"""
Main Server for RPi Streamer
============================
Refactored to use ControlManager for logic separation.
Includes Face Recognition capabilities.
"""
import logging
from flask import Flask
from flask_socketio import SocketIO, emit
from picamera2 import Picamera2
import cv2

from config import CONFIG
from normal_stream import NormalStreamer
from control_manager import ControlManager
from face_manager import FaceManager

# =============================================================================
# LOGGING
# =============================================================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# =============================================================================
# FLASK & SOCKET.IO
# =============================================================================
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# =============================================================================
# GLOBALS & MANAGERS
# =============================================================================
# Initialize Managers
control_manager = ControlManager(socketio)
normal_streamer = NormalStreamer(CONFIG)
face_manager = FaceManager()
picam2 = None

# =============================================================================
# BACKGROUND TASKS
# =============================================================================
def camera_loop():
    """
    Background task: Camera capture and processing.
    """
    global picam2
    
    try:
        # Camera init
        picam2 = Picamera2()
        cfg = picam2.create_video_configuration(
            main={"size": (1640, 1232), "format": "BGR888"},
            controls={"FrameRate": CONFIG["VIDEO"]["FPS"]}
        )
        picam2.configure(cfg)
        picam2.start()
        logger.info("Camera started")
        
        while control_manager.state["running"]:
            frame = picam2.capture_array()
            
            # Process Frame based on Mode
            if control_manager.state["mode"] == "recognition":
                processed = face_manager.recognize_faces(frame)
            else:
                processed = normal_streamer.process_frame(frame)
            
            # Broadcast Frame
            if control_manager.state["streaming"]:
                _, buf = cv2.imencode('.jpg', processed, [
                    cv2.IMWRITE_JPEG_QUALITY,
                    CONFIG["VIDEO"]["JPEG_QUALITY"]
                ])
                socketio.emit(
                    'video_frame',
                    buf.tobytes(),
                    namespace=CONFIG["NETWORK"]["NAMESPACE"]
                )
            
            socketio.sleep(0.01)
    
    except Exception as e:
        logger.error(f"Camera error: {e}")
    finally:
        if picam2:
            picam2.stop()
        control_manager.cleanup()
        logger.info("Camera stopped, cleanup done")

# =============================================================================
# SOCKET.IO HANDLERS
# =============================================================================
NS = CONFIG["NETWORK"]["NAMESPACE"]

@socketio.on('connect', namespace=NS)
def handle_connect():
    control_manager.set_streaming(True)
    logger.info(f"Client connected | Mode: {control_manager.state['mode']}")
    emit('status', control_manager.state)

@socketio.on('disconnect', namespace=NS)
def handle_disconnect():
    control_manager.set_streaming(False) # Optional: Pause streaming on disconnect?
    logger.info("Client disconnected")

@socketio.on('set_mode', namespace=NS)
def handle_set_mode(data):
    new_mode = data.get("mode", "normal")
    if control_manager.set_mode(new_mode):
        emit('mode_changed', {
            "mode": new_mode,
            "servos_active": control_manager.state["servos_active"]
        }, broadcast=True)

@socketio.on('manual_move', namespace=NS)
def handle_manual_move(data):
    control_manager.update_manual_position(
        pan=data.get('pan'),
        tilt=data.get('tilt')
    )

@socketio.on('center', namespace=NS)
def handle_center():
    control_manager.center_servos()

@socketio.on('get_status', namespace=NS)
def handle_get_status():
    emit('status', control_manager.state)

# --- Person Management ---
@socketio.on('create_person', namespace=NS)
def handle_create_person(data):
    name = data.get('name')
    if name and face_manager.create_person(name):
        emit('person_created', {'name': name, 'success': True})
    else:
        emit('person_created', {'name': name, 'success': False})

@socketio.on('capture_image', namespace=NS)
def handle_capture_image(data):
    name = data.get('name')
    image_data = data.get('image') # Expecting raw bytes or similar
    
    if name and image_data:
        success = face_manager.save_training_image(name, image_data)
        emit('image_captured', {'success': success})

@socketio.on('train_model', namespace=NS)
def handle_train_model():
    logger.info("Training requested...")
    success = face_manager.train_model()
    emit('training_complete', {'success': success})

@socketio.on('get_persons', namespace=NS)
def handle_get_persons():
    persons = face_manager.get_persons()
    emit('persons_list', {'persons': persons})

# =============================================================================
# MAIN
# =============================================================================
if __name__ == '__main__':
    logger.info("=" * 50)
    logger.info("RPi Streamer (Refactored) - Starting")
    logger.info("=" * 50)
    logger.info(f"  Port: {CONFIG['NETWORK']['PORT']}")
    logger.info("=" * 50)
    
    # Start Background Tasks
    socketio.start_background_task(control_manager.servo_loop)
    socketio.start_background_task(camera_loop)
    
    # Run Server
    socketio.run(
        app,
        host='0.0.0.0',
        port=CONFIG["NETWORK"]["PORT"],
        debug=False
    )
