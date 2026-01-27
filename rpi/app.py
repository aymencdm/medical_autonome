from flask import Flask, render_template, Response
from picamera2 import Picamera2
from picamera2.encoders import MJPEGEncoder
from picamera2.outputs import FileOutput
import io
import threading
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global camera instance
picam2 = None
output = None
lock = threading.Lock()

class StreamingOutput(io.BufferedIOBase):
    def __init__(self):
        self.frame = None

    def write(self, buf):
        self.frame = buf
        return len(buf)

def init_camera():
    """Initialize the camera"""
    global picam2, output
    
    if picam2 is None:
        try:
            logger.info("Initializing camera...")
            picam2 = Picamera2()
            output = StreamingOutput()
            
            # Configure camera for MJPEG streaming
            logger.info("Configuring camera...")
            # Use simple configuration without specific format
            config = picam2.create_preview_configuration()
            config["main"]["size"] = (640, 480)
            picam2.configure(config)
            
            logger.info("Starting recording...")
            picam2.start_recording(MJPEGEncoder(), FileOutput(output))
            picam2.start()
            logger.info("✓ Camera initialized and recording")
        except Exception as e:
            logger.error(f"Error initializing camera: {e}")
            import traceback
            traceback.print_exc()
            picam2 = None
            raise

def generate_frames():
    """Generate frames from the camera"""
    try:
        init_camera()
        
        frame_count = 0
        while True:
            if output and output.frame:
                frame = output.frame
                frame_count += 1
                if frame_count % 30 == 0:
                    logger.info(f"Streaming frame {frame_count}")
                
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n'
                       b'Content-Length: ' + str(len(frame)).encode() + b'\r\n\r\n'
                       + frame + b'\r\n')
            
            time.sleep(0.01)
    except Exception as e:
        logger.error(f"Error in generate_frames: {e}")
        raise

@app.route('/')
def index():
    """Video streaming home page"""
    logger.info("Index page requested")
    return render_template('index.html')

@app.route('/video_feed')
def video_feed():
    """Video streaming route"""
    logger.info("Video feed requested")
    try:
        return Response(generate_frames(),
                        mimetype='multipart/x-mixed-replace; boundary=frame')
    except Exception as e:
        logger.error(f"Error in video_feed: {e}")
        return f"Error: {e}", 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'ok'}, 200

def cleanup():
    """Cleanup camera resources"""
    global picam2
    if picam2:
        try:
            logger.info("Stopping camera...")
            picam2.stop()
            picam2.close()
            logger.info("✓ Camera stopped cleanly")
        except Exception as e:
            logger.error(f"Error stopping camera: {e}")

if __name__ == '__main__':
    try:
        # Run the Flask app
        # Use 0.0.0.0 to access from other machines on the network
        logger.info("Starting Flask app on 0.0.0.0:5000")
        app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    finally:
        cleanup()
