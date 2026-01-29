import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class StreamService extends ChangeNotifier {
  String _serverIp = '';
  bool _isConnected = false;
  bool _isStreaming = false;
  bool _isTracking = true;
  String? _errorMessage;
  Uint8List? _currentFrame;
  io.Socket? _socket;

  String get serverIp => _serverIp;
  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  Uint8List? get currentFrame => _currentFrame;

  void setServerIp(String ip) {
    _serverIp = ip;
    _errorMessage = null;
    notifyListeners();
  }

  void connect() {
    if (_serverIp.isEmpty) {
      _errorMessage = 'Please enter server IP address';
      notifyListeners();
      return;
    }

    // Close existing connection if any
    _socket?.dispose();

    try {
      _socket = io.io('http://$_serverIp:8080/stream', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        _errorMessage = null;
        logger('Connected to server');
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _isStreaming = false;
        logger('Disconnected from server');
        notifyListeners();
      });

      _socket!.onConnectError((data) {
        _errorMessage = 'Connection Error: $data';
        _isConnected = false;
        logger('Connect Error: $data');
        notifyListeners();
      });

      // Handle video frames
      int frameCount = 0;
      DateTime lastLog = DateTime.now();

      _socket!.on('video_frame', (data) {
        try {
          if (data != null) {
            // Socket.IO for Flutter usually returns Uint8List directly for binary events
            // or maps containing Uint8List
            final dynamic rawData = data is Map ? data['data'] : data;
            
            if (rawData is Uint8List) {
              _currentFrame = rawData;
            } else if (rawData is List<int>) {
              _currentFrame = Uint8List.fromList(rawData);
            }

            _isStreaming = true;
            
            // Only notify if we haven't updated in ~30ms to prevent UI saturation
            // This ensures smooth playback without freezing the UI thread
            notifyListeners();
            
            frameCount++;
            if (DateTime.now().difference(lastLog).inSeconds >= 5) {
              logger('Received $frameCount frames in 5s');
              frameCount = 0;
              lastLog = DateTime.now();
            }
          }
        } catch (e) {
          logger('Error processing frame: $e');
        }
      });

      // Handle status updates
      _socket!.on('status', (data) {
        if (data != null) {
          if (data.containsKey('tracking')) _isTracking = data['tracking'];
          if (data.containsKey('streaming')) _isStreaming = data['streaming'];
          notifyListeners();
        }
      });

      _socket!.connect();
    } catch (e) {
      _errorMessage = 'Failed to initialize socket: $e';
      notifyListeners();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isStreaming = false;
    _currentFrame = null;
    notifyListeners();
  }

  void startStreaming() {
    _socket?.emit('start_streaming');
  }

  void stopStreaming() {
    _socket?.emit('stop_streaming');
    _isStreaming = false;
    _currentFrame = null;
    notifyListeners();
  }

  void toggleTracking(bool enabled) {
    _socket?.emit('toggle_tracking', {'enabled': enabled});
  }

  void centerServo() {
    _socket?.emit('center_servo');
  }

  void moveServo(double pan, double tilt) {
    _socket?.emit('move_servo', {'pan': pan, 'tilt': tilt});
  }

  void logger(String msg) {
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
