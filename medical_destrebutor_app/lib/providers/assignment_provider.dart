import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/raspberry_pi_service.dart';

class AssignmentProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final RaspberryPiService _rpiService;
  
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = false;
  String? _error;

  AssignmentProvider(this._rpiService);

  List<Map<String, dynamic>> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignments = await _db.getAllAssignments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignMedicine(int patientId, int medicineId) async {
    try {
      await _db.assignMedicineToPatient(patientId, medicineId);
      await _rpiService.assignMedicine(patientId, medicineId);
      await loadAssignments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic>? getAssignmentForPatient(int patientId) {
    try {
      return _assignments.firstWhere((a) => a['patientId'] == patientId);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getUnassignedPatients() {
    return _assignments.where((a) => a['medicineId'] == null).toList();
  }

  List<Map<String, dynamic>> getAssignedPatients() {
    return _assignments.where((a) => a['medicineId'] != null).toList();
  }
}
