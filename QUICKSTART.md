# 🚀 Quick Start Guide

## Prerequisites
- ✅ Raspberry Pi 4 with Pi Camera v2.1
- ✅ Arduino Uno/Nano
- ✅ Flutter installed on development machine
- ✅ All hardware assembled

---

## Step 1: Clone & Setup (5 minutes)

```bash
git clone [your-repo-url]
cd medical_destrebutor
```

---

## Step 2: Raspberry Pi Setup (10 minutes)

### Install Dependencies
```bash
cd rpi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Configure
Edit `config.py`:
- Set correct GPIO pins
- Adjust servo limits
- Set Arduino serial port

### Test Camera & Servos
```bash
python main.py
```

Visit `http://raspberrypi.local:8080/api/system/status`

If you see JSON response → ✅ Success!

---

## Step 3: Arduino Setup (5 minutes)

### Upload Code
1. Open `arduino/line_follower/line_follower.ino`
2. Connect Arduino via USB
3. Select Board & Port
4. Click Upload

### Calibrate Sensors
1. Open Serial Monitor (9600 baud)
2. Place robot on white surface
3. Note sensor values
4. Place on black line
5. Note sensor values
6. Adjust `BLACK_THRESHOLD` in code
7. Re-upload

---

## Step 4: Flutter App Setup (5 minutes)

### Install Dependencies
```bash
cd medical_destrebutor_app
flutter pub get
```

### Configure Raspberry Pi IP
Edit `lib/main.dart` line ~36:
```dart
baseUrl: 'http://192.168.1.100:8080',  // YOUR RPi IP
```

### Run App
```bash
flutter run -d windows
```

---

## Step 5: Add First Medicine (2 minutes)

1. Click **Medicine Wheel** tab
2. Click **+ Add Medicine**
3. Enter:
   - Name: `Aspirin`
   - Slot: `1`
   - Angle: `0`
4. Click **Add**
5. See the wheel visualizer update!

---

## Step 6: Add First Patient (3 minutes)

1. Click **Patient Management** tab
2. Click **+ Add Patient**
3. Enter name: `John Doe`
4. Click **Capture Faces**
5. Take 5-10 photos from different angles
6. Click **Save**

Repeat for 2-3 patients.

---

## Step 7: Train Face Recognition (1 minute)

1. Click **Train Model** button
2. Wait for training to complete (~30 seconds)
3. See "✅ Training Complete" message

---

## Step 8: Assign Medicines (1 minute)

1. Click **Assignment** tab
2. Select patient: `John Doe`
3. Select medicine: `Aspirin`
4. Click **Assign**

---

## Step 9: Test Medicine Wheel (1 minute)

1. Go to **Medicine Wheel** tab
2. Click on `Aspirin` medicine slot
3. Click **Rotate** in confirmation dialog
4. Watch the wheel:
   - Rotate 180° backward (red arrow shows)
   - Then rotate to target angle
   - Angle indicator updates in real-time

---

## Step 10: Full System Test (5 minutes)

### Prepare
1. Place robot on black line
2. Mark a "STOP" zone (all 5 sensors detect black)
3. Ensure Raspberry Pi is running: `python rpi/main_extended.py`
4. Ensure Arduino is powered & connected

### Test Flow
1. Robot starts → `LINE_FOLLOWING` mode
2. Robot reaches STOP zone → `STOPPED_WAITING`
3. Arduino sends "STOP" → `FACE_TRACKING` mode
4. Stand in front of camera (move slowly so it can track)
5. After 3 seconds → `FACE_RECOGNITION` mode
6. If recognized → `MEDICINE_DISPENSING` mode
   - Watch wheel rotate 180° backward
   - Watch wheel align to medicine angle
   - Door opens
   - Wait 10 seconds
   - Door closes
7. Robot resumes → `LINE_FOLLOWING` mode

### Check Status
In Flutter app, go to **Live System** tab to see:
- Current FSM state
- Wheel angle
- Door status
- Recognized patient

---

## Troubleshooting

### Robot doesn't stop at black marker
- **Cause**: IR sensors not calibrated
- **Fix**: Adjust `BLACK_THRESHOLD` in Arduino code

### Face tracking shaky
- **Cause**: PID gains too high
- **Fix**: Reduce `SPEED` in `rpi/config.py`

### Face recognition says "Unknown"
- **Cause**: Not enough training images
- **Fix**: Capture 10+ images per patient, retrain

### Wheel doesn't move
- **Cause**: Servo not connected or wrong pin
- **Fix**: Check wiring, verify WHEEL_PIN in config.py

### Door doesn't open
- **Cause**: Door servo angles incorrect
- **Fix**: Test with `curl -X POST http://rpi:8080/api/wheel/door -d '{"open":true}'`

### Arduino not responding
- **Cause**: Serial port incorrect
- **Fix**: Check `ls /dev/tty*` and update ARDUINO.PORT in config.py

---

## Next Steps

✅ Add more patients  
✅ Add more medicines  
✅ Adjust wheel rotation speed  
✅ Customize UI theme  
✅ Add voice feedback (future)  
✅ Deploy to multiple robots  

---

## Support

**Issues?** Open GitHub issue or check README.md

**Success?** Star the repo ⭐

---

**You're now ready to deploy an autonomous hospital medicine delivery robot! 🎉**
