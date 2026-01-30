enum RobotMode {
  lineFollowing,
  stoppedWaiting,
  faceTracking,
  faceRecognition,
  medicineDispensing,
  waitingForPickup,
  resuming,
  error,
  idle,
}

extension RobotModeExtension on RobotMode {
  String get displayName {
    switch (this) {
      case RobotMode.lineFollowing:
        return 'Line Following';
      case RobotMode.stoppedWaiting:
        return 'Stopped - Waiting';
      case RobotMode.faceTracking:
        return 'Face Tracking';
      case RobotMode.faceRecognition:
        return 'Face Recognition';
      case RobotMode.medicineDispensing:
        return 'Dispensing Medicine';
      case RobotMode.waitingForPickup:
        return 'Waiting for Pickup';
      case RobotMode.resuming:
        return 'Resuming';
      case RobotMode.error:
        return 'Error';
      case RobotMode.idle:
        return 'Idle';
    }
  }

  String get icon {
    switch (this) {
      case RobotMode.lineFollowing:
        return '🚗';
      case RobotMode.stoppedWaiting:
        return '⏸️';
      case RobotMode.faceTracking:
        return '👁️';
      case RobotMode.faceRecognition:
        return '🔍';
      case RobotMode.medicineDispensing:
        return '💊';
      case RobotMode.waitingForPickup:
        return '⏳';
      case RobotMode.resuming:
        return '▶️';
      case RobotMode.error:
        return '❌';
      case RobotMode.idle:
        return '⭕';
    }
  }
}
