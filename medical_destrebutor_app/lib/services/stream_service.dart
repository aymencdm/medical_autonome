import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Available streaming modes
enum StreamMode {
  normal,       // Pure video streaming, no servos
  manual,       // Manual control with keyboard
  recognition   // Face detection active, servos OFF
}

/// Extension to convert enum to/from string
extension StreamModeExtension on StreamMode {
  String get value {
    switch (this) {
      case StreamMode.manual:
        return 'manual';
      case StreamMode.recognition:
        return 'recognition';
      case StreamMode.normal:
        return 'normal';
    }
  }
  
  static StreamMode fromString(String value) {
    switch (value) {
      case 'manual':
        return StreamMode.manual;
      case 'recognition':
        return StreamMode.recognition;
      case 'normal':
      default:
        return StreamMode.normal;
    }
  }
}

/// Service for managing video stream connection and control.
/// 
/// Handles:
/// - Socket.IO connection to Raspberry Pi
/// - Video frame reception
/// - Stream mode switching
/// - Servo control commands
class StreamService extends ChangeNotifier {
  // Connection state
  String _serverIp = '';
  int _serverPort = 8080;
  bool _isConnected = false;
  bool _isStreaming = false;
  String? _errorMessage;
  Uint8List? _currentFrame;
  io.Socket? _socket;
  
  // Stream mode
  StreamMode _currentMode = StreamMode.normal;
  
  // Servo State
  double _pan = 90.0;
  double _tilt = 110.0;
  bool _servosActive = false;
  DateTime _lastLocalMoveTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Getters
  String get serverIp => _serverIp;
  int get serverPort => _serverPort;
  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  String? get errorMessage => _errorMessage;
  Uint8List? get currentFrame => _currentFrame;
  StreamMode get currentMode => _currentMode;
  
  double get pan => _pan;
  double get tilt => _tilt;
  bool get servosActive => _servosActive;
  
  // Face Rec
  List<String> _persons = [];
  List<String> get persons => _persons;

  /// Set server connection details
  void setServer(String ip, {int port = 8080}) {
    _serverIp = ip;
    _serverPort = port;
    _errorMessage = null;
    notifyListeners();
  }

  /// Legacy method for compatibility
  void setServerIp(String ip) => setServer(ip);

  /// Connect to the Raspberry Pi server
  void connect() {
    if (_serverIp.isEmpty) {
      _errorMessage = 'Please enter server IP address';
      notifyListeners();
      return;
    }

    // Close existing connection
    _socket?.dispose();

    try {
      final url = 'http://$_serverIp:$_serverPort/stream';
      _log('Connecting to: $url');
      
      _socket = io.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Connection events
      _socket!.onConnect((_) {
        _isConnected = true;
        _errorMessage = null;
        _log('Connected successfully');
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _isStreaming = false;
        _log('Disconnected from server');
        notifyListeners();
      });

      _socket!.onConnectError((data) {
        _errorMessage = 'Connection Error: $data';
        _isConnected = false;
        _log('Connect Error: $data');
        notifyListeners();
      });

      // Video frame handler
      _socket!.on('video_frame', (data) {
        try {
          if (data != null) {
            final dynamic rawData = data is Map ? data['data'] : data;
            
            if (rawData is Uint8List) {
              _currentFrame = rawData;
            } else if (rawData is List<int>) {
              _currentFrame = Uint8List.fromList(rawData);
            }

            _isStreaming = true;
            notifyListeners();
          }
        } catch (e) {
          _log('Error processing frame: $e');
        }
      });

      // Status handler
      _socket!.on('status', (data) {
        if (data != null) {
          // CRITICAL FIX: In Manual Mode, the Client is the source of truth.
          // Ignore server position echoes to prevent shaking/jitter.
          // Only sync with server if we are NOT in manual mode.
          if (_currentMode != StreamMode.manual) {
             if (data.containsKey('pan')) _pan = (data['pan'] as num).toDouble();
             if (data.containsKey('tilt')) _tilt = (data['tilt'] as num).toDouble();
          }
          
          if (data.containsKey('servos_active')) _servosActive = data['servos_active'];
          if (data.containsKey('streaming')) _isStreaming = data['streaming'];
          if (data.containsKey('mode')) {
            _currentMode = StreamModeExtension.fromString(data['mode']);
          }
          notifyListeners();
        }
      });

      // Mode change handler
      _socket!.on('mode_changed', (data) {
        if (data != null && data.containsKey('mode')) {
          _currentMode = StreamModeExtension.fromString(data['mode']);
          if (data.containsKey('servos_active')) _servosActive = data['servos_active'];
          _log('Mode changed to: ${_currentMode.value}');
          notifyListeners();
        }
      });

      // Face Recognition Events
      _socket!.on('persons_list', (data) {
         if (data != null && data['persons'] != null) {
           _persons = List<String>.from(data['persons']);
           notifyListeners();
         }
      });

      _socket!.connect();
    } catch (e) {
      _errorMessage = 'Failed to initialize socket: $e';
      notifyListeners();
    }
  }

  /// Disconnect from server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isStreaming = false;
    _currentFrame = null;
    notifyListeners();
  }

  /// Set the stream mode
  void setStreamMode(StreamMode mode) {
    _socket?.emit('set_mode', {'mode': mode.value});
    _currentMode = mode;
    notifyListeners();
    _log('Requesting mode: ${mode.value}');
  }

  /// Adjust Servos relatively (for keyboard control)
  void adjustPan(double delta) {
    double newPan = (_pan + delta).clamp(0.0, 180.0);
    // Optimistic update
    if ((newPan - _pan).abs() > 0.05) {
      _pan = newPan; 
      _lastLocalMoveTime = DateTime.now();
      moveServo(_pan, _tilt);
    }
  }

  void adjustTilt(double delta) {
    double newTilt = (_tilt + delta).clamp(90.0, 180.0); // Limit 90-180
    // Optimistic update
    if ((newTilt - _tilt).abs() > 0.05) {
      _tilt = newTilt; 
      _lastLocalMoveTime = DateTime.now();
      moveServo(_pan, _tilt);
    }
  }

  /// Move servos manually (manual mode only)
  void moveServo(double pan, double tilt) {
    if (_currentMode == StreamMode.manual) {
      _socket?.emit('manual_move', {'pan': pan, 'tilt': tilt});
      notifyListeners();
    }
  }

  /// Request current status from server
  void requestStatus() {
    _socket?.emit('get_status');
  }

  // --- Face Recognition API ---

  void getPersons() {
    _socket?.emit('get_persons');
  }

  void createPerson(String name) {
    _socket?.emit('create_person', {'name': name});
  }

  void captureImage(String name, Uint8List imageBytes) {
    // Send image data to server
    // Note: SocketIO handles basic type serialization, but lists often safer
    _socket?.emit('capture_image', {
      'name': name,
      'image': imageBytes
    });
  }

  void trainModel() {
    _socket?.emit('train_model');
  }

  void _log(String msg) {
    if (kDebugMode) {
      print('[StreamService] $msg');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
