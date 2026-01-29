"""
Main Server for rpi_pro Face Tracker
Architecture: Cleaned, Ported Logic from @FaceTracking project
"""
import cv2
import time
import logging
import threading
from flask import Flask
from flask_socketio import SocketIO, emit
from picamera2 import Picamera2

from config import CONFIG
from servos import ServoController
from tracker import FaceTrackerPro

# --- Logging ---
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# --- App ---
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# --- Globals ---
servos = ServoController()
tracker = FaceTrackerPro()
picam2 = None

state = {
    "running": True,
    "streaming": False,
    "auto_tracking": True,
    "pan": CONFIG["SERVOS"]["CENTER_PAN"],
    "tilt": CONFIG["SERVOS"]["CENTER_TILT"]
}

def tracking_loop():
    """Background task for smooth servo movement"""
    last_pan = -1
    last_tilt = -1
    
    while state["running"]:
        curr_pan = state["pan"]
        curr_tilt = state["tilt"]
        
        # Only send command if angle has changed
        # This prevents "PWM jitter" when the face is Centered (Dead Zone)
        if abs(curr_pan - last_pan) > 0.01 or abs(curr_tilt - last_tilt) > 0.01:
            servos.move(curr_pan, curr_tilt)
            last_pan = curr_pan
            last_tilt = curr_tilt
        
        socketio.sleep(0.02) # 50Hz update rate

def camera_loop():
    """Capture, Analysis, and Stream Broadcast"""
    global picam2
    try:
        picam2 = Picamera2()
        # Fix: Capture at 1640x1232 (2x2 binning) to get FULL Field of View (no crop)
        # Then resize down to 640x480 for processing/streaming.
        cfg = picam2.create_video_configuration(
            main={"size": (1640, 1232), "format": "BGR888"},
            controls={"FrameRate": CONFIG["VIDEO"]["FPS"]}
        )
        picam2.configure(cfg)
        picam2.start()
        logger.info("Camera online.")

        while state["running"]:
            frame = picam2.capture_array()
            
            # "Digital Zoom" Logic (1.3x)
            # Capture is 1640x1232. We want to crop the center to make it look "closer" 
            # but not "too close" like the original mode.
            h, w = frame.shape[:2]
            zoom_factor = 1.3
            new_h, new_w = int(h / zoom_factor), int(w / zoom_factor)
            y_start = (h - new_h) // 2
            x_start = (w - new_w) // 2
            
            frame = frame[y_start:y_start+new_h, x_start:x_start+new_w]
            
            # Resize to standard streaming size
            frame = cv2.resize(frame, (CONFIG["VIDEO"]["WIDTH"], CONFIG["VIDEO"]["HEIGHT"]))
            
            if CONFIG["VIDEO"]["FLIP"]:
                frame = cv2.flip(frame, -1)
            
            # Update target angles
            if state["auto_tracking"]:
                nt_pan, nt_tilt = tracker.process_frame(frame, state["pan"], state["tilt"])
                state["pan"], state["tilt"] = nt_pan, nt_tilt
            
            # Broadcast frame if streaming
            if state["streaming"]:
                _, buf = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, CONFIG["VIDEO"]["JPEG_QUALITY"]])
                socketio.emit('video_frame', buf.tobytes(), namespace=CONFIG["NETWORK"]["NAMESPACE"])
            
            socketio.sleep(0.01)

    except Exception as e:
        logger.error(f"Camera Crash: {e}")
    finally:
        if picam2: picam2.stop()
        servos.cleanup()

# --- Socket Handlers ---
NS = CONFIG["NETWORK"]["NAMESPACE"]

@socketio.on('connect', namespace=NS)
def on_connect():
    state["streaming"] = True
    logger.info("Client connected.")
    emit('status', {"pan": state["pan"], "tilt": state["tilt"], "tracking": state["auto_tracking"]})

@socketio.on('toggle_tracking', namespace=NS)
def on_toggle(data):
    state["auto_tracking"] = data.get("enabled", not state["auto_tracking"])
    logger.info(f"Auto-tracking: {state['auto_tracking']}")

@socketio.on('manual_move', namespace=NS)
def on_manual(data):
    state["auto_tracking"] = False
    if 'pan' in data: state["pan"] = data['pan']
    if 'tilt' in data: state["tilt"] = data['tilt']

@socketio.on('center', namespace=NS)
def on_center():
    state["pan"] = CONFIG["SERVOS"]["CENTER_PAN"]
    state["tilt"] = CONFIG["SERVOS"]["CENTER_TILT"]

if __name__ == '__main__':
    socketio.start_background_task(tracking_loop)
    socketio.start_background_task(camera_loop)
    logger.info(f"rpi_pro server starting on port {CONFIG['NETWORK']['PORT']}...")
    socketio.run(app, host='0.0.0.0', port=CONFIG["NETWORK"]["PORT"], debug=False)
