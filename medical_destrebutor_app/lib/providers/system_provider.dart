import 'package:flutter/material.dart';
import '../models/system_state.dart';
import '../models/robot_mode.dart';
import '../services/raspberry_pi_service.dart';

class SystemProvider with ChangeNotifier {
  final RaspberryPiService _rpiService;
  
  SystemState _systemState = SystemState();
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  SystemProvider(this._rpiService) {
    _setupWebSocketListeners();
  }

  SystemState get systemState => _systemState;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setupWebSocketListeners() {
    _rpiService.onSystemStateUpdate = (state) {
      _systemState = state;
      notifyListeners();
    };

    _rpiService.onWheelAngleUpdate = (angle) {
      _systemState = _systemState.copyWith(wheelAngle: angle);
      notifyListeners();
    };

    _rpiService.onDoorStateUpdate = (isOpen) {
      _systemState = _systemState.copyWith(isDoorOpen: isOpen);
      notifyListeners();
    };

    _rpiService.onPatientRecognized = (patientName) {
      _systemState = _systemState.copyWith(recognizedPatientName: patientName);
      notifyListeners();
    };
  }

  Future<void> connect() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isConnected = await _rpiService.testConnection();
      if (_isConnected) {
        _rpiService.connectWebSocket();
        await refreshStatus();
      }
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _rpiService.disconnectWebSocket();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    try {
      _systemState = await _rpiService.getSystemStatus();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> emergencyStop() async {
    try {
      await _rpiService.emergencyStop();
      _systemState = _systemState.copyWith(mode: RobotMode.error);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> testDoor(bool open) async {
    try {
      await _rpiService.testDoor(open);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rpiService.dispose();
    super.dispose();
  }
}
