# Quick Start Guide

## Raspberry Pi Setup (One-time)

1. **Install GStreamer**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
       gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
       gstreamer1.0-plugins-ugly gstreamer1.0-libav
   ```

2. **Install Python dependencies**:
   ```bash
   cd rpi
   pip install -r requirements_rtp.txt
   ```

## Running the System

### On Raspberry Pi:

```bash
cd rpi
python app_rtp.py
```

You should see:
```
============================================================
RTP Streaming Server for Raspberry Pi Face Tracker
============================================================
RTP Stream will be available at: rtp://<server-ip>:5000
SDP file available at: http://<server-ip>:8080/stream.sdp
============================================================
```

Note the IP address (e.g., 192.168.1.100)

### On Android Device:

1. Install the APK or run from Flutter:
   ```bash
   cd face_tracker_app
   flutter run
   ```

2. In the app:
   - Enter the Raspberry Pi IP address
   - Tap "Connect"
   - Tap "Start Stream"
   - Enjoy the live video feed!

## Network Requirements

- Both devices must be on the same WiFi network
- Firewall must allow ports: 5000, 5001, 8080

## Differences from HTTP Streaming

### Old (HTTP/MJPEG):
- Protocol: HTTP
- Format: MJPEG (Motion JPEG)
- Port: 5000
- Latency: Higher (~500ms)
- Bandwidth: Higher

### New (RTP):
- Protocol: RTP (Real-time Transport Protocol)
- Format: H.264 (compressed)
- Ports: 5000 (RTP), 5001 (RTCP), 8080 (API)
- Latency: Lower (~100-200ms)
- Bandwidth: Lower (better compression)
- Quality: Better

## Troubleshooting

**Can't connect?**
- Ping the Raspberry Pi: `ping <ip-address>`
- Check if server is running: `curl http://<ip>:8080/health`

**No video?**
- Wait 5-10 seconds for stream to initialize
- Check GStreamer is installed on Pi
- Restart the app

**Laggy video?**
- Move closer to WiFi router
- Reduce other network traffic
- Lower bitrate in app_rtp.py
