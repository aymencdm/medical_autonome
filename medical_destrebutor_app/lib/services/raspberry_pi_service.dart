import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import '../models/system_state.dart';
import '../models/patient.dart';
import '../models/medicine.dart';

class RaspberryPiService {
  final String baseUrl;
  final String socketNamespace;
  IO.Socket? _socket;
  
  // Callbacks
  Function(Uint8List)? onVideoFrame;
  Function(SystemState)? onSystemStateUpdate;
  Function(double)? onWheelAngleUpdate;
  Function(bool)? onDoorStateUpdate;
  Function(String)? onPatientRecognized;

  RaspberryPiService({
    required this.baseUrl,
    this.socketNamespace = '/stream',
  });

  // ==================== HTTP API METHODS ====================

  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/system/status')).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Patient Management
  Future<void> addPatient(Patient patient) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient.toMap()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add patient: ${response.body}');
    }
  }

  Future<void> deletePatient(int patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/patients/$patientId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete patient');
    }
  }

  Future<void> uploadFaceImages(int patientId, List<String> imagePaths) async {
    final uri = Uri.parse('$baseUrl/api/patients/$patientId/faces');
    var request = http.MultipartRequest('POST', uri);
    
    for (var path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', path));
    }
    
    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload face images');
    }
  }

  Future<void> trainFaceRecognition() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/train'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Face training failed: ${response.body}');
    }
  }

  // Medicine Management
  Future<void> addMedicine(Medicine medicine) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/medicines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(medicine.toMap()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add medicine: ${response.body}');
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/medicines/${medicine.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(medicine.toMap()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update medicine');
    }
  }

  Future<void> deleteMedicine(int medicineId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/medicines/$medicineId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete medicine');
    }
  }

  // Assignment Management
  Future<void> assignMedicine(int patientId, int medicineId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assignments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': patientId,
        'medicineId': medicineId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to assign medicine');
    }
  }

  // System Control
  Future<SystemState> getSystemStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/system/status'),
    );
    if (response.statusCode == 200) {
      return SystemState.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get system status');
    }
  }

  Future<void> emergencyStop() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/system/emergency_stop'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Emergency stop failed');
    }
  }

  Future<void> rotateWheelToAngle(double angle) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/wheel/rotate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'angle': angle}),
    );
    if (response.statusCode != 200) {
      throw Exception('Wheel rotation failed');
    }
  }

  Future<void> testDoor(bool open) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/wheel/door'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'open': open}),
    );
    if (response.statusCode != 200) {
      throw Exception('Door control failed');
    }
  }

  // ==================== WEBSOCKET METHODS ====================

  void connectWebSocket() {
    _socket = IO.io(
      '$baseUrl$socketNamespace',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('✅ Connected to Raspberry Pi WebSocket');
    });

    _socket!.on('disconnect', (_) {
      print('⚠️ Disconnected from Raspberry Pi WebSocket');
    });

    _socket!.on('video_frame', (data) {
      if (onVideoFrame != null && data is List<int>) {
        onVideoFrame!(Uint8List.fromList(data));
      }
    });

    _socket!.on('system_state_update', (data) {
      if (onSystemStateUpdate != null) {
        onSystemStateUpdate!(SystemState.fromMap(data));
      }
    });

    _socket!.on('wheel_angle_update', (data) {
      if (onWheelAngleUpdate != null) {
        onWheelAngleUpdate!(data['angle'] as double);
      }
    });

    _socket!.on('door_state_update', (data) {
      if (onDoorStateUpdate != null) {
        onDoorStateUpdate!(data['open'] as bool);
      }
    });

    _socket!.on('patient_recognized', (data) {
      if (onPatientRecognized != null) {
        onPatientRecognized!(data['name'] as String);
      }
    });
  }

  void disconnectWebSocket() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  void toggleTracking(bool enabled) {
    _socket?.emit('toggle_tracking', {'enabled': enabled});
  }

  void manualMove(double? pan, double? tilt) {
    _socket?.emit('manual_move', {'pan': pan, 'tilt': tilt});
  }

  void center() {
    _socket?.emit('center');
  }

  void dispose() {
    disconnectWebSocket();
  }
}
