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
      if (id != null) 'id': id,
      'name': name,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'] ?? '',
      photoPath: map['photo_path'],
      isTrained: map['is_trained'] == true || map['is_trained'] == 1,
      assignedMedicineId: map['assigned_medicine_id'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
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
