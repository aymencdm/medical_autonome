---
description: Autonomous Medical Delivery Robot - Complete Implementation Plan
---

# 🤖 Autonomous Medical Delivery Robot - Implementation Plan

## 📋 Project Overview

**System Components:**
- Arduino (line following with 5 IR sensors)
- Raspberry Pi 4 (vision, logic, communication)
- Face tracking (existing, working)
- Face recognition (to be implemented)
- Medicine wheel carousel (rotation servo + door servo)
- Flutter desktop application (complete redesign)

**Core Logic Rules:**
- ✅ Angles belong to MEDICINES, not patients
- ✅ Mapping: Patient → Medicine → Angle
- ✅ 180° backward rotation for loading/alignment

---

## 🎯 Phase 1: Flutter Desktop App Redesign

### Architecture
```
lib/
├── main.dart
├── models/
│   ├── patient.dart
│   ├── medicine.dart
│   ├── system_state.dart
│   └── robot_mode.dart
├── services/
│   ├── database_service.dart (SQLite)
│   ├── face_recognition_service.dart
│   ├── raspberry_pi_service.dart (WebSocket/HTTP)
│   └── stream_service.dart (existing)
├── providers/
│   ├── patient_provider.dart
│   ├── medicine_provider.dart
│   ├── assignment_provider.dart
│   └── system_provider.dart
├── screens/
│   ├── home_screen.dart (4-section dashboard)
│   ├── patient_management_screen.dart
│   ├── medicine_wheel_screen.dart
│   ├── assignment_screen.dart
│   └── live_camera_screen.dart
└── widgets/
    ├── medicine_wheel_visualizer.dart
    ├── patient_card.dart
    ├── face_capture_dialog.dart
    ├── system_status_panel.dart
    └── camera_feed.dart
```

### Screen 1: Patient Management & Face Training
**Features:**
- Patient list (add/edit/delete)
- Face capture dialog (multiple images per patient)
- Train/update face recognition dataset
- Show assigned medicine per patient
- Status: trained/not trained

**UI Components:**
- Patient cards with avatar
- "Add Patient" FAB
- Face capture modal (webcam + capture button)
- Training progress indicator

### Screen 2: Medicine Wheel Management
**Features:**
- Circular wheel visualization (360° carousel)
- Compartment/slot management
- Each medicine has:
  - Name
  - Fixed servo angle (0-360°)
  - Slot index
- Visual indicators:
  - Current wheel position
  - Target angle
  - 180° backward rotation arrow
- Manual wheel control for testing

**UI Components:**
- `CustomPaint` circular wheel
- Medicine slot cards
- Angle input fields
- "Add Medicine" button
- "Rotate to Position" button (with 180° backward animation)

**Logic:**
```dart
void rotateToMedicine(Medicine medicine) async {
  // Step 1: Rotate 180° backward
  double currentAngle = wheelState.currentAngle;
  double backwardAngle = (currentAngle + 180) % 360;
  await rotateWheel(backwardAngle);
  
  // Step 2: Rotate to medicine's target angle
  await rotateWheel(medicine.angle);
}
```

### Screen 3: Patient → Medicine Assignment
**Features:**
- Patient list
- Medicine dropdown per patient
- Assignment mapping table:
  - Patient | Medicine | Medicine Angle
- Save/update assignments

**UI Components:**
- Assignment cards
- Dropdown selectors
- Save button
- Validation (one medicine per patient)

### Screen 4: Live Camera & System Status
**Features:**
- Live camera feed (from existing code)
- System mode indicator (FSM state):
  - LINE_FOLLOWING
  - FACE_TRACKING
  - FACE_RECOGNITION
  - WHEEL_ROTATION
  - DOOR_OPEN
  - WAITING
- Real-time status display:
  - Current patient (if recognized)
  - Selected medicine
  - Wheel angle
  - Door servo state (open/closed)
- Emergency stop button

**UI Components:**
- Video stream widget
- Status panel with animated indicators
- Mode badge
- Stop/resume controls

---

## 🤖 Phase 2: Raspberry Pi Control System

