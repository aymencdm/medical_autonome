# 📚 Documentation Index

Welcome to the **Autonomous Medical Delivery Robot** project!

---

## 🚀 Quick Navigation

### For First-Time Users
1. **Start Here:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Overview of what was built
2. **Quick Setup:** [QUICKSTART.md](QUICKSTART.md) - 10-step guide to get running
3. **Hardware:** [HARDWARE_SETUP.md](HARDWARE_SETUP.md) - Wiring and assembly

### For Developers
1. **Full Documentation:** [README.md](README.md) - Complete technical reference
2. **Implementation Plan:** [.agent/workflows/implementation-plan.md](.agent/workflows/implementation-plan.md) - Detailed specifications

### For Deployment
1. **Deployment Checklist:** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Pre-launch verification

---

## 📖 Document Descriptions

### 📄 PROJECT_SUMMARY.md
**What is it:** High-level overview of the entire system  
**Read if:** You want to understand what was built and how it works  
**Time:** 10 minutes  
**Topics:**
- Complete feature list
- Flutter UI overview
- Raspberry Pi modules
- Arduino code
- 180° backward rotation logic
- Control flow
- Project structure

---

### 📄 QUICKSTART.md
**What is it:** Step-by-step setup guide  
**Read if:** You want to get the system running quickly  
**Time:** 30 minutes total (5-10 min per step)  
**Topics:**
- Raspberry Pi setup (5 min)
- Arduino setup (5 min)
- Flutter app setup (5 min)
- Adding medicines (2 min)
- Adding patients (3 min)
- Training face recognition (1 min)
- Full system test (5 min)
- Troubleshooting

---

### 📄 README.md
**What is it:** Complete technical documentation  
**Read if:** You need detailed information about any component  
**Time:** 30-45 minutes  
**Topics:**
- System overview
- Finite state machine (FSM)
- Installation instructions
- Flutter app features
- Raspberry Pi modules
- Arduino line follower
- Communication protocols (HTTP/WebSocket/Serial)
- Medicine dispensing logic
- Error handling
- Testing workflow
- Dependencies

---

### 📄 HARDWARE_SETUP.md
**What is it:** Hardware assembly and wiring guide  
**Read if:** You need to build or troubleshoot the physical robot  
**Time:** 60 minutes (assembly) + 30 minutes (testing)  
**Topics:**
- Components list
- Raspberry Pi GPIO wiring
- Arduino wiring
- Power distribution
- Assembly steps
- Component testing
- Calibration procedures
- Mechanical design
- Troubleshooting hardware

---

### 📄 DEPLOYMENT_CHECKLIST.md
**What is it:** Pre-deployment verification checklist  
**Read if:** You're preparing to deploy the system in production  
**Time:** 2-4 hours (full validation)  
**Topics:**
- Hardware verification
- Software installation
- Database setup
- Face recognition training
- Communication testing
- FSM state testing
- Error handling validation
- Performance testing
- Safety checklist
- User training
- Sign-off

---

### 📄 .agent/workflows/implementation-plan.md
**What is it:** Detailed implementation specification  
**Read if:** You want to understand design decisions or extend the system  
**Time:** 20 minutes  
**Topics:**
- Phase-by-phase breakdown
- Architecture diagrams
- File structure
- Module specifications
- Communication protocols
- Servo configuration
- Face recognition details
- Dependencies list
- Deployment steps

---

## 🎯 Reading Paths by Role

### 👨‍💻 **Software Developer**
1. PROJECT_SUMMARY.md (understand system)
2. README.md (technical details)
3. implementation-plan.md (architecture)
4. Start coding!

### 🔧 **Hardware Engineer**
1. HARDWARE_SETUP.md (wiring diagrams)
2. PROJECT_SUMMARY.md (system overview)
3. DEPLOYMENT_CHECKLIST.md (testing procedures)
4. Start assembling!

### 🚀 **Project Manager**
1. PROJECT_SUMMARY.md (deliverables)
2. DEPLOYMENT_CHECKLIST.md (requirements)
3. QUICKSTART.md (timeline estimation)
4. Plan deployment!

### 🏥 **Hospital Administrator**
1. QUICKSTART.md (how to use)
2. DEPLOYMENT_CHECKLIST.md → User Training section
3. README.md → Error Handling section
4. Start training staff!

