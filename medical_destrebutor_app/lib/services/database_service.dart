import '../models/patient.dart';
import '../models/medicine.dart';

/// Simplified database service using in-memory storage
/// For production, this will be replaced with sqflite_common_ffi
class DatabaseService {
  static DatabaseService? _instance;
  
  // In-memory storage
  final Map<int, Patient> _patients = {};
  final Map<int, Medicine> _medicines = {};
  final Map<int, List<String>> _faceImages = {};
  int _patientIdCounter = 1;
  int _medicineIdCounter = 1;

  DatabaseService._();

  factory DatabaseService() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<dynamic> get database async => this;

  // ==================== PATIENT OPERATIONS ====================

  Future<int> insertPatient(Patient patient) async {
    final id = _patientIdCounter++;
    _patients[id] = patient.copyWith(id: id);
    return id;
  }

  Future<List<Patient>> getAllPatients() async {
    return _patients.values.toList();
  }

  Future<Patient?> getPatient(int id) async {
    return _patients[id];
  }

  Future<int> updatePatient(Patient patient) async {
    if (patient.id != null && _patients.containsKey(patient.id)) {
      _patients[patient.id!] = patient;
      return 1;
    }
    return 0;
  }

  Future<int> deletePatient(int id) async {
    if (_patients.containsKey(id)) {
      _patients.remove(id);
      _faceImages.remove(id);
      return 1;
    }
    return 0;
  }

  // ==================== MEDICINE OPERATIONS ====================

  Future<int> insertMedicine(Medicine medicine) async {
    final id = _medicineIdCounter++;
    _medicines[id] = medicine.copyWith(id: id);
    return id;
  }

  Future<List<Medicine>> getAllMedicines() async {
    return _medicines.values.toList()..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  }

  Future<Medicine?> getMedicine(int id) async {
    return _medicines[id];
  }

  Future<int> updateMedicine(Medicine medicine) async {
    if (medicine.id != null && _medicines.containsKey(medicine.id)) {
      _medicines[medicine.id!] = medicine;
      return 1;
    }
    return 0;
  }

  Future<int> deleteMedicine(int id) async {
    if (_medicines.containsKey(id)) {
      _medicines.remove(id);
      return 1;
    }
    return 0;
  }

  // ==================== FACE IMAGE OPERATIONS ====================

  Future<int> insertFaceImage(int patientId, String imagePath) async {
    if (!_faceImages.containsKey(patientId)) {
      _faceImages[patientId] = [];
    }
    _faceImages[patientId]!.add(imagePath);
    return _faceImages[patientId]!.length;
  }

  Future<List<String>> getFaceImages(int patientId) async {
    return _faceImages[patientId] ?? [];
  }

  Future<int> deleteFaceImage(int id) async {
    // Simplified: not implemented for in-memory version
    return 0;
  }

  // ==================== ASSIGNMENT OPERATIONS ====================

  Future<int> assignMedicineToPatient(int patientId, int medicineId) async {
    final patient = _patients[patientId];
    if (patient != null) {
      _patients[patientId] = patient.copyWith(assignedMedicineId: medicineId);
      return 1;
    }
    return 0;
  }

  Future<Map<String, dynamic>?> getAssignment(int patientId) async {
    final patient = _patients[patientId];
    if (patient == null) return null;
    
    final medicine = patient.assignedMedicineId != null 
        ? _medicines[patient.assignedMedicineId]
        : null;
    
    return {
      'patientId': patient.id,
      'patientName': patient.name,
      'medicineId': medicine?.id,
      'medicineName': medicine?.name,
      'medicineAngle': medicine?.angle,
    };
  }

  Future<List<Map<String, dynamic>>> getAllAssignments() async {
    final List<Map<String, dynamic>> assignments = [];
    
    for (var patient in _patients.values) {
      final medicine = patient.assignedMedicineId != null 
          ? _medicines[patient.assignedMedicineId]
          : null;
      
      assignments.add({
        'patientId': patient.id,
        'patientName': patient.name,
        'isTrained': patient.isTrained,
        'medicineId': medicine?.id,
        'medicineName': medicine?.name,
        'medicineAngle': medicine?.angle,
      });
    }
    
    return assignments;
  }

  // ==================== UTILITY ====================

  Future<void> close() async {
    // No-op for in-memory storage
  }
}
