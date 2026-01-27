# 📋 Quick Reference Card

## 🚀 Start the System

### Raspberry Pi
```bash
cd ~/ppp/rpi
python app_rtp.py
```
**Note the IP address shown!** (e.g., 192.168.1.100)

### Windows Desktop
```bash
cd face_tracker_viewer
flutter run -d windows
```
Or double-click `run.bat`

---

## 🔌 Connect

1. Enter Pi IP address in app
2. Click "Connect"
3. Click "Start Stream"
4. Watch the video!

---

## 🛠️ Common Commands

### Raspberry Pi

```bash
# Test setup
python test_setup.py

# Check IP address
hostname -I

# Test camera
libcamera-hello

# Check GStreamer
gst-launch-1.0 --version

# View running processes
ps aux | grep python
```

### Windows

```bash
# Check Flutter
flutter doctor

# Clean build
flutter clean
flutter pub get

# Build release
flutter build windows --release

# View logs
flutter logs
```

---

## 🌐 Network

### Ports
- **5000** - RTP video stream
- **5001** - RTCP control  
- **8080** - HTTP API

### Test Connection
```bash
# Ping Pi
ping 192.168.1.100

# Test API
curl http://192.168.1.100:8080/health
```

---

## ⚙️ Video Settings

**Edit `rpi/app_rtp.py`:**

```python
# Low quality (fast)
VIDEO_WIDTH = 320
VIDEO_HEIGHT = 240
VIDEO_BITRATE = 500000

# Medium (default)
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 480
VIDEO_BITRATE = 1000000

# High quality (slow)
VIDEO_WIDTH = 1280
VIDEO_HEIGHT = 720
VIDEO_BITRATE = 2000000
```

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't connect | Check IP, verify same WiFi |
| No video | Wait 10s, restart stream |
| Laggy | Lower bitrate, use 5GHz WiFi |
| Build error | `flutter clean && flutter pub get` |
| Port in use | Kill process: `sudo lsof -i :5000` |

---

## 📁 Important Files

```
ppp/
├── rpi/
│   ├── app_rtp.py          ⭐ RTP server
│   ├── test_setup.py       🔧 Test script
│   └── requirements_rtp.txt 📦 Dependencies
│
└── face_tracker_viewer/
    ├── run.bat             ▶️ Quick start
    ├── lib/main.dart       🎨 App entry
    └── README.md           📖 Documentation
```

---

## 📚 Documentation

- **SETUP_GUIDE.md** - Complete setup instructions
- **PROJECT_SUMMARY.md** - Full project overview
- **QUICKSTART.md** - Quick start guide
- **face_tracker_viewer/README.md** - App details

---

## ✅ Success Checklist

- [ ] GStreamer installed on Pi
- [ ] Python packages installed
- [ ] Flutter installed on Windows
- [ ] Both on same WiFi
- [ ] Pi server running
- [ ] Desktop app running
- [ ] Connected successfully
- [ ] Video streaming

---

## 🎯 Key Features

✨ **Low latency** (~100-200ms)  
✨ **H.264 compression** (better quality)  
✨ **Desktop app** (large screen)  
✨ **Real-time monitoring**  
✨ **Professional UI**  

---

## 📞 Need Help?

1. Run `python test_setup.py` on Pi
2. Check `flutter doctor` on Windows
3. Review SETUP_GUIDE.md
4. Check logs on both devices

---

**Made with Flutter & RTP** 🚀
