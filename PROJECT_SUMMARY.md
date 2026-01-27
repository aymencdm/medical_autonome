# Face Tracker RTP Streaming - Complete Guide

## 🎯 Overview

This project converts your Raspberry Pi face tracker to use **RTP (Real-time Transport Protocol)** streaming with a **Flutter Windows desktop viewer application** (not mobile).

## 📦 What You Get

1. **Raspberry Pi RTP Server** (`rpi/app_rtp.py`) - Streams H.264 video over RTP
2. **Flutter Desktop Viewer** (`face_tracker_viewer/`) - Windows app to view the stream
3. **Original HTTP Server** (`rpi/app.py`) - Still available if needed

## 🚀 Quick Start

### Step 1: Raspberry Pi Setup (One-time)

```bash
# Install GStreamer
sudo apt-get update
sudo apt-get install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav

# Install Python dependencies
cd rpi
pip install -r requirements_rtp.txt

# Test setup
python test_setup.py
```

### Step 2: Start Streaming

```bash
# On Raspberry Pi
cd rpi
python app_rtp.py
```

Note the IP address (e.g., `192.168.1.100`)

### Step 3: Run Desktop Viewer

```bash
# On Windows PC
cd face_tracker_viewer
flutter run -d windows
```

### Step 4: Connect and Watch

1. Enter Raspberry Pi IP in the app
2. Click "Connect"
3. Click "Start Stream"
4. Enjoy the live feed!

## 🏗️ Architecture

```
┌─────────────────────┐         WiFi          ┌──────────────────────┐
│   Raspberry Pi      │◄─────────────────────►│   Windows PC         │
│                     │                        │                      │
│  ┌───────────────┐  │                        │  ┌────────────────┐  │
│  │  Picamera2    │  │                        │  │  Flutter App   │  │
│  └───────┬───────┘  │                        │  └────────┬───────┘  │
│          ↓          │                        │           ↓          │
│  ┌───────────────┐  │                        │  ┌────────────────┐  │
│  │ H.264 Encoder │  │                        │  │  VLC Player    │  │
│  └───────┬───────┘  │                        │  └────────┬───────┘  │
│          ↓          │                        │           ↓          │
│  ┌───────────────┐  │   RTP Stream (5000)   │  ┌────────────────┐  │
│  │  GStreamer    │──┼───────────────────────┼─►│ Video Display  │  │
│  └───────────────┘  │                        │  └────────────────┘  │
│                     │                        │                      │
│  ┌───────────────┐  │   HTTP API (8080)     │  ┌────────────────┐  │
│  │  Flask API    │◄─┼───────────────────────┼──│  HTTP Client   │  │
│  └───────────────┘  │                        │  └────────────────┘  │
└─────────────────────┘                        └──────────────────────┘
```

## 📁 Project Structure

```
ppp/
├── rpi/                           # Raspberry Pi code
│   ├── app.py                     # Original HTTP/MJPEG server
│   ├── app_rtp.py                # ⭐ NEW: RTP streaming server
│   ├── face_tracker.py           # Face tracking logic
│   ├── requirements.txt          # Original dependencies
│   ├── requirements_rtp.txt      # ⭐ NEW: RTP dependencies
│   └── test_setup.py             # ⭐ NEW: Setup verification
│
├── face_tracker_viewer/          # ⭐ NEW: Flutter desktop app
│   ├── lib/
│   │   ├── main.dart             # App entry + window config
│   │   ├── services/
│   │   │   └── stream_service.dart    # API + state management
│   │   └── screens/
│   │       └── viewer_screen.dart     # Main UI
│   ├── windows/                  # Windows platform code
│   ├── pubspec.yaml              # Flutter dependencies
│   └── README.md                 # App documentation
│
├── face_tracker_app/             # Mobile app (if you want it)
│   └── ...
│
├── PROJECT_SUMMARY.md            # ⭐ This file
├── QUICKSTART.md                 # Quick reference
└── README.md                     # General documentation
```

## 🔧 Key Technologies

### Raspberry Pi
- **Python 3** - Programming language
- **Flask** - HTTP API server
- **Picamera2** - Camera interface
- **GStreamer** - RTP streaming pipeline
- **H.264** - Video codec

### Desktop Viewer
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **dart_vlc** - VLC media player integration
- **window_manager** - Window customization
- **Provider** - State management

## 📊 RTP vs HTTP Comparison

| Feature | HTTP/MJPEG (Old) | RTP/H.264 (New) |
|---------|------------------|-----------------|
| **Latency** | ~500ms | ~100-200ms |
| **Bandwidth** | High | Low (better compression) |
| **Quality** | Good | Better |
| **Mobile Support** | Limited | Excellent |
| **Desktop Support** | Browser only | Native app |
| **Protocol** | HTTP | RTP (designed for streaming) |
| **Codec** | JPEG | H.264 |

## 🎨 Desktop App Features

### UI Layout
- **Split Panel Design** - Controls on left, video on right
- **Dark Theme** - Professional appearance
- **Live Indicator** - Shows when streaming is active
- **Stream Info** - Real-time statistics display

### Controls
- **Connection Management** - Easy IP input and connection
- **Stream Control** - Start/stop streaming
- **Status Monitoring** - Real-time connection and stream status

