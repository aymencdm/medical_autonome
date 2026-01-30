class Medicine {
  final int? id;
  final String name;
  final double angle; // Fixed servo angle (0-360°)
  final int slotIndex; // Logical slot position
  final String? description;
  final DateTime createdAt;

  Medicine({
    this.id,
    required this.name,
    required this.angle,
    required this.slotIndex,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'angle': angle,
      'slotIndex': slotIndex,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      angle: map['angle'],
      slotIndex: map['slotIndex'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    double? angle,
    int? slotIndex,
    String? description,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      angle: angle ?? this.angle,
      slotIndex: slotIndex ?? this.slotIndex,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
