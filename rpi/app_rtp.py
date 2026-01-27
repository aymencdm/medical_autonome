"""
RTP Streaming Server for Raspberry Pi Face Tracker
Streams video using RTP protocol for Flutter app consumption
"""

from flask import Flask, jsonify
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import FileOutput
import subprocess
import threading
import time
import logging
import signal
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables
picam2 = None
gstreamer_process = None
streaming = False
lock = threading.Lock()

# RTP Configuration
RTP_HOST = "0.0.0.0"  # Listen on all interfaces
RTP_PORT = 5000       # RTP stream port
RTCP_PORT = 5001      # RTCP control port
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 480
VIDEO_FPS = 30
VIDEO_BITRATE = 1000000  # 1 Mbps

def init_camera():
    """Initialize the camera for H.264 encoding"""
    global picam2
    
    if picam2 is None:
        try:
            logger.info("Initializing camera...")
            picam2 = Picamera2()
            
            # Configure for H.264 video encoding
            config = picam2.create_video_configuration(
                main={"size": (VIDEO_WIDTH, VIDEO_HEIGHT), "format": "RGB888"},
                encode="main"
            )
            picam2.configure(config)
            
            logger.info(f"✓ Camera initialized ({VIDEO_WIDTH}x{VIDEO_HEIGHT} @ {VIDEO_FPS}fps)")
            
        except Exception as e:
            logger.error(f"Error initializing camera: {e}")
            import traceback
            traceback.print_exc()
            raise

def start_gstreamer_pipeline():
    """Start GStreamer pipeline for RTP streaming"""
    global gstreamer_process, streaming
    
    try:
        # GStreamer pipeline for RTP streaming
        # This creates an H.264 RTP stream that can be received by Flutter
        gst_command = [
            'gst-launch-1.0',
            '-v',
            'fdsrc', 'fd=0',
            '!', 'h264parse',
            '!', 'rtph264pay', 'config-interval=1', 'pt=96',
            '!', 'udpsink', f'host={RTP_HOST}', f'port={RTP_PORT}',
            'sync=false'
        ]
        
        logger.info(f"Starting GStreamer pipeline: {' '.join(gst_command)}")
        
        gstreamer_process = subprocess.Popen(
            gst_command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        streaming = True
        logger.info(f"✓ GStreamer pipeline started - Streaming to {RTP_HOST}:{RTP_PORT}")
        
    except Exception as e:
        logger.error(f"Error starting GStreamer: {e}")
        import traceback
        traceback.print_exc()
        raise

def start_streaming():
    """Start camera and RTP streaming"""
    global picam2, streaming
    
    try:
        init_camera()
        
        # Start camera
        picam2.start()
        logger.info("✓ Camera started")
        
        # Start GStreamer pipeline
        start_gstreamer_pipeline()
        
        # Create H.264 encoder
        encoder = H264Encoder(bitrate=VIDEO_BITRATE)
        
        # Start recording and pipe to GStreamer
        logger.info("Starting H.264 encoding and streaming...")
        picam2.start_recording(encoder, FileOutput(gstreamer_process.stdin))
        
        logger.info("✓ RTP streaming active")
        
    except Exception as e:
        logger.error(f"Error starting streaming: {e}")
        import traceback
        traceback.print_exc()
        streaming = False
        raise

def stop_streaming():
    """Stop streaming and cleanup"""
    global picam2, gstreamer_process, streaming
    
    streaming = False
    
    if picam2:
        try:
            logger.info("Stopping camera...")
            picam2.stop_recording()
            picam2.stop()
            picam2.close()
            logger.info("✓ Camera stopped")
        except Exception as e:
            logger.error(f"Error stopping camera: {e}")
    
    if gstreamer_process:
        try:
            logger.info("Stopping GStreamer...")
            gstreamer_process.terminate()
            gstreamer_process.wait(timeout=5)
            logger.info("✓ GStreamer stopped")
        except Exception as e:
            logger.error(f"Error stopping GStreamer: {e}")
            gstreamer_process.kill()

# Flask Routes

@app.route('/api/stream/info')
def stream_info():
    """Get RTP stream information"""
    return jsonify({
        'protocol': 'rtp',
        'host': RTP_HOST,
        'rtp_port': RTP_PORT,
        'rtcp_port': RTCP_PORT,
        'width': VIDEO_WIDTH,
        'height': VIDEO_HEIGHT,
        'fps': VIDEO_FPS,
        'codec': 'h264',
        'streaming': streaming,
        'sdp_url': f'http://{{server_ip}}:8080/stream.sdp'
    })

@app.route('/stream.sdp')
def get_sdp():
    """Generate SDP file for RTP stream"""
    # Get server IP (you may need to adjust this)
    import socket
    hostname = socket.gethostname()
    server_ip = socket.gethostbyname(hostname)
    
    sdp_content = f"""v=0
o=- 0 0 IN IP4 {server_ip}
s=Raspberry Pi Face Tracker Stream
c=IN IP4 {server_ip}
t=0 0
m=video {RTP_PORT} RTP/AVP 96
a=rtpmap:96 H264/90000
a=fmtp:96 packetization-mode=1
"""
    
    return sdp_content, 200, {'Content-Type': 'application/sdp'}

@app.route('/api/stream/start', methods=['POST'])
def start_stream():
    """Start RTP streaming"""
    global streaming
    
    if not streaming:
        try:
            threading.Thread(target=start_streaming, daemon=True).start()
            time.sleep(2)  # Give it time to start
            return jsonify({'status': 'started', 'streaming': streaming})
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500
    else:
        return jsonify({'status': 'already_streaming', 'streaming': streaming})

@app.route('/api/stream/stop', methods=['POST'])
def stop_stream():
    """Stop RTP streaming"""
    stop_streaming()
    return jsonify({'status': 'stopped', 'streaming': streaming})

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'streaming': streaming
    })

def signal_handler(sig, frame):
    """Handle shutdown signals"""
    logger.info("\nShutdown signal received")
    stop_streaming()
    sys.exit(0)

if __name__ == '__main__':
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        logger.info("=" * 60)
        logger.info("RTP Streaming Server for Raspberry Pi Face Tracker")
        logger.info("=" * 60)
        logger.info(f"RTP Stream will be available at: rtp://<server-ip>:{RTP_PORT}")
        logger.info(f"SDP file available at: http://<server-ip>:8080/stream.sdp")
        logger.info("=" * 60)
        
        # Auto-start streaming
        threading.Thread(target=start_streaming, daemon=True).start()
        
        # Run Flask app
        app.run(host='0.0.0.0', port=8080, debug=False, threaded=True)
        
    except KeyboardInterrupt:
        logger.info("\nInterrupted by user")
    finally:
        stop_streaming()
