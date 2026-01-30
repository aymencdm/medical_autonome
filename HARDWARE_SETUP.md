# Hardware Setup Guide

## 🔌 Complete Wiring Diagram

### Components List

#### Electronics
- [ ] Raspberry Pi 4 (4GB+ RAM)
- [ ] Pi Camera v2.1
- [ ] Arduino Uno or Nano
- [ ] L298N Motor Driver
- [ ] 5x IR Line Sensors (TCRT5000)
- [ ] 2x DC Gearmotors (6V-12V)
- [ ] 4x Servo Motors:
  - [ ] Pan servo (face tracking)
  - [ ] Tilt servo (face tracking)
  - [ ] Wheel servo (carousel rotation)
  - [ ] Door servo (medicine dispenser)

#### Power
- [ ] 12V LiPo/Li-ion battery (2200mAh+)
- [ ] 5V Buck converter (for Arduino/servos)
- [ ] USB power bank (for Raspberry Pi)

#### Mechanical
- [ ] Robot chassis
- [ ] Pan-tilt bracket
- [ ] Horizontal medicine wheel (3D printed)
- [ ] Medicine compartments (6-12 slots)
- [ ] Door mechanism with hinge

---

## 📐 Raspberry Pi 4 Wiring

### GPIO Pin Assignments

```
GPIO 17 → Pan Servo (Signal - Orange wire)
GPIO 27 → Tilt Servo (Signal - Orange wire)
GPIO 22 → Wheel Servo (Signal - Orange wire)
GPIO 23 → Door Servo (Signal - Orange wire)

All Servos:
- Red wire → 5V
- Brown/Black wire → GND
```

### Camera
```
Camera ribbon cable → Raspberry Pi Camera port
```

### Serial to Arduino
```
Raspberry Pi TX (GPIO 14) → Arduino RX (Pin 0)
Raspberry Pi RX (GPIO 15) → Arduino TX (Pin 1)
GND → GND
```

**Note:** Use USB cable for easier connection:
```
Arduino USB → Raspberry Pi USB port
```

---

## 🤖 Arduino Uno Wiring

### IR Sensors (Analog Pins)
```
Sensor L2 → A0
Sensor L1 → A1
Sensor C  → A2
Sensor R1 → A3
Sensor R2 → A4

All sensors:
- VCC → 5V
- GND → GND
```

### Motor Driver (L298N)
```
Left Motor:
- Enable (PWM) → Pin 5
- IN1 → Pin 6
- IN2 → Pin 7

Right Motor:
- Enable (PWM) → Pin 10
- IN1 → Pin 8
- IN2 → Pin 9

Motor Driver Power:
- 12V → Battery 12V
- GND → Battery GND
- 5V Enable → Jumper ON (to power Arduino)
- 5V Out → Arduino Vin
```

### Power
```
Option 1: Power from L298N
- L298N 5V → Arduino Vin

Option 2: Separate power
- Battery → 5V Buck Converter → Arduino Vin
```

---

## ⚡ Power Distribution

### Voltage Requirements
| Component | Voltage | Current | Source |
|-----------|---------|---------|--------|
| Raspberry Pi 4 | 5V 3A | 3A+ | USB-C Power Bank |
| Arduino Uno | 7-12V | 500mA | 5V Buck or L298N |
| Face Servos (2x) | 5V | 1A total | Buck Converter |
| Wheel Servo | 5V | 1A | Buck Converter |
| Door Servo | 5V | 500mA | Buck Converter |
| DC Motors (2x) | 6-12V | 2A total | L298N via Battery |
| IR Sensors (5x) | 5V | 250mA | Arduino 5V |

### Power Schematic
```
12V Battery (2200mAh)
    ├─→ L298N Motor Driver
    │   ├─→ Motor 1
    │   ├─→ Motor 2
    │   └─→ Arduino Vin (via 5V regulator)
    │
    └─→ 5V 3A Buck Converter
        ├─→ Pan/Tilt Servos
        ├─→ Wheel Servo
        └─→ Door Servo

USB Power Bank (10000mAh)
    └─→ Raspberry Pi 4 (USB-C)
```

---

## 🔧 Assembly Steps

### 1. Build Robot Base (30 min)
- Mount chassis
- Install DC motors
- Connect wheels
- Mount L298N motor driver

### 2. Install Line Sensors (15 min)
- Mount 5 IR sensors in a line at front
- Spacing: ~1.5cm apart
- Height: 3-5mm above ground
- Connect to Arduino analog pins

### 3. Install Arduino (10 min)
- Mount Arduino on chassis
- Connect to motor driver
- Connect IR sensors
- Route wires neatly

### 4. Install Raspberry Pi (20 min)
- Mount Raspberry Pi (elevated for cooling)
- Install Pan-Tilt bracket
- Mount Pi Camera on tilt servo
- Connect servos to GPIO pins

### 5. Build Medicine Wheel (60 min)
- 3D print or fabricate circular wheel
- Create 6-12 compartments
- Mount wheel servo (horizontal)
- Install door servo
- Test rotation (should spin 360°)