## 🌐 Network Configuration

### Required Ports
- **5000** - RTP video stream
- **5001** - RTCP control
- **8080** - HTTP API

### Requirements
- Both devices on same WiFi network
- Recommended: 5 Mbps+ WiFi speed
- Firewall must allow the ports above

## 🛠️ Customization

### Video Quality (Raspberry Pi)

Edit `rpi/app_rtp.py`:
```python
VIDEO_WIDTH = 640          # Resolution width
VIDEO_HEIGHT = 480         # Resolution height
VIDEO_FPS = 30             # Frames per second
VIDEO_BITRATE = 1000000    # 1 Mbps (adjust as needed)
```

### Window Size (Desktop App)

Edit `face_tracker_viewer/lib/main.dart`:
```dart
WindowOptions windowOptions = const WindowOptions(
  size: Size(1280, 800),        // Default window size
  minimumSize: Size(800, 600),  // Minimum allowed size
  // ...
);
```

### Theme Colors

Edit `face_tracker_viewer/lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF2196F3),  // Change this color
  brightness: Brightness.dark,
),
```

## 🐛 Troubleshooting

### Raspberry Pi Issues

**GStreamer not found**
```bash
sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-*
```

**Camera not working**
```bash
# Check camera
libcamera-hello

# Check if camera is enabled
sudo raspi-config
# Interface Options → Camera → Enable
```

**Port already in use**
```bash
# Find what's using the port
sudo lsof -i :5000
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>
```

### Desktop App Issues

**Flutter not found**
```bash
# Check Flutter installation
flutter doctor

# Fix any issues shown
```

**Can't connect to Pi**
- Verify IP address is correct
- Ping the Pi: `ping 192.168.1.100`
- Check firewall on both devices
- Ensure Pi server is running

**No video appears**
- Wait 5-10 seconds for initialization
- Check Pi logs for errors
- Restart the stream
- Verify GStreamer is installed on Pi

**Build errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d windows
```

## 📦 Building for Distribution

### Create Windows Executable

```bash
cd face_tracker_viewer
flutter build windows --release
```

Executable location:
```
build\windows\x64\runner\Release\face_tracker_viewer.exe
```

### Create Installer (Optional)

Use **Inno Setup** or **MSIX** to create an installer package.

## 🔄 Workflow

### Daily Use

1. **Start Pi Server**:
   ```bash
   python app_rtp.py
   ```

2. **Run Desktop App**:
   ```bash
   flutter run -d windows
   ```

3. **Connect and Stream** - Use the UI

### Development

```bash
# Run in debug mode
flutter run -d windows

# Hot reload (press 'r' while running)

# View logs
flutter logs
```

## 📝 API Reference

### Raspberry Pi Endpoints

```
GET  /health              - Health check
GET  /api/stream/info     - Stream configuration
GET  /stream.sdp          - SDP file for RTP
POST /api/stream/start    - Start streaming
POST /api/stream/stop     - Stop streaming
```

### Example API Call

```bash
# Check if server is running
curl http://192.168.1.100:8080/health

# Get stream info
curl http://192.168.1.100:8080/api/stream/info

# Start stream
curl -X POST http://192.168.1.100:8080/api/stream/start
```

## 🎯 Use Cases

### Monitoring Station
- Set up desktop PC as dedicated monitoring station
- Large screen for better visibility
- Always-on connection to Pi

### Development/Testing
- Test face tracking algorithms
- Debug camera positioning
- Monitor servo movements

### Demonstration
- Show face tracking in action
- Professional presentation setup
- Easy to control and monitor

## 🔮 Future Enhancements

Possible additions:
- Recording functionality
- Snapshot capture
- Multiple camera support
- Stream quality adjustment in UI
- Connection history
- Auto-reconnect feature

## 📚 Additional Resources

- **Flutter Documentation**: https://docs.flutter.dev/
- **GStreamer Documentation**: https://gstreamer.freedesktop.org/documentation/
- **RTP Protocol**: https://en.wikipedia.org/wiki/Real-time_Transport_Protocol
- **Picamera2 Guide**: https://datasheets.raspberrypi.com/camera/picamera2-manual.pdf

## ✅ Checklist

Before running:
- [ ] GStreamer installed on Raspberry Pi
- [ ] Python dependencies installed (`requirements_rtp.txt`)
- [ ] Flutter installed on Windows PC
- [ ] Both devices on same network
- [ ] Firewall configured (ports 5000, 5001, 8080)
- [ ] Camera working on Raspberry Pi

## 🆘 Getting Help

1. Check `QUICKSTART.md` for quick reference
2. Review `face_tracker_viewer/README.md` for app-specific help
3. Run `python test_setup.py` on Pi to verify setup
4. Check logs on both Pi and desktop app
5. Verify network connectivity

## 📄 License

MIT License - Free to use and modify

## 👏 Credits

Built with:
- Flutter & Dart
- VLC Media Player (dart_vlc)
- GStreamer
- Python Flask
- Raspberry Pi Picamera2

---

**Note**: This is a desktop application, not a mobile app. If you need a mobile version, the `face_tracker_app` directory contains an Android version.
