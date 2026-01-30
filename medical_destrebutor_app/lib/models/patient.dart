class Patient {
  final int? id;
  final String name;
  final String? photoPath;
  final bool isTrained;
  final int? assignedMedicineId;
  final DateTime createdAt;

  Patient({
    this.id,
    required this.name,
    this.photoPath,
    this.isTrained = false,
    this.assignedMedicineId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'isTrained': isTrained ? 1 : 0,
      'assignedMedicineId': assignedMedicineId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      photoPath: map['photoPath'],
      isTrained: map['isTrained'] == 1,
      assignedMedicineId: map['assignedMedicineId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Patient copyWith({
    int? id,
    String? name,
    String? photoPath,
    bool? isTrained,
    int? assignedMedicineId,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      isTrained: isTrained ?? this.isTrained,
      assignedMedicineId: assignedMedicineId ?? this.assignedMedicineId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