### 6. Wire Everything (45 min)
- Connect all power cables
- Connect serial (Arduino ↔ Raspberry Pi)
- Double-check polarity
- Use zip ties for cable management
- Label all connections

### 7. Software Upload (30 min)
- Upload Arduino code
- Install Raspberry Pi OS
- Clone project
- Install dependencies
- Test each component

---

## ✅ Component Testing

### Test 1: Arduino IR Sensors
```arduino
// Open Serial Monitor
void loop() {
  Serial.print(analogRead(A0)); Serial.print(" ");
  Serial.print(analogRead(A1)); Serial.print(" ");
  Serial.print(analogRead(A2)); Serial.print(" ");
  Serial.print(analogRead(A3)); Serial.print(" ");
  Serial.println(analogRead(A4));
  delay(100);
}
```
**Expected:** Values change between ~0-1023 (white) and near threshold (black)

### Test 2: Motors
```arduino
// Test both motors forward
digitalWrite(6, HIGH);
digitalWrite(7, LOW);
analogWrite(5, 150);

digitalWrite(8, HIGH);
digitalWrite(9, LOW);
analogWrite(10, 150);
delay(2000);
```
**Expected:** Both motors spin forward at medium speed

### Test 3: Raspberry Pi Camera
```bash
libcamera-still -o test.jpg
```
**Expected:** Image saved to test.jpg

### Test 4: Face Tracking Servos
```bash
cd rpi
python main.py
```
**Expected:** Servos center, camera feed starts

### Test 5: Medicine Wheel Servo
```python
import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setup(22, GPIO.OUT)
pwm = GPIO.PWM(22, 50)
pwm.start(7.5)  # Center

for angle in range(0, 360, 45):
    duty = 2.5 + (angle / 180.0) * 10.0
    pwm.ChangeDutyCycle(duty)
    time.sleep(1)

pwm.stop()
GPIO.cleanup()
```
**Expected:** Wheel rotates through full circle

---

## 🔍 Troubleshooting Hardware

### Motors not spinning
- ✅ Check L298N power (12V LED on)
- ✅ Check motor connections
- ✅ Verify Arduino PWM pins
- ✅ Test with higher PWM value (255)

### Servos jittering
- ✅ Insufficient power (add capacitor 100μF near servo)
- ✅ Separate power supply for servos
- ✅ Check ground connection

### IR sensors not working
- ✅ Check 5V and GND connections
- ✅ Adjust sensor distance from ground
- ✅ Calibrate threshold in code

### Camera not detected
- ✅ Check ribbon cable connection
- ✅ Enable camera in `raspi-config`
- ✅ Restart Raspberry Pi

### Arduino serial not responding
- ✅ Check TX/RX crossover (TX→RX, RX→TX)
- ✅ Verify baud rate (9600)
- ✅ Use USB cable instead

---

## 📏 Mechanical Design Notes

### Medicine Wheel Dimensions
- **Diameter:** 20-30cm
- **Compartment size:** 5cm x 5cm x 3cm (adjustable)
- **Number of slots:** 6-12 (depends on medicine size)
- **Rotation:** Must be smooth, no wobble
- **Material:** 3D printed PLA or acrylic

### Door Mechanism
- **Type:** Hinged flap or sliding door
- **Servo angle:** 0° = closed, 90° = open
- **Gravity-based:** Medicine drops out when door opens
- **Material:** Lightweight (cardboard/plastic)

### Chassis Requirements
- **Size:** 25cm x 20cm minimum
- **Ground clearance:** 2-3cm for cables
- **Weight capacity:** 1.5kg (with all components)
- **Balance:** Center of mass must be stable

---

## 🎯 Calibration Checklist

### IR Sensors (Line Following)
- [ ] Place on white surface → note values
- [ ] Place on black line → note values
- [ ] Set `BLACK_THRESHOLD` midway
- [ ] Test with different lighting
- [ ] Tune PID constants

### Servos (Face Tracking)
- [ ] Center servos at 90°
- [ ] Test pan limits (0° to 180°)
- [ ] Test tilt limits (90° to 180°)
- [ ] Verify camera view at center
- [ ] Adjust dead zone

### Medicine Wheel
- [ ] Mark 0° position
- [ ] Test full 360° rotation
- [ ] Verify angle accuracy
- [ ] Map medicine slots to angles
- [ ] Test 180° backward rotation

### Door Servo
- [ ] Set closed angle (usually 0°)
- [ ] Set open angle (usually 90°)
- [ ] Test medicine drop
- [ ] Adjust timing (wait duration)

---

## 📦 Optional Enhancements

### Sensors
- [ ] Ultrasonic sensor (obstacle avoidance)
- [ ] Battery voltage monitor
- [ ] Weight sensor (verify medicine pickup)

### Display
- [ ] OLED screen (128x64) for status
- [ ] LED status indicators
- [ ] Buzzer for alerts

### Power
- [ ] Battery percentage display
- [ ] Low battery warning
- [ ] Charging port (XT60)

---

**Hardware setup complete! Proceed to software setup in QUICKSTART.md** 🔧✅
