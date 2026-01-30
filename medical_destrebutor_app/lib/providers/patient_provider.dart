import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../services/raspberry_pi_service.dart';

class PatientProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final RaspberryPiService _rpiService;
  
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;
  bool _isTraining = false;

  PatientProvider(this._rpiService);

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTraining => _isTraining;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _db.getAllPatients();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPatient(Patient patient, {List<String>? imagePaths}) async {
    try {
      final id = await _db.insertPatient(patient);
      
      if (imagePaths != null && imagePaths.isNotEmpty) {
        // Upload face images
        for (var path in imagePaths) {
          await _db.insertFaceImage(id, path);
        }
        
        // Send to RPi
        await _rpiService.addPatient(patient.copyWith(id: id));
        await _rpiService.uploadFaceImages(id, imagePaths);
      }
      
      await loadPatients();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      await _db.deletePatient(id);
      await _rpiService.deletePatient(id);
      await loadPatients();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> trainFaceRecognition() async {
    _isTraining = true;
    notifyListeners();

    try {
      await _rpiService.trainFaceRecognition();
      
      // Mark all patients as trained
      for (var patient in _patients) {
        if (patient.id != null) {
          await _db.updatePatient(patient.copyWith(isTrained: true));
        }
      }
      
      await loadPatients();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isTraining = false;
      notifyListeners();
    }
  }

  Patient? getPatientById(int id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
