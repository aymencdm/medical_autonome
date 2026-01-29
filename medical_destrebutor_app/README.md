# Face Tracker RTP Viewer - Desktop Application

A Flutter Windows desktop application that receives and displays RTP video streams from your Raspberry Pi face tracker.

## Features

- 🖥️ **Desktop Application** - Native Windows app (not mobile)
- 🎥 **Real-time RTP Streaming** - Low-latency video playback
- 🎨 **Beautiful UI** - Modern dark theme with split-panel design
- 📊 **Stream Monitoring** - Real-time stream information display
- ⚡ **VLC-powered** - Professional video playback using dart_vlc

## Quick Start

### 1. Run on Raspberry Pi

```bash
cd rpi
python app_rtp.py
```

Note the IP address displayed (e.g., `192.168.1.100`)

### 2. Run Desktop Viewer

```bash
cd face_tracker_viewer
flutter run -d windows
```

### 3. Connect and Stream

1. Enter the Raspberry Pi IP address in the left panel
2. Click "Connect"
3. Click "Start Stream"
4. Watch the live video feed!

## Installation

### Prerequisites

- **Windows 10/11**
- **Flutter SDK** (3.0 or higher)
- **Visual Studio 2022** with C++ desktop development tools

### Setup

1. **Clone/Navigate to project**:
   ```bash
   cd face_tracker_viewer
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run -d windows
   ```

## Building for Distribution

### Build Release Version

```bash
flutter build windows --release
```

The executable will be in:
```
build\windows\x64\runner\Release\face_tracker_viewer.exe
```

### Create Installer (Optional)

You can use tools like:
- **Inno Setup** - Create Windows installer
- **MSIX** - Create Microsoft Store package

## UI Layout

```
┌─────────────────────────────────────────────────────────┐
│  Face Tracker RTP Viewer                                │
├──────────────────┬──────────────────────────────────────┤
│                  │                                      │
│  Control Panel   │      Video Player                    │
│  (Left Sidebar)  │      (Main Area)                     │
│                  │                                      │
│  ┌────────────┐  │  ┌────────────────────────────────┐ │
│  │ Connection │  │  │                                │ │
│  │   Card     │  │  │                                │ │
│  └────────────┘  │  │     Live Video Stream          │ │
│                  │  │                                │ │
│  ┌────────────┐  │  │                                │ │
│  │  Stream    │  │  │                                │ │
│  │  Controls  │  │  └────────────────────────────────┘ │
│  └────────────┘  │                                      │
│                  │                                      │
│  ┌────────────┐  │                                      │
│  │  Stream    │  │                                      │
│  │   Info     │  │                                      │
│  └────────────┘  │                                      │
│                  │                                      │
└──────────────────┴──────────────────────────────────────┘
```

## Architecture

### Desktop App Components

```
face_tracker_viewer/
├── lib/
│   ├── main.dart                    # App entry + window config
│   ├── services/
│   │   └── stream_service.dart      # HTTP API + state management
│   └── screens/
│       └── viewer_screen.dart       # Main UI with video player
├── windows/                         # Windows platform code
└── pubspec.yaml                     # Dependencies
```

### Key Dependencies

- **dart_vlc** - VLC media player for Flutter (RTP support)
- **window_manager** - Window customization
- **provider** - State management
- **http** - API communication

## Network Configuration

The app connects to your Raspberry Pi on these ports:

- **Port 5000** - RTP video stream
- **Port 5001** - RTCP control
- **Port 8080** - HTTP API (stream control)

## Troubleshooting

### App won't start
- Ensure Flutter is properly installed: `flutter doctor`
- Check Visual Studio C++ tools are installed
- Try: `flutter clean` then `flutter pub get`

### Can't connect to Raspberry Pi
- Verify both devices are on the same network
- Ping the Pi: `ping <ip-address>`
- Check firewall settings on both devices
- Ensure `app_rtp.py` is running on the Pi

### No video appears
- Wait 5-10 seconds for stream initialization
- Check that GStreamer is installed on the Raspberry Pi
- Verify the stream is actually running (check Pi logs)
- Try restarting the stream

### Video is laggy
- Check your WiFi signal strength
- Reduce other network traffic
- Lower the bitrate in `app_rtp.py`:
  ```python
  VIDEO_BITRATE = 500000  # 500 Kbps instead of 1 Mbps
  ```

### VLC errors
- The app uses `dart_vlc` which requires VLC libraries
- These are automatically included with the package
- If issues persist, try reinstalling dependencies

## Customization

### Window Size

Edit `lib/main.dart`:
```dart
WindowOptions windowOptions = const WindowOptions(
  size: Size(1280, 800),        // Change window size
  minimumSize: Size(800, 600),  // Change minimum size
  // ...
);
```

### Theme Colors

Edit `lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF2196F3),  // Change accent color
  brightness: Brightness.dark,
),
```

### Video Quality

Edit `rpi/app_rtp.py` on Raspberry Pi:
```python
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 480
VIDEO_FPS = 30
VIDEO_BITRATE = 1000000  # Adjust bitrate
```

## Comparison: Desktop vs Mobile

| Feature | Desktop App | Mobile App |
|---------|-------------|------------|
| Platform | Windows | Android |
| Screen Size | Large (1280x800+) | Small (phone) |
| Use Case | Monitoring station | Portable viewing |
| Performance | Better | Good |
| UI Layout | Split panel | Scrollable |
| Keyboard | Full support | Limited |

## Development

### Run in Debug Mode

```bash
flutter run -d windows
```

### Hot Reload

Press `r` in the terminal while app is running

### View Logs

```bash
flutter logs
```

### Build Modes

```bash
# Debug (with DevTools)
flutter run -d windows

# Profile (performance testing)
flutter run -d windows --profile

# Release (optimized)
flutter run -d windows --release
```

## System Requirements

### Minimum
- Windows 10 (64-bit)
- 4 GB RAM
- 100 MB disk space
- WiFi connection

### Recommended
- Windows 11 (64-bit)
- 8 GB RAM
- SSD storage
- Gigabit WiFi (5GHz)

## License

This project is open source and available under the MIT License.

## Support

For issues:
1. Check this README
2. Review `PROJECT_SUMMARY.md` in parent directory
3. Check Raspberry Pi logs
4. Verify network connectivity

## Credits

Built with Flutter and VLC for professional RTP streaming from Raspberry Pi to Windows desktop.
