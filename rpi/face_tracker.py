"""
Face Tracking System for Raspberry Pi
Uses Picamera2 for camera capture, OpenCV for face detection,
and GPIO PWM for servo control (pan-tilt mechanism).
"""

from flask import Flask, render_template, Response, jsonify, request
from picamera2 import Picamera2
import cv2
import numpy as np
import threading
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to import GPIO - will only work on Raspberry Pi
try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
    logger.info("✓ GPIO available - Running on Raspberry Pi")
except ImportError:
    GPIO_AVAILABLE = False
    logger.warning("⚠ GPIO not available - Servo control disabled (simulation mode)")

app = Flask(__name__)

# ==================== CONFIGURATION ====================

# Camera settings
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480
CAMERA_FPS = 30

# Servo GPIO pins (BCM numbering)
PAN_SERVO_PIN = 17   # Horizontal servo (left-right)
TILT_SERVO_PIN = 27  # Vertical servo (up-down)

# Servo angle limits (in degrees)
PAN_MIN_ANGLE = 0
PAN_MAX_ANGLE = 180
PAN_CENTER_ANGLE = 90

TILT_MIN_ANGLE = 30   # Limit to prevent camera looking too far down
TILT_MAX_ANGLE = 150  # Limit to prevent camera looking too far up
TILT_CENTER_ANGLE = 90

# PWM frequency for servos (standard is 50Hz)
SERVO_PWM_FREQ = 50

# PID controller gains for smooth tracking
PAN_KP = 0.05   # Proportional gain for pan
PAN_KI = 0.001  # Integral gain for pan
PAN_KD = 0.02   # Derivative gain for pan

TILT_KP = 0.05  # Proportional gain for tilt
TILT_KI = 0.001 # Integral gain for tilt
TILT_KD = 0.02  # Derivative gain for tilt

# Dead zone - don't move if face is close to center (in pixels)
DEAD_ZONE_X = 30
DEAD_ZONE_Y = 30

# Smoothing factor for servo movement (0.0 = no smoothing, 1.0 = max smoothing)
SMOOTHING_FACTOR = 0.3

# ==================== GLOBAL VARIABLES ====================

# Camera
picam2 = None
camera_lock = threading.Lock()

# Servos
pan_servo = None
tilt_servo = None

# Current servo angles
current_pan_angle = PAN_CENTER_ANGLE
current_tilt_angle = TILT_CENTER_ANGLE

# Target servo angles
target_pan_angle = PAN_CENTER_ANGLE
target_tilt_angle = TILT_CENTER_ANGLE

# Face detection
face_cascade = None
last_face_location = None
face_detected = False

# PID state
pan_error_sum = 0
pan_last_error = 0
tilt_error_sum = 0
tilt_last_error = 0

# Tracking state
tracking_enabled = True
show_debug_overlay = True

# Thread management
frame_lock = threading.Lock()
current_frame = None
running = True

# ==================== HELPER FUNCTIONS ====================

def angle_to_duty_cycle(angle):
    """
    Convert servo angle (0-180) to PWM duty cycle (2.5-12.5%)
    Standard servo: 1ms pulse = 0°, 2ms pulse = 180°
    At 50Hz: 20ms period
    """
    # Map 0-180 degrees to 2.5-12.5 duty cycle
    return 2.5 + (angle / 180.0) * 10.0


def clamp(value, min_val, max_val):
    """Clamp a value between min and max"""
    return max(min_val, min(max_val, value))


def smooth_angle(current, target, factor):
    """Apply exponential smoothing to angle transition"""
    return current + (target - current) * (1 - factor)


# ==================== SERVO CONTROL ====================

def init_servos():
    """Initialize GPIO and servo PWM"""
    global pan_servo, tilt_servo, current_pan_angle, current_tilt_angle
    
    if not GPIO_AVAILABLE:
        logger.info("Servo simulation mode - no actual servo control")
        return
    
    try:
        # Set GPIO mode
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)
        
        # Setup servo pins
        GPIO.setup(PAN_SERVO_PIN, GPIO.OUT)
        GPIO.setup(TILT_SERVO_PIN, GPIO.OUT)
        
        # Initialize PWM
        pan_servo = GPIO.PWM(PAN_SERVO_PIN, SERVO_PWM_FREQ)
        tilt_servo = GPIO.PWM(TILT_SERVO_PIN, SERVO_PWM_FREQ)
        
        # Start servos at center position
        pan_servo.start(angle_to_duty_cycle(PAN_CENTER_ANGLE))
        tilt_servo.start(angle_to_duty_cycle(TILT_CENTER_ANGLE))
        
        current_pan_angle = PAN_CENTER_ANGLE
        current_tilt_angle = TILT_CENTER_ANGLE
        
        logger.info(f"✓ Servos initialized (Pan: GPIO{PAN_SERVO_PIN}, Tilt: GPIO{TILT_SERVO_PIN})")
        
    except Exception as e:
        logger.error(f"Error initializing servos: {e}")
        raise


