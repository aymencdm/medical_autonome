import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/raspberry_pi_service.dart';

class MedicineProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final RaspberryPiService _rpiService;
  
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;
  
  double _currentWheelAngle = 0.0;
  double? _targetWheelAngle;
  bool _isRotating = false;

  MedicineProvider(this._rpiService);

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentWheelAngle => _currentWheelAngle;
  double? get targetWheelAngle => _targetWheelAngle;
  bool get isRotating => _isRotating;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicines = await _db.getAllMedicines();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedicine(Medicine medicine) async {
    try {
      final id = await _db.insertMedicine(medicine);
      await _rpiService.addMedicine(medicine.copyWith(id: id));
      await loadMedicines();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await _db.updateMedicine(medicine);
      await _rpiService.updateMedicine(medicine);
      await loadMedicines();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMedicine(int id) async {
    try {
      await _db.deleteMedicine(id);
      await _rpiService.deleteMedicine(id);
      await loadMedicines();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Rotate wheel with 180° backward rotation, then to target angle
  Future<void> rotateToMedicine(Medicine medicine) async {
    _isRotating = true;
    _targetWheelAngle = medicine.angle;
    notifyListeners();

    try {
      // Step 1: Rotate 180° backward
      double backwardAngle = (_currentWheelAngle + 180) % 360;
      await _rpiService.rotateWheelToAngle(backwardAngle);
      _currentWheelAngle = backwardAngle;
      notifyListeners();
      
      // Small delay for visualization
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 2: Rotate to medicine's angle
      await _rpiService.rotateWheelToAngle(medicine.angle);
      _currentWheelAngle = medicine.angle;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRotating = false;
      _targetWheelAngle = null;
      notifyListeners();
    }
  }

  void updateWheelAngle(double angle) {
    _currentWheelAngle = angle;
    notifyListeners();
  }

  Medicine? getMedicineById(int id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Medicine? getMedicineBySlot(int slot) {
    try {
      return _medicines.firstWhere((m) => m.slotIndex == slot);
    } catch (e) {
      return null;
    }
  }
}
