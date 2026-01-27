# 🚀 Complete Setup Guide - Face Tracker RTP Desktop Viewer

## 📋 What You're Building

A **Windows desktop application** that receives live video from your Raspberry Pi face tracker using **RTP protocol** (not HTTP, not mobile app).

## 🎯 System Overview

```
Raspberry Pi (Camera) ──RTP Stream──> Windows PC (Desktop Viewer)
     (Server)          via WiFi              (Client)
```

---

## Part 1: Raspberry Pi Setup

### 1.1 Install GStreamer (Required for RTP)

```bash
sudo apt-get update
sudo apt-get install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav
```

**Verify installation:**
```bash
gst-launch-1.0 --version
```

### 1.2 Install Python Dependencies

```bash
cd ~/ppp/rpi
pip install -r requirements_rtp.txt
```

This installs:
- Flask (web server)
- Picamera2 (camera interface)

### 1.3 Test Your Setup

```bash
python test_setup.py
```

This checks:
- ✓ Python packages installed
- ✓ GStreamer available
- ✓ Network configuration
- ✓ Ports available

**Expected output:**
```
============================================================
  RTP Streaming Setup Verification
============================================================
✓ PASS: Python Packages
✓ PASS: GStreamer
✓ PASS: Network
✓ PASS: Ports

All checks passed! You're ready to run the RTP server.
```

### 1.4 Start the RTP Server

```bash
python app_rtp.py
```

**You should see:**
```
============================================================
RTP Streaming Server for Raspberry Pi Face Tracker
============================================================
RTP Stream will be available at: rtp://<server-ip>:5000
SDP file available at: http://<server-ip>:8080/stream.sdp
============================================================
✓ Camera initialized (640x480 @ 30fps)
✓ GStreamer pipeline started - Streaming to 0.0.0.0:5000
✓ RTP streaming active
```

**📝 Note the IP address** (e.g., `192.168.1.100`) - you'll need it for the desktop app!

---

## Part 2: Windows Desktop App Setup

### 2.1 Prerequisites

**Install Flutter:**
1. Download from: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add to PATH: `C:\flutter\bin`
4. Verify: `flutter doctor`

**Install Visual Studio 2022:**
- Download Community Edition
- Select "Desktop development with C++"
- Install

### 2.2 Install Dependencies

```bash
cd C:\Users\aymen\Desktop\ppp\face_tracker_viewer
flutter pub get
```

**Expected output:**
```
Resolving dependencies...
+ dart_vlc 0.4.0
+ window_manager 0.3.9
+ provider 6.1.5+1
+ http 1.6.0
Changed 14 dependencies!
```

### 2.3 Run the Desktop App

**Option A: Using Command Line**
```bash
flutter run -d windows
```

**Option B: Using Batch File**
```bash
run.bat
```

**The app window will open** with a dark-themed interface.

---

## Part 3: Connect and Stream

### 3.1 In the Desktop App

1. **Enter IP Address**
   - Type the Raspberry Pi IP (e.g., `192.168.1.100`)
   - Click "Connect"
   
2. **Wait for Connection**
   - You'll see "✓ Connected to Raspberry Pi"
   - The connection card will turn green

3. **Start Streaming**
   - Click "Start Stream" (green button)
   - Wait 5-10 seconds for initialization
   - Video will appear in the main area

4. **Watch the Stream**
   - You should see live video from the Pi camera
   - "LIVE" badge appears in top-right
   - Stream info shows at bottom-left

### 3.2 Troubleshooting Connection

**Can't connect?**
```bash
# On Windows, ping the Pi
ping 192.168.1.100

# Check if server is running
curl http://192.168.1.100:8080/health
```

**No video?**
- Wait 10 seconds (stream initialization takes time)
- Check Pi terminal for errors
- Restart the stream (Stop → Start)
- Verify GStreamer is running on Pi

---

## Part 4: Network Configuration

### 4.1 Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 5000 | RTP/UDP | Video stream |
| 5001 | RTCP/UDP | Stream control |
| 8080 | HTTP/TCP | API control |

### 4.2 Firewall Configuration

**On Raspberry Pi:**
```bash
# Allow ports (if firewall enabled)
sudo ufw allow 5000/udp
sudo ufw allow 5001/udp
sudo ufw allow 8080/tcp
```

**On Windows:**
- Windows Defender should allow automatically
- If blocked, add exception for ports 5000, 5001, 8080

### 4.3 Network Requirements

- ✅ Both devices on **same WiFi network**
- ✅ WiFi speed: **5 Mbps or higher**
- ✅ Recommended: **5GHz WiFi** for better performance
- ✅ Router must allow **local network communication**

---

## Part 5: Customization

### 5.1 Adjust Video Quality

**Edit `rpi/app_rtp.py`:**
```python
# Lower quality (faster, less bandwidth)
VIDEO_WIDTH = 320
VIDEO_HEIGHT = 240
VIDEO_BITRATE = 500000  # 500 Kbps

# Higher quality (slower, more bandwidth)
VIDEO_WIDTH = 1280
VIDEO_HEIGHT = 720
VIDEO_BITRATE = 2000000  # 2 Mbps
```

