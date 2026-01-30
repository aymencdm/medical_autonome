# 🤖 Autonomous Medical Delivery Robot

A complete autonomous hospital medicine delivery system combining Arduino line following, Raspberry Pi vision/logic, and Flutter desktop control application.

---

## 🎯 System Overview

### Components
1. **Arduino Uno** - Line following with 5 IR sensors + PID control
2. **Raspberry Pi 4** - Face tracking, face recognition, servo control
3. **Pan/Tilt Servos** - Face tracking system (existing)
4. **Medicine Carousel** - Horizontal rotating wheel with door servo
5. **Flutter Desktop App** - Control interface and management system

### Core Logic Rules
✅ **Angles belong to MEDICINES, not patients**  
✅ **Mapping: Patient → Medicine → Angle**  
✅ **180° backward rotation before medicine alignment**

---

## 📋 Finite State Machine

```
[IDLE]
    ↓ (start)
[LINE_FOLLOWING]
    ↓ (all IR sensors detect black)
[STOPPED_WAITING]
    ↓ (Arduino sends "STOP")
[FACE_TRACKING]
    ↓ (face detected for 3 seconds)
[FACE_RECOGNITION]
    ↓ (patient recognized)
[MEDICINE_DISPENSING]
    ├─→ 1. Rotate 180° backward
    ├─→ 2. Rotate to medicine angle
    ├─→ 3. Open door
    ├─→ 4. Wait 10 seconds
    └─→ 5. Close door
[WAITING_FOR_PICKUP]
    ↓ (timer complete)
[RESUMING]
    ↓ (send "RESUME" to Arduino)
[LINE_FOLLOWING]
    ↓ (repeat)
```

---

## 🚀 Installation & Setup

### 1. Raspberry Pi Setup

```bash
cd rpi
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Update `config.py`
- Set correct GPIO pins for all servos
- Configure camera settings
- Set Arduino serial port

#### Run Server
```bash
python main.py
```

### 2. Flutter Desktop App Setup

```bash
cd medical_destrebutor_app
flutter pub get
flutter run -d windows  # or -d macos, -d linux
```

#### Configure RPi Connection
In `lib/main.dart`, update:
```dart
final rpiService = RaspberryPiService(
  baseUrl: 'http://YOUR_RPI_IP:8080',
);
```

### 3. Arduino Setup

1. Open `arduino/line_follower/line_follower.ino` in Arduino IDE
2. Select your board (Arduino Uno/Nano)
3. Select correct COM port
4. Upload sketch

#### Calibrate IR Sensors
- Adjust `BLACK_THRESHOLD` in code based on your sensors
- Use Serial Monitor to view sensor readings
- Tune PID constants (`KP`, `KI`, `KD`) for smooth following

---

## 🎨 Flutter App Features

### 1. Patient Management
- Add/edit/delete patients
- Capture multiple face images per patient
- Train face recognition dataset
- View training status

### 2. Medicine Wheel Management
- **Circular carousel visualizer** (360° wheel)
- Add medicines with:
  - Name
  - Fixed servo angle (0-360°)
  - Slot index
- **180° backward rotation visualization**
- Manual wheel testing
- Real-time angle display

### 3. Patient → Medicine Assignment
- Assign one medicine per patient
- View assignment table
- Patient | Medicine | Angle mapping

### 4. Live Camera & System Status
- Real-time camera feed
- System mode indicator
- Wheel angle display
- Door status (open/closed)
- Recognized patient name
- Emergency stop button

---

## 🔧 Hardware Wiring

### Arduino
```
IR Sensors:
- L2 → A0
- L1 → A1
- C  → A2
- R1 → A3
- R2 → A4

Motor Driver (L298N):
- Left Motor Enable  → Pin 5 (PWM)
- Left Motor IN1     → Pin 6
- Left Motor IN2     → Pin 7
- Right Motor Enable → Pin 10 (PWM)
- Right Motor IN1    → Pin 8
- Right Motor IN2    → Pin 9
```

### Raspberry Pi
```
Face Tracking Servos:
- Pan Servo  → GPIO 17
- Tilt Servo → GPIO 27

Medicine Carousel:
- Wheel Servo → GPIO 22
- Door Servo  → GPIO 23

