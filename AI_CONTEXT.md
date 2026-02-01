# Medical Autonome - Architecture & Changes Documentation

> **For AI Assistants**: This document describes the current architecture and recent changes.  
> Read this first before making modifications.

---

## 📁 Project Structure

```
medical_autonome/
├── rpi/                              # Raspberry Pi Backend (Python)
│   ├── main.py                       # Main server - mode switching, no servos on startup
│   ├── config.py                     # All configuration settings
│   ├── normal_stream.py              # Normal streaming module (no AI, no servos)
│   ├── tracker.py                    # MediaPipe face tracking logic (Original)
│   ├── servos.py                     # Servo controller
│   └── requirements.txt              # Python dependencies
│
└── medical_destrebutor_app/          # Flutter Desktop App
    └── lib/
        ├── main.dart                 # App entry point with providers
        ├── screens/
        │   ├── viewer_screen.dart    # Main viewer with mode buttons
        │   └── settings_screen.dart  # IP/port settings
        └── services/
            ├── stream_service.dart   # Socket.IO streaming + mode control
            └── settings_service.dart # Persistent settings
```

---

## 🔄 Stream Modes (IMPORTANT)

The system has **two completely separate modes**:

| Mode | Servos | AI Tracking | Description |
|------|--------|-------------|-------------|
| `normal` | **OFF** | ❌ Disabled | Pure video streaming only |
| `face_tracking` | **ON** | ✅ Active | Smooth servo movement following faces |

### Key Behavior:
- **On Startup**: Server starts in `normal` mode with **servos completely OFF**
- **Switching to Normal**: Servos are disabled and cleaned up
- **Switching to Face Tracking**: Servos are initialized and start moving smoothly

---

## 📡 Socket.IO API Reference

### Namespace: `/stream`

#### Events from Client → Server

| Event | Payload | Description |
|-------|---------|-------------|
| `set_mode` | `{"mode": "normal" \| "face_tracking"}` | Switch streaming mode |
| `toggle_tracking` | `{"enabled": bool}` | Enable/disable face tracking AI |
| `manual_move` | `{"pan": float, "tilt": float}` | Move servos manually (tracking mode only) |
| `center` | (none) | Center servos (tracking mode only) |
| `get_status` | (none) | Request current system status |

#### Events from Server → Client

| Event | Payload | Description |
|-------|---------|-------------|
| `video_frame` | `bytes` | JPEG encoded frame |
| `status` | `{mode, pan, tilt, tracking, streaming, servos_active}` | System status |
| `mode_changed` | `{mode, servos_active}` | Broadcast when mode changes |

---

## 🔧 Key Files

### `rpi/main.py`
Main server file with clean separation:
- `start_servos()` - Initializes servos only when needed
- `stop_servos()` - Cleans up servos when not needed
- `camera_loop()` - Handles both modes with appropriate processing
- `servo_loop()` - Only moves servos when in face_tracking mode

### `rpi/tracker.py`
**Original Face Tracking Logic**:
- `FaceTrackerPro` class
- Implements Dead Zone, Nearest Neighbor, and Search Mode
- Directly used by `main.py` in `face_tracking` mode

### `rpi/normal_stream.py`
Simple streaming module:
- `NormalStreamer.process_frame()` - Basic frame processing (zoom, resize, flip)
- No AI, no servo interaction

### Flutter `viewer_screen.dart`
Main UI with:
- Two mode cards (Normal Stream / Face Tracking)
- Clearly shows "Servos OFF" vs "Servos ON"
- Servo controls only visible in Face Tracking mode

---

## 🎨 UI Mode Cards

The UI shows two distinct cards:

1. **Normal Stream** (Blue)
   - Icon: Video camera
   - Subtitle: "Video only • Servos OFF"
   
2. **Face Tracking** (Orange)
   - Icon: Face with effects
   - Subtitle: "AI tracking • Servos ON"

Only one can be selected at a time. Selecting a mode sends `set_mode` event to server.

---

## 📝 Configuration

### `rpi/config.py`

```python
CONFIG = {
    "VIDEO": {...},       # Width, height, FPS, JPEG quality, flip
    "SERVOS": {...},      # GPIO pins, limits, center positions
    "TRACKING": {...},    # FOV, dead zone, speed, confidence
    "SEARCH": {...},      # Search mode parameters
    "NETWORK": {...},     # Port: 8080, namespace: /stream
    "STREAM_MODE": {
        "DEFAULT": "normal"  # Always starts with servos OFF
    }
}
```

---

## 🚀 How to Extend

### Adding a New Stream Mode

1. **Create module** in `rpi/` (e.g., `my_mode_stream.py`)
2. **Import in main.py** and add instance
3. **Add mode check** in `camera_loop()` 
4. **Handle in `handle_set_mode()`** - enable/disable hardware as needed
5. **Update Flutter** - add new `StreamMode` enum value and UI card

### Modifying Servo Behavior

The servos are controlled in two places:
1. `face_tracking_stream.py` - Calculates new angles based on face position
2. `main.py` - `servo_control_loop()` applies angles at 50Hz

Adjust `TRACKING.SPEED` in config for slower/faster movement.

---

## ⚠️ Important Notes

1. **Servos OFF by Default**: Server always starts with servos disabled
2. **Mode Separation**: Each mode has its own module file
3. **Smooth Movement**: Servo loop runs at 50Hz with jitter prevention
4. **Cleanup**: Servos are properly cleaned up when switching to normal mode
5. **Tilt Safety**: Tilt servo has hard limits (90-180°) to prevent looking down

---

## 🔗 Dependencies

### RPi (requirements.txt)
```
flask
flask-socketio
eventlet
opencv-python
mediapipe
picamera2
RPi.GPIO
```

### Flutter (pubspec.yaml)
```yaml
socket_io_client: ^2.0.2
provider: ^6.1.1
shared_preferences: ^2.2.2
window_manager: ^0.3.7
```
