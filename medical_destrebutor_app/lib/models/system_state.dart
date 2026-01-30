import 'robot_mode.dart';

class SystemState {
  final RobotMode mode;
  final double wheelAngle; // Current wheel position (0-360°)
  final bool isDoorOpen;
  final String? recognizedPatientName;
  final String? selectedMedicine;
  final double? targetWheelAngle;
  final bool isWheelRotating;
  final String? errorMessage;
  final DateTime timestamp;

  SystemState({
    this.mode = RobotMode.idle,
    this.wheelAngle = 0.0,
    this.isDoorOpen = false,
    this.recognizedPatientName,
    this.selectedMedicine,
    this.targetWheelAngle,
    this.isWheelRotating = false,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.toString(),
      'wheelAngle': wheelAngle,
      'isDoorOpen': isDoorOpen,
      'recognizedPatientName': recognizedPatientName,
      'selectedMedicine': selectedMedicine,
      'targetWheelAngle': targetWheelAngle,
      'isWheelRotating': isWheelRotating,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SystemState.fromMap(Map<String, dynamic> map) {
    return SystemState(
      mode: RobotMode.values.firstWhere(
        (e) => e.toString() == map['mode'],
        orElse: () => RobotMode.idle,
      ),
      wheelAngle: map['wheelAngle'] ?? 0.0,
      isDoorOpen: map['isDoorOpen'] ?? false,
      recognizedPatientName: map['recognizedPatientName'],
      selectedMedicine: map['selectedMedicine'],
      targetWheelAngle: map['targetWheelAngle'],
      isWheelRotating: map['isWheelRotating'] ?? false,
      errorMessage: map['errorMessage'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  SystemState copyWith({
    RobotMode? mode,
    double? wheelAngle,
    bool? isDoorOpen,
    String? recognizedPatientName,
    String? selectedMedicine,
    double? targetWheelAngle,
    bool? isWheelRotating,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return SystemState(
      mode: mode ?? this.mode,
      wheelAngle: wheelAngle ?? this.wheelAngle,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      recognizedPatientName: recognizedPatientName ?? this.recognizedPatientName,
      selectedMedicine: selectedMedicine ?? this.selectedMedicine,
      targetWheelAngle: targetWheelAngle ?? this.targetWheelAngle,
      isWheelRotating: isWheelRotating ?? this.isWheelRotating,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