def move_servo(pan_angle, tilt_angle):
    """Move servos to specified angles"""
    global current_pan_angle, current_tilt_angle
    
    # Clamp angles to valid range
    pan_angle = clamp(pan_angle, PAN_MIN_ANGLE, PAN_MAX_ANGLE)
    tilt_angle = clamp(tilt_angle, TILT_MIN_ANGLE, TILT_MAX_ANGLE)
    
    current_pan_angle = pan_angle
    current_tilt_angle = tilt_angle
    
    if GPIO_AVAILABLE and pan_servo and tilt_servo:
        pan_servo.ChangeDutyCycle(angle_to_duty_cycle(pan_angle))
        tilt_servo.ChangeDutyCycle(angle_to_duty_cycle(tilt_angle))


def center_servos():
    """Move servos to center position"""
    global target_pan_angle, target_tilt_angle
    target_pan_angle = PAN_CENTER_ANGLE
    target_tilt_angle = TILT_CENTER_ANGLE
    move_servo(PAN_CENTER_ANGLE, TILT_CENTER_ANGLE)
    logger.info("Servos centered")


def cleanup_servos():
    """Cleanup GPIO resources"""
    if GPIO_AVAILABLE:
        try:
            if pan_servo:
                pan_servo.stop()
            if tilt_servo:
                tilt_servo.stop()
            GPIO.cleanup()
            logger.info("✓ GPIO cleaned up")
        except Exception as e:
            logger.error(f"Error cleaning up GPIO: {e}")


# ==================== FACE DETECTION ====================

def init_face_detector():
    """Initialize OpenCV face cascade classifier"""
    global face_cascade
    
    # Try to load the face cascade
    cascade_paths = [
        cv2.data.haarcascades + 'haarcascade_frontalface_default.xml',
        '/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml',
        '/usr/share/opencv/haarcascades/haarcascade_frontalface_default.xml',
    ]
    
    for path in cascade_paths:
        try:
            face_cascade = cv2.CascadeClassifier(path)
            if not face_cascade.empty():
                logger.info(f"✓ Face cascade loaded from: {path}")
                return
        except:
            continue
    
    raise RuntimeError("Could not load face cascade classifier")


def detect_faces(frame):
    """Detect faces in a frame and return largest face"""
    global face_detected, last_face_location
    
    # Convert to grayscale for detection
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # Detect faces
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30),
        flags=cv2.CASCADE_SCALE_IMAGE
    )
    
    if len(faces) > 0:
        # Find the largest face
        largest_face = max(faces, key=lambda f: f[2] * f[3])
        x, y, w, h = largest_face
        
        # Calculate center of face
        face_center_x = x + w // 2
        face_center_y = y + h // 2
        
        face_detected = True
        last_face_location = (face_center_x, face_center_y, w, h)
        
        return faces, (face_center_x, face_center_y)
    else:
        face_detected = False
        return [], None


# ==================== TRACKING LOGIC ====================

def calculate_servo_adjustment(face_center):
    """
    Calculate servo angle adjustments using PID controller
    to center the face in the frame
    """
    global pan_error_sum, pan_last_error
    global tilt_error_sum, tilt_last_error
    global target_pan_angle, target_tilt_angle
    
    if face_center is None:
        return
    
    face_x, face_y = face_center
    
    # Calculate error (difference from frame center)
    frame_center_x = CAMERA_WIDTH // 2
    frame_center_y = CAMERA_HEIGHT // 2
    
    error_x = frame_center_x - face_x  # Positive = face is left, need to pan right
    error_y = frame_center_y - face_y  # Positive = face is up, need to tilt up
    
    # Apply dead zone
    if abs(error_x) < DEAD_ZONE_X:
        error_x = 0
    if abs(error_y) < DEAD_ZONE_Y:
        error_y = 0
    
    # PID for pan (horizontal)
    pan_error_sum += error_x
    pan_error_sum = clamp(pan_error_sum, -1000, 1000)  # Anti-windup
    pan_derivative = error_x - pan_last_error
    pan_adjustment = PAN_KP * error_x + PAN_KI * pan_error_sum + PAN_KD * pan_derivative
    pan_last_error = error_x
    
    # PID for tilt (vertical)
    tilt_error_sum += error_y
    tilt_error_sum = clamp(tilt_error_sum, -1000, 1000)  # Anti-windup
    tilt_derivative = error_y - tilt_last_error
    tilt_adjustment = TILT_KP * error_y + TILT_KI * tilt_error_sum + TILT_KD * tilt_derivative
    tilt_last_error = error_y
    
    # Update target angles
    # Note: Pan direction may need to be inverted depending on servo orientation
    target_pan_angle = current_pan_angle + pan_adjustment
    target_tilt_angle = current_tilt_angle - tilt_adjustment  # Inverted for proper direction