### Extended Architecture
```
rpi/
├── main.py (Extended Flask-SocketIO server)
├── config.py (Extended config)
├── servos.py (Extended for wheel + door servos)
├── tracker.py (Existing face tracking)
├── face_recognizer.py (NEW: Face recognition)
├── state_machine.py (NEW: Robot FSM)
├── serial_comm.py (NEW: Arduino communication)
├── medicine_controller.py (NEW: Wheel + door logic)
└── datasets/
    └── faces/ (Training images per patient)
```

### New Modules

#### `face_recognizer.py`
```python
# Face recognition using OpenCV LBPH/DeepFace
# - Train from dataset
# - Recognize patient from frame
# - Return patient ID + confidence
```

#### `state_machine.py`
```python
# Finite State Machine
States:
- LINE_FOLLOWING
- STOPPED_WAITING
- FACE_TRACKING
- FACE_RECOGNITION
- MEDICINE_DISPENSING
- WAITING_FOR_PICKUP
- RESUMING

Transitions:
- Arduino STOP → STOPPED_WAITING → FACE_TRACKING
- Face detected 3s → FACE_RECOGNITION
- Patient recognized → MEDICINE_DISPENSING
- Pickup complete → RESUMING → LINE_FOLLOWING
```

#### `serial_comm.py`
```python
# Serial communication with Arduino
# Commands:
# - Receive: "STOP" (all sensors black)
# - Send: "RESUME" (continue line following)
```

#### `medicine_controller.py`
```python
# Medicine wheel + door servo control
# - rotate_backward_180()
# - rotate_to_angle(angle)
# - open_door()
# - close_door()
# - dispense_medicine(medicine_angle)
```

### Servo Configuration (Extended)
```python
CONFIG["SERVOS"] = {
    # Existing pan/tilt for face tracking
    "PAN_PIN": 17,
    "TILT_PIN": 27,
    
    # NEW: Medicine wheel + door
    "WHEEL_PIN": 22,
    "DOOR_PIN": 23,
    
    "WHEEL_ANGLE_RANGE": (0, 360),
    "DOOR_OPEN_ANGLE": 90,
    "DOOR_CLOSED_ANGLE": 0,
    
    "ROTATION_SPEED": 1.0,  # degrees per step
    "PICKUP_WAIT_TIME": 10  # seconds
}
```

---

## 📡 Phase 3: Arduino Line Following

### Arduino Code (`line_follower.ino`)
```cpp
// 5 IR sensors (L2, L1, C, R1, R2)
// PID line following
// Serial communication with RPi

void loop() {
  readSensors();
  
  if (allSensorsBlack()) {
    stopMotors();
    Serial.println("STOP");
    waitForResumeSignal();
  } else {
    followLine();
  }
}

void waitForResumeSignal() {
  while (true) {
    if (Serial.available()) {
      String cmd = Serial.readStringUntil('\n');
      if (cmd == "RESUME") {
        break;
      }
    }
  }
}
```

---

## 🔄 Phase 4: Complete Control Flow

### Finite State Machine

```
[LINE_FOLLOWING] 
    ↓ (all sensors black)
[STOPPED_WAITING]
    ↓ (Arduino sends "STOP")
[FACE_TRACKING]
    ↓ (face detected for 3s)
[FACE_RECOGNITION]
    ↓ (patient recognized)
[MEDICINE_DISPENSING]
    ├→ rotate_backward_180()
    ├→ rotate_to_medicine_angle()
    ├→ open_door()
    ├→ wait_10s()
    └→ close_door()
    ↓
[WAITING_FOR_PICKUP]
    ↓ (timer complete)
[RESUMING]
    ↓ (send "RESUME" to Arduino)
[LINE_FOLLOWING]
```

### Detailed Dispensing Sequence
```python
async def dispense_medicine(patient_id):
    # 1. Get assignment
    medicine = get_assigned_medicine(patient_id)
    if not medicine:
        raise NoMedicineAssignedError()
    
    # 2. Rotate backward 180°
    current_angle = wheel_controller.get_current_angle()
    backward_angle = (current_angle + 180) % 360
    await wheel_controller.rotate_to(backward_angle)
    
    # 3. Rotate to medicine angle
    await wheel_controller.rotate_to(medicine.angle)
    
    # 4. Open door
    await door_controller.open()
    
    # 5. Wait for pickup
    await asyncio.sleep(10)
    
    # 6. Close door
    await door_controller.close()
    
    # 7. Send resume signal
    serial_comm.send("RESUME")
```

