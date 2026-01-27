# 👁️ Face Tracking System for Raspberry Pi

A real-time face tracking system using a pan-tilt servo mechanism controlled by a Raspberry Pi. This system uses OpenCV for face detection and PID control for smooth servo movements.

![Pan-Tilt Servo Mechanism](https://example.com/servo.jpg)

## 🎯 Features

- **Real-time face detection** using OpenCV Haar Cascades
- **PID-controlled servo movement** for smooth, precise tracking
- **Web-based interface** for monitoring and control
- **Manual control mode** with joystick-style buttons
- **Debug overlay** showing tracking information
- **Responsive design** works on desktop and mobile

## 🔧 Hardware Requirements

- **Raspberry Pi** (3B+, 4, or newer recommended)
- **Pi Camera Module** (v1, v2, or HQ Camera)
- **2x Servo Motors** (SG90 or MG90S recommended)
- **Pan-Tilt Bracket** (like the one in the image)
- **5V Power Supply** (servos need adequate current)
- **Jumper Wires**

## 📌 Wiring Diagram

```
Raspberry Pi GPIO (BCM)     Servo Connections
─────────────────────────────────────────────
GPIO 17  ─────────────────►  Pan Servo (Signal - Orange wire)
GPIO 27  ─────────────────►  Tilt Servo (Signal - Orange wire)
5V       ─────────────────►  Both Servos (VCC - Red wire)
GND      ─────────────────►  Both Servos (GND - Brown wire)
```

### GPIO Pin Layout:
```
                    ┌─────────────────┐
           3V3 (1) │ ●             ● │ (2) 5V ──► Servo VCC
         GPIO2 (3) │ ●             ● │ (4) 5V
         GPIO3 (5) │ ●             ● │ (6) GND ─► Servo GND
         GPIO4 (7) │ ●             ● │ (8) GPIO14
           GND (9) │ ●             ● │ (10) GPIO15
Pan ◄── GPIO17(11) │ ●             ● │ (12) GPIO18
Tilt ◄─ GPIO27(13) │ ●             ● │ (14) GND
        GPIO22(15) │ ●             ● │ (16) GPIO23
           3V3(17) │ ●             ● │ (18) GPIO24
        GPIO10(19) │ ●             ● │ (20) GND
         GPIO9(21) │ ●             ● │ (22) GPIO25
        GPIO11(23) │ ●             ● │ (24) GPIO8
           GND(25) │ ●             ● │ (26) GPIO7
                    └─────────────────┘
```

## 📦 Installation

1. **Update your Raspberry Pi:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install system dependencies:**
   ```bash
   sudo apt install -y python3-opencv python3-picamera2 python3-flask python3-numpy
   ```

3. **Clone the project:**
   ```bash
   cd ~/
   git clone <your-repo-url> face_tracker
   cd face_tracker
   ```

4. **Install Python dependencies:**
   ```bash
   pip3 install -r requirements.txt
   ```

5. **Enable the camera (if not already enabled):**
   ```bash
   sudo raspi-config
   # Navigate to: Interface Options → Camera → Enable
   ```

## 🚀 Usage

### Running the Face Tracker

```bash
cd ~/face_tracker
python3 face_tracker.py
```

### Accessing the Web Interface

Open a browser and navigate to:
```
http://<raspberry-pi-ip>:5000
```

To find your Pi's IP address:
```bash
hostname -I
```

## 🎮 Controls

### Web Interface
- **Toggle Tracking**: Enable/disable automatic face tracking
- **Toggle Debug Overlay**: Show/hide tracking visualization
- **Center Button**: Move servos to center position
- **Joystick**: Manually control servo position

### Keyboard Shortcuts
- **Arrow Keys**: Move servos manually
- **Space**: Center servos

## ⚙️ Configuration

Edit the configuration section in `face_tracker.py`:

```python
# Camera settings
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480

# Servo GPIO pins (BCM numbering)
PAN_SERVO_PIN = 17   # Change if using different pins
TILT_SERVO_PIN = 27

# Servo angle limits
PAN_MIN_ANGLE = 0
PAN_MAX_ANGLE = 180
TILT_MIN_ANGLE = 30   # Limit tilting range
TILT_MAX_ANGLE = 150

# PID gains (tune for your setup)
PAN_KP = 0.05   # Proportional
PAN_KI = 0.001  # Integral
PAN_KD = 0.02   # Derivative
```

## 🔧 PID Tuning

If the tracking is too slow, jerky, or oscillating, tune the PID values:

| Issue | Solution |
|-------|----------|
| Slow response | Increase `KP` |
| Overshooting | Decrease `KP`, increase `KD` |
| Oscillating | Decrease `KP`, increase `KD` |
| Steady-state error | Increase `KI` |

## 📁 Project Structure

```
face_tracker/
├── face_tracker.py    # Main application
├── app.py             # Original camera streaming app
├── requirements.txt   # Python dependencies
├── README.md          # This file
└── templates/
    ├── index.html     # Original streaming page
    └── tracking.html  # Face tracking interface
```

## 🐛 Troubleshooting

### Camera not detected
```bash
# Check if camera is detected
vcgencmd get_camera
# Should show: supported=1 detected=1

# If using libcamera (Pi Camera v3 or newer)
libcamera-hello --list-cameras
```

### Servos not moving
1. Check wiring - ensure correct GPIO pins
2. Verify power supply can handle servo current
3. Test servos with simple script:
   ```python
   import RPi.GPIO as GPIO
   import time
   
   GPIO.setmode(GPIO.BCM)
   GPIO.setup(17, GPIO.OUT)
   
   servo = GPIO.PWM(17, 50)
   servo.start(7.5)  # Center position
   time.sleep(2)
   servo.stop()
   GPIO.cleanup()
   ```

### Face not detected
- Ensure adequate lighting
- Face the camera directly
- Adjust `minSize` in `detectMultiScale()` for face size

## 📄 License

MIT License - Feel free to use and modify!

## 🙏 Credits

- OpenCV for face detection
- Flask for web framework
- Picamera2 for camera interface