def tracking_loop():
    """Background thread for smooth servo movement"""
    global running
    
    while running:
        if tracking_enabled:
            # Apply smoothing and move servos
            smooth_pan = smooth_angle(current_pan_angle, target_pan_angle, SMOOTHING_FACTOR)
            smooth_tilt = smooth_angle(current_tilt_angle, target_tilt_angle, SMOOTHING_FACTOR)
            move_servo(smooth_pan, smooth_tilt)
        
        time.sleep(0.02)  # 50Hz update rate


# ==================== CAMERA & STREAMING ====================

def init_camera():
    """Initialize the Picamera2"""
    global picam2
    
    if picam2 is not None:
        return
    
    try:
        logger.info("Initializing camera...")
        picam2 = Picamera2()
        
        # Configure for video capture
        config = picam2.create_preview_configuration(
            main={"size": (CAMERA_WIDTH, CAMERA_HEIGHT), "format": "RGB888"}
        )
        picam2.configure(config)
        picam2.start()
        
        logger.info(f"✓ Camera initialized ({CAMERA_WIDTH}x{CAMERA_HEIGHT})")
        
    except Exception as e:
        logger.error(f"Error initializing camera: {e}")
        raise


def draw_debug_overlay(frame, faces, face_center):
    """Draw debug information on the frame"""
    height, width = frame.shape[:2]
    
    # Draw crosshair at center
    center_x, center_y = width // 2, height // 2
    cv2.line(frame, (center_x - 20, center_y), (center_x + 20, center_y), (0, 255, 0), 2)
    cv2.line(frame, (center_x, center_y - 20), (center_x, center_y + 20), (0, 255, 0), 2)
    
    # Draw dead zone rectangle
    cv2.rectangle(
        frame,
        (center_x - DEAD_ZONE_X, center_y - DEAD_ZONE_Y),
        (center_x + DEAD_ZONE_X, center_y + DEAD_ZONE_Y),
        (0, 255, 0), 1
    )
    
    # Draw face rectangles
    for (x, y, w, h) in faces:
        # Rectangle around face
        cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), 2)
        # Center point
        cv2.circle(frame, (x + w//2, y + h//2), 5, (0, 0, 255), -1)
    
    # Draw line from center to face
    if face_center:
        cv2.line(frame, (center_x, center_y), face_center, (255, 0, 255), 2)
    
    # Status text
    status_color = (0, 255, 0) if face_detected else (0, 0, 255)
    status_text = "TRACKING" if face_detected else "SEARCHING"
    cv2.putText(frame, status_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, status_color, 2)
    
    # Servo angles
    cv2.putText(frame, f"Pan: {current_pan_angle:.1f}°", (10, 60), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
    cv2.putText(frame, f"Tilt: {current_tilt_angle:.1f}°", (10, 85), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
    
    # Tracking enabled status
    tracking_text = "Tracking: ON" if tracking_enabled else "Tracking: OFF"
    tracking_color = (0, 255, 0) if tracking_enabled else (0, 0, 255)
    cv2.putText(frame, tracking_text, (width - 150, 30), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, tracking_color, 2)
    
    return frame


def capture_frames():
    """Background thread to capture and process frames"""
    global current_frame, running
    
    init_camera()
    init_face_detector()
    
    while running:
        try:
            # Capture frame
            frame = picam2.capture_array()
            
            # Convert RGB to BGR for OpenCV
            frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
            
            # Detect faces
            faces, face_center = detect_faces(frame)
            
            # Calculate servo adjustments if tracking is enabled
            if tracking_enabled and face_center:
                calculate_servo_adjustment(face_center)
            
            # Draw debug overlay if enabled
            if show_debug_overlay:
                frame = draw_debug_overlay(frame, faces, face_center)
            
            # Store frame for streaming
            with frame_lock:
                current_frame = frame.copy()
            
            time.sleep(1.0 / CAMERA_FPS)
            
        except Exception as e:
            logger.error(f"Error in capture_frames: {e}")
            time.sleep(0.1)


def generate_frames():
    """Generate JPEG frames for streaming"""
    global current_frame
    
    while True:
        with frame_lock:
            if current_frame is not None:
                frame = current_frame.copy()
            else:
                # Create a blank frame if no frame available yet
                frame = np.zeros((CAMERA_HEIGHT, CAMERA_WIDTH, 3), dtype=np.uint8)
                cv2.putText(frame, "Initializing...", (200, 240),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
        
        # Encode frame as JPEG
        ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        frame_bytes = buffer.tobytes()
        
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n'
               b'Content-Length: ' + str(len(frame_bytes)).encode() + b'\r\n\r\n'
               + frame_bytes + b'\r\n')
        
        time.sleep(0.01)


# ==================== FLASK ROUTES ====================

@app.route('/')
def index():
    """Serve the main page"""
    return render_template('tracking.html')


@app.route('/video_feed')
def video_feed():
    """Video streaming route"""
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')


@app.route('/api/status')
def get_status():
    """Get current tracking status"""
    return jsonify({
        'face_detected': face_detected,
        'tracking_enabled': tracking_enabled,
        'pan_angle': round(current_pan_angle, 1),
        'tilt_angle': round(current_tilt_angle, 1),
        'face_location': last_face_location,
        'gpio_available': GPIO_AVAILABLE
    })


@app.route('/api/tracking', methods=['POST'])
def set_tracking():
    """Enable/disable tracking"""
    global tracking_enabled
    data = request.get_json()
    tracking_enabled = data.get('enabled', True)
    logger.info(f"Tracking {'enabled' if tracking_enabled else 'disabled'}")
    return jsonify({'tracking_enabled': tracking_enabled})


@app.route('/api/debug', methods=['POST'])
def set_debug():
    """Enable/disable debug overlay"""
    global show_debug_overlay
    data = request.get_json()
    show_debug_overlay = data.get('enabled', True)
    return jsonify({'debug_overlay': show_debug_overlay})


@app.route('/api/center', methods=['POST'])
def center():
    """Center the servos"""
    center_servos()
    return jsonify({'status': 'centered'})


@app.route('/api/move', methods=['POST'])
def manual_move():
    """Manually move servos"""
    global target_pan_angle, target_tilt_angle, tracking_enabled
    
    data = request.get_json()
    
    if 'pan' in data:
        target_pan_angle = clamp(data['pan'], PAN_MIN_ANGLE, PAN_MAX_ANGLE)
    if 'tilt' in data:
        target_tilt_angle = clamp(data['tilt'], TILT_MIN_ANGLE, TILT_MAX_ANGLE)
    
    # Disable tracking when manually moving
    if data.get('disable_tracking', True):
        tracking_enabled = False
    
    return jsonify({
        'pan': target_pan_angle,
        'tilt': target_tilt_angle,
        'tracking_enabled': tracking_enabled
    })


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'gpio_available': GPIO_AVAILABLE,
        'camera_active': picam2 is not None
    })


# ==================== MAIN ====================

def cleanup():
    """Cleanup all resources"""
    global running, picam2
    
    running = False
    
    if picam2:
        try:
            picam2.stop()
            picam2.close()
            logger.info("✓ Camera stopped")
        except:
            pass
    
    cleanup_servos()


if __name__ == '__main__':
    try:
        logger.info("=" * 50)
        logger.info("Face Tracking System Starting...")
        logger.info("=" * 50)
        
        # Initialize servos
        init_servos()
        center_servos()
        
        # Start capture thread
        capture_thread = threading.Thread(target=capture_frames, daemon=True)
        capture_thread.start()
        
        # Start tracking thread
        tracking_thread = threading.Thread(target=tracking_loop, daemon=True)
        tracking_thread.start()
        
        # Give threads time to initialize
        time.sleep(2)
        
        logger.info("=" * 50)
        logger.info("Starting web server on http://0.0.0.0:5000")
        logger.info("=" * 50)
        
        # Run Flask app
        app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
        
    except KeyboardInterrupt:
        logger.info("\nInterrupted by user")
    except Exception as e:
        logger.error(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        cleanup()