### 5.2 Change Window Size

**Edit `face_tracker_viewer/lib/main.dart`:**
```dart
WindowOptions windowOptions = const WindowOptions(
  size: Size(1600, 900),        // Larger window
  minimumSize: Size(1024, 768), // Minimum size
  // ...
);
```

### 5.3 Customize Theme

**Edit `face_tracker_viewer/lib/main.dart`:**
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF00FF00),  // Green theme
  // or
  seedColor: const Color(0xFFFF5722),  // Orange theme
  brightness: Brightness.dark,
),
```

---

## Part 6: Building for Distribution

### 6.1 Build Release Version

```bash
cd face_tracker_viewer
flutter build windows --release
```

**Output location:**
```
build\windows\x64\runner\Release\face_tracker_viewer.exe
```

### 6.2 Create Portable Package

1. Copy the entire `Release` folder
2. Rename to `FaceTrackerViewer`
3. Zip it for distribution
4. Users can run `face_tracker_viewer.exe` directly

### 6.3 Create Installer (Optional)

**Using Inno Setup:**
1. Download Inno Setup: https://jrsoftware.org/isinfo.php
2. Create installer script
3. Build installer package

---

## Part 7: Daily Usage

### 7.1 Starting the System

**On Raspberry Pi:**
```bash
cd ~/ppp/rpi
python app_rtp.py
```

**On Windows:**
```bash
cd face_tracker_viewer
flutter run -d windows
# or double-click run.bat
```

### 7.2 Stopping the System

**Desktop App:**
- Click "Stop Stream"
- Close the window

**Raspberry Pi:**
- Press `Ctrl+C` in terminal
- Server will clean up automatically

---

## Part 8: Common Issues & Solutions

### Issue 1: "GStreamer not found"

**Solution:**
```bash
# On Raspberry Pi
sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-*
```

### Issue 2: "Connection refused"

**Possible causes:**
- Pi server not running → Start `app_rtp.py`
- Wrong IP address → Check with `hostname -I` on Pi
- Firewall blocking → Check firewall settings
- Different networks → Ensure same WiFi

### Issue 3: "No video appears"

**Solutions:**
1. Wait 10-15 seconds (initialization time)
2. Check Pi terminal for errors
3. Restart stream (Stop → Start)
4. Verify camera works: `libcamera-hello` on Pi

### Issue 4: "Laggy video"

**Solutions:**
1. Move closer to WiFi router
2. Use 5GHz WiFi instead of 2.4GHz
3. Lower bitrate in `app_rtp.py`:
   ```python
   VIDEO_BITRATE = 500000  # 500 Kbps
   ```
4. Reduce resolution:
   ```python
   VIDEO_WIDTH = 320
   VIDEO_HEIGHT = 240
   ```

### Issue 5: "Flutter build errors"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run -d windows
```

---

## Part 9: Testing Checklist

Before reporting issues, verify:

- [ ] GStreamer installed on Pi (`gst-launch-1.0 --version`)
- [ ] Python packages installed (`pip list | grep flask`)
- [ ] Camera works (`libcamera-hello`)
- [ ] Server running (`python app_rtp.py`)
- [ ] Correct IP address (check Pi terminal output)
- [ ] Same WiFi network (ping test)
- [ ] Firewall allows ports 5000, 5001, 8080
- [ ] Flutter installed (`flutter doctor`)
- [ ] Desktop app dependencies installed (`flutter pub get`)

---

## Part 10: Performance Tips

### For Best Performance:

1. **Network:**
   - Use 5GHz WiFi
   - Keep devices close to router
   - Minimize other network traffic

2. **Raspberry Pi:**
   - Use Pi 4 or newer
   - Ensure adequate cooling
   - Use quality power supply

3. **Windows PC:**
   - Close unnecessary applications
   - Use wired connection if possible
   - Ensure good WiFi signal

4. **Video Settings:**
   - Start with default (640x480, 1Mbps)
   - Adjust based on network speed
   - Lower quality if experiencing lag

---

## 📞 Getting Help

1. **Check logs:**
   - Pi: Terminal output from `app_rtp.py`
   - Desktop: Flutter console output

2. **Test connectivity:**
   ```bash
   ping <pi-ip>
   curl http://<pi-ip>:8080/health
   ```

3. **Verify setup:**
   ```bash
   # On Pi
   python test_setup.py
   ```

4. **Review documentation:**
   - `PROJECT_SUMMARY.md` - Complete overview
   - `face_tracker_viewer/README.md` - App details
   - `QUICKSTART.md` - Quick reference

---

## ✅ Success Indicators

You know it's working when:

- ✓ Pi shows "✓ RTP streaming active"
- ✓ Desktop app shows "Connected" (green)
- ✓ "LIVE" badge appears on video
- ✓ You see smooth video feed
- ✓ Stream info shows "Status: Streaming"

---

## 🎉 You're Done!

You now have a professional desktop application for viewing your Raspberry Pi face tracker stream using RTP protocol!

**Enjoy your low-latency, high-quality video streaming! 🚀**
