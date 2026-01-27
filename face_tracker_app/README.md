# Face Tracker RTP Stream - Flutter App

A Flutter mobile application that receives and displays RTP video streams from a Raspberry Pi face tracking system.

## Features

- 🎥 Real-time RTP video streaming
- 📱 Beautiful dark-themed UI
- 🔌 Easy connection management
- 📊 Stream information display
- ⚡ Low-latency video playback using VLC

## Prerequisites

### Raspberry Pi Setup

1. **Install GStreamer** (required for RTP streaming):
   ```bash
   sudo apt-get update
   sudo apt-get install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
       gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
       gstreamer1.0-plugins-ugly gstreamer1.0-libav
   ```

2. **Install Python dependencies**:
   ```bash
   cd rpi
   pip install flask picamera2
   ```

3. **Run the RTP streaming server**:
   ```bash
   python app_rtp.py
   ```

   The server will:
   - Start streaming H.264 video over RTP on port 5000
   - Provide an HTTP API on port 8080
   - Generate an SDP file for stream configuration

### Flutter App Setup

1. **Install Flutter dependencies**:
   ```bash
   cd face_tracker_app
   flutter pub get
   ```

2. **For Android**: Make sure you have Android SDK installed and configured

3. **Build and run**:
   ```bash
   # For Android
   flutter run

   # Or build APK
   flutter build apk --release
   ```

## Usage

1. **Start the Raspberry Pi server**:
   - Run `python app_rtp.py` on your Raspberry Pi
   - Note the IP address shown in the logs

2. **Connect from the Flutter app**:
   - Open the app on your Android device
   - Enter the Raspberry Pi IP address (e.g., `192.168.1.100`)
   - Tap "Connect"

3. **Start streaming**:
   - Once connected, tap "Start Stream"
   - The video feed will appear in the player

## Network Configuration

- **RTP Port**: 5000 (video stream)
- **RTCP Port**: 5001 (control)
- **HTTP API Port**: 8080 (control interface)

Make sure your Raspberry Pi and Android device are on the same network.

## Architecture

### Raspberry Pi (Server)
- **Flask**: HTTP API server
- **Picamera2**: Camera interface
- **H.264 Encoder**: Video compression
- **GStreamer**: RTP streaming pipeline

### Flutter App (Client)
- **VLC Player**: RTP stream playback
- **Provider**: State management
- **HTTP**: Server communication

## API Endpoints

The Raspberry Pi server provides these endpoints:

- `GET /health` - Health check
- `GET /api/stream/info` - Get stream information
- `GET /stream.sdp` - Get SDP file for stream
- `POST /api/stream/start` - Start streaming
- `POST /api/stream/stop` - Stop streaming

## Troubleshooting

### No video appears
- Check that both devices are on the same network
- Verify the IP address is correct
- Ensure GStreamer is installed on the Raspberry Pi
- Check firewall settings (ports 5000, 5001, 8080)

### Stream is laggy
- Reduce network traffic on your WiFi
- Move devices closer to the router
- Adjust bitrate in `app_rtp.py` (VIDEO_BITRATE)

### Connection fails
- Verify the Raspberry Pi server is running
- Check the IP address
- Ensure no firewall is blocking the connection

## Customization

### Change video quality
Edit `app_rtp.py`:
```python
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 480
VIDEO_FPS = 30
VIDEO_BITRATE = 1000000  # 1 Mbps
```

### Change ports
Edit `app_rtp.py`:
```python
RTP_PORT = 5000
RTCP_PORT = 5001
```

## License

This project is open source and available under the MIT License.

## Credits

Built with Flutter and VLC for seamless RTP streaming from Raspberry Pi.