Arduino Communication:
- Serial → /dev/ttyUSB0 (or /dev/ttyACM0)
```

---

## 📡 Communication Protocol

### HTTP REST API

```
POST   /api/patients              # Add patient
GET    /api/patients              # List patients
DELETE /api/patients/{id}         # Delete patient
POST   /api/patients/{id}/faces   # Upload face images
POST   /api/train                 # Train face recognition

POST   /api/medicines             # Add medicine
GET    /api/medicines             # List medicines
PUT    /api/medicines/{id}        # Update medicine
DELETE /api/medicines/{id}        # Delete medicine

POST   /api/assignments           # Assign patient → medicine
GET    /api/assignments           # List assignments

GET    /api/system/status         # System state
POST   /api/system/emergency_stop # Emergency stop
POST   /api/wheel/rotate          # Manual wheel rotation
POST   /api/wheel/door            # Test door servo
```

### WebSocket Events

```
Client ← Server:
- video_frame           # JPEG frame bytes
- system_state_update   # FSM state change
- wheel_angle_update    # Wheel position
- door_state_update     # Door open/closed
- patient_recognized    # Recognition result

Client → Server:
- toggle_tracking       # Enable/disable face tracking
- manual_move           # Manual servo control
- center                # Center servos
```

### Serial (Arduino ↔ RPi)

```
Arduino → RPi:  "STOP\n"
RPi → Arduino:  "RESUME\n"
```

---

## 🧪 Testing Workflow

1. **Add Medicines**
   - Go to Medicine Wheel screen
   - Add medicines with specific angles
   - Test wheel rotation (180° backward + alignment)

2. **Add Patients**
   - Go to Patient Management
   - Add patient
   - Capture 5-10 face images per patient
   - Train face recognition

3. **Assign Patients**
   - Go to Assignment screen
   - Assign medicine to each patient

4. **Test Full Flow**
   - Place robot on line
   - Arduino starts line following
   - Robot stops at black marker (all sensors black)
   - Face tracking activates
   - Stand in front of camera for 3 seconds
   - Face recognition identifies patient
   - Medicine carousel dispenses medicine
   - Robot resumes line following

---

## ⚠️ Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| Unknown Face | Patient not recognized | Retrain with more images |
| No Medicine Assigned | Patient has no medicine | Assign in Assignment screen |
| Servo Timeout | Servo not reaching angle | Check wiring & power |
| Arduino Timeout | No "STOP" signal | Check serial connection |
| Door Jam | Door servo stuck | Check mechanical obstruction |

---

## 🎯 Medicine Dispensing Logic

```python
async def dispense_medicine(patient_id):
    # 1. Get patient's assigned medicine
    medicine = get_medicine_for_patient(patient_id)
    
    # 2. Rotate 180° backward
    current = wheel_controller.get_angle()
    backward = (current + 180) % 360
    await wheel_controller.rotate_to(backward)
    
    # 3. Rotate to medicine angle
    await wheel_controller.rotate_to(medicine.angle)
    
    # 4. Open door
    await door_servo.open()
    
    # 5. Wait 10 seconds
    await asyncio.sleep(10)
    
    # 6. Close door
    await door_servo.close()
    
    # 7. Resume line following
    arduino.send("RESUME")
```

---

## 📝 Configuration Files

### `rpi/config.py`
- Servo pins
- Camera settings
- Face tracking parameters
- Medicine wheel settings
- Arduino serial port

### `lib/main.dart`
- Raspberry Pi IP address
- WebSocket namespace
- Theme customization

---

## 🔮 Future Enhancements

- [ ] Multiple medicine compartments
- [ ] Voice feedback ("Please take your medicine")
- [ ] LCD display on robot
- [ ] Battery monitoring
- [ ] Obstacle avoidance with ultrasonic sensors
- [ ] Mobile app (iOS/Android)
- [ ] Cloud logging and analytics
- [ ] Multi-language support

---

## 📖 License

MIT License - See LICENSE file for details

---

## 🤝 Contributing

Pull requests welcome! Please follow the code style and add tests for new features.

---

## 📧 Support

For issues or questions:
- Open an issue on GitHub
- Contact: [your-email@example.com]

---

**Built with ❤️ for autonomous hospital medicine delivery**