### 🎓 **Student / Learner**
1. PROJECT_SUMMARY.md (what it does)
2. README.md → FSM section (how it works)
3. implementation-plan.md (how to build)
4. HARDWARE_SETUP.md (hands-on)
5. Build your own!

---

## 📊 Visual Diagrams

### Finite State Machine (FSM)
See generated diagram: `fsm_diagram.png`

**Shows:**
- All robot states (IDLE, LINE_FOLLOWING, FACE_TRACKING, etc.)
- State transitions with conditions
- Medicine dispensing sub-steps
- Error handling flows

### System Architecture
See generated diagram: `system_architecture.png`

**Shows:**
- Flutter Desktop App (4 sections)
- Raspberry Pi modules
- Arduino components
- Hardware connections
- Data flow (HTTP/WebSocket/Serial)

---

## 🔗 External Resources

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [SocketIO Client](https://pub.dev/packages/socket_io_client)

### Raspberry Pi
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [GPIO Pinout](https://pinout.xyz/)
- [PiCamera2](https://datasheets.raspberrypi.com/camera/picamera2-manual.pdf)

### Arduino
- [Arduino Reference](https://www.arduino.cc/reference/en/)
- [PID Control Tutorial](https://www.electronicwings.com/arduino/pid-control-for-arduino)

### Face Recognition
- [OpenCV Documentation](https://docs.opencv.org/)
- [LBPH Face Recognizer](https://docs.opencv.org/4.x/df/d25/tutorial_py_face_detection.html)

---

## 📞 Support & Troubleshooting

### Issue Resolution Order
1. Check **QUICKSTART.md** → Troubleshooting section
2. Check **HARDWARE_SETUP.md** → Troubleshooting Hardware section
3. Check **README.md** → Error Handling section
4. Check **DEPLOYMENT_CHECKLIST.md** → Performance Testing section
5. Open GitHub issue with:
   - Symptoms
   - Error messages
   - What you've tried
   - Hardware/software versions

---

## 🎓 Code Examples

### Testing Face Recognition (Python)
```python
from face_recognizer import FaceRecognizer

recognizer = FaceRecognizer()
recognizer.load_model()

# Test with camera
import cv2
cap = cv2.VideoCapture(0)
ret, frame = cap.read()
patient_name, confidence = recognizer.recognize(frame)
print(f"Recognized: {patient_name}, Confidence: {confidence}")
```

### Testing Medicine Wheel (Python)
```python
from medicine_controller import MedicineController
import asyncio

controller = MedicineController()
asyncio.run(controller.dispense_medicine(medicine_angle=90))
```

### Testing Flutter Database (Dart)
```dart
final db = DatabaseService();
final patients = await db.getAllPatients();
print('Total patients: ${patients.length}');
```

---

## ✅ Quick Reference

### Key Concepts
- **Angles → Medicines** (not patients!)
- **180° Backward Rotation** (always before alignment)
- **Patient → Medicine → Angle** (mapping chain)
- **FSM** (Finite State Machine for robot control)

### Critical Files
- `rpi/main_extended.py` - Main server
- `rpi/medicine_controller.py` - Dispensing logic
- `lib/screens/medicine_wheel_screen.dart` - UI
- `lib/widgets/medicine_wheel_visualizer.dart` - Wheel animation
- `arduino/line_follower/line_follower.ino` - Line following

### Important Commands
```bash
# Start Raspberry Pi server
python rpi/main_extended.py

# Start Flutter app
flutter run -d windows

# Upload Arduino code
# (Use Arduino IDE)

# Test camera
libcamera-still -o test.jpg

# Monitor serial
screen /dev/ttyUSB0 9600
```

---

## 🎉 Success Checklist

- [ ] Read PROJECT_SUMMARY.md
- [ ] Followed QUICKSTART.md
- [ ] System running successfully
- [ ] Able to add patients
- [ ] Able to add medicines
- [ ] Face recognition working
- [ ] Medicine wheel rotating correctly
- [ ] 180° backward rotation verified
- [ ] Full dispensing cycle tested
- [ ] Reviewed DEPLOYMENT_CHECKLIST.md

**If all checked → You're ready to deploy! 🚀**

---

**Need help? Start with QUICKSTART.md!**  
**Want details? Read README.md!**  
**Ready to launch? Use DEPLOYMENT_CHECKLIST.md!**