---

## 🛠️ Phase 5: Communication Protocol

### HTTP REST API (Flutter ← → RPi)
```
POST   /api/patients              # Add patient
GET    /api/patients              # List patients
DELETE /api/patients/{id}         # Delete patient

POST   /api/patients/{id}/faces   # Upload face images
POST   /api/train                 # Train face recognition

POST   /api/medicines             # Add medicine
GET    /api/medicines             # List medicines
PUT    /api/medicines/{id}        # Update medicine

POST   /api/assignments           # Assign patient → medicine
GET    /api/assignments           # List assignments

GET    /api/system/status         # System state
POST   /api/system/emergency_stop # Emergency stop
```

### WebSocket Events (Real-time)
```
← video_frame          # Camera feed
← system_state_update  # FSM state changes
← wheel_angle_update   # Wheel position
← door_state_update    # Door open/closed
← patient_recognized   # Recognition result
```

### Serial Protocol (Arduino ↔ RPi)
```
Arduino → RPi:
- "STOP\n"

RPi → Arduino:
- "RESUME\n"
```

---

## ⚠️ Phase 6: Error Handling

### Error Cases

1. **Unknown Face**
   - Show on screen: "Unknown patient"
   - Do not dispense medicine
   - Return to FACE_TRACKING after timeout
   - Log event

2. **Medicine Not Assigned**
   - Show on screen: "Patient has no assigned medicine"
   - Do not dispense
   - Send alert to Flutter app
   - Return to LINE_FOLLOWING

3. **Servo Failure**
   - Detect: servo not reaching target angle
   - Emergency stop
   - Alert Flutter app
   - Require manual reset

4. **Communication Timeout**
   - Arduino not responding → emergency stop
   - RPi not responding → show offline status in Flutter

5. **Door Jam**
   - Detect: door servo current spike
   - Retry 3 times
   - If failed → emergency stop

---

## ✅ Phase 7: Testing & Validation

### Unit Tests
- [ ] Medicine wheel 180° rotation
- [ ] Angle calculation accuracy
- [ ] Patient → Medicine → Angle mapping
- [ ] Face recognition accuracy
- [ ] Serial communication reliability

### Integration Tests
- [ ] Full dispensing sequence
- [ ] State machine transitions
- [ ] Emergency stop from any state
- [ ] Multiple patients in sequence

### UI/UX Tests
- [ ] Wheel visualization accuracy
- [ ] Real-time status updates
- [ ] Camera feed latency
- [ ] Assignment validation

---

## 📦 Dependencies

### Flutter (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  socket_io_client: ^2.0.2
  http: ^1.1.0
  provider: ^6.1.1
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  camera: ^0.10.5
  fl_chart: ^0.64.0  # For wheel visualization
  window_manager: ^0.3.7
```

### Raspberry Pi (`requirements.txt`)
```
flask==3.0.0
flask-socketio==5.3.5
picamera2==0.3.16
opencv-python==4.8.1.78
mediapipe==0.10.8
face-recognition==1.3.0
pyserial==3.5
RPi.GPIO==0.7.1
```

### Arduino Libraries
```
None (built-in only)
```

---

## 🚀 Deployment Steps

1. **Setup Raspberry Pi**
   ```bash
   cd rpi
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Setup Flutter App**
   ```bash
   cd medical_destrebutor_app
   flutter pub get
   flutter run -d windows
   ```

3. **Upload Arduino Code**
   - Open `line_follower.ino` in Arduino IDE
   - Select board & port
   - Upload

4. **Configure Servos**
   - Calibrate wheel angles
   - Test door open/close
   - Set medicine angles

5. **Train Face Recognition**
   - Add patients in Flutter app
   - Capture multiple face images
   - Train model on RPi

---

## 📝 Next Steps

**What do you want me to build first?**

1. 🎨 **Flutter UI** - Complete 4-section desktop app
2. 🤖 **RPi State Machine** - Robot control logic
3. 🔧 **Arduino Code** - Line following with serial
4. 📡 **Communication Layer** - HTTP + WebSocket APIs
5. 🧠 **Face Recognition** - Training & recognition module
6. 🎡 **Medicine Wheel Controller** - Servo logic with 180° rotation

Or I can build everything in sequence! Just let me know.
