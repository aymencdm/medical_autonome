"""
RTP Face Tracking Server for Raspberry Pi
Combines OpenCV face detection with RTP streaming
"""

import cv2
import numpy as np
import threading
import time
import logging
import subprocess
import signal
import sys
from flask import Flask, jsonify
from picamera2 import Picamera2

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

# Video settings
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 480
VIDEO_FPS = 30
VIDEO_BITRATE = 1000000

# RTP Configuration
RTP_HOST = "0.0.0.0"
RTP_PORT = 5000
API_PORT = 8080

# Servo GPIO pins (BCM numbering)
PAN_SERVO_PIN = 17
TILT_SERVO_PIN = 27

# PWM frequency for servos
SERVO_PWM_FREQ = 50

# PID controller gains
PAN_KP, PAN_KI, PAN_KD = 0.05, 0.001, 0.02
TILT_KP, TILT_KI, TILT_KD = 0.05, 0.001, 0.02

# Dead zone
DEAD_ZONE_X, DEAD_ZONE_Y = 30, 30
SMOOTHING_FACTOR = 0.3

# ==================== GLOBAL VARIABLES ====================

picam2 = None
gst_process = None
pan_servo = None
tilt_servo = None

current_pan_angle = 90
current_tilt_angle = 90
target_pan_angle = 90
target_tilt_angle = 90

face_cascade = None
face_detected = False
last_face_location = None

pan_error_sum, pan_last_error = 0, 0
tilt_error_sum, tilt_last_error = 0, 0

tracking_enabled = True
running = True
streaming = False
frame_lock = threading.Lock()
current_frame = None

# ==================== HELPER FUNCTIONS ====================

def angle_to_duty_cycle(angle):
    return 2.5 + (angle / 180.0) * 10.0

def clamp(value, min_val, max_val):
    return max(min_val, min(max_val, value))

def smooth_angle(current, target, factor):
    return current + (target - current) * (1 - factor)

# ==================== SERVO CONTROL ====================

def init_servos():
    global pan_servo, tilt_servo
    if not GPIO_AVAILABLE: return
    try:
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)
        GPIO.setup(PAN_SERVO_PIN, GPIO.OUT)
        GPIO.setup(TILT_SERVO_PIN, GPIO.OUT)
        pan_servo = GPIO.PWM(PAN_SERVO_PIN, SERVO_PWM_FREQ)
        tilt_servo = GPIO.PWM(TILT_SERVO_PIN, SERVO_PWM_FREQ)
        pan_servo.start(angle_to_duty_cycle(90))
        tilt_servo.start(angle_to_duty_cycle(90))
        logger.info("✓ Servos initialized")
    except Exception as e:
        logger.error(f"Error initializing servos: {e}")

def move_servo(pan, tilt):
    global current_pan_angle, current_tilt_angle
    current_pan_angle = clamp(pan, 0, 180)
    current_tilt_angle = clamp(tilt, 30, 150)
    if GPIO_AVAILABLE and pan_servo and tilt_servo:
        pan_servo.ChangeDutyCycle(angle_to_duty_cycle(current_pan_angle))
        tilt_servo.ChangeDutyCycle(angle_to_duty_cycle(current_tilt_angle))

def tracking_loop():
    while running:
        if tracking_enabled:
            s_pan = smooth_angle(current_pan_angle, target_pan_angle, SMOOTHING_FACTOR)
            s_tilt = smooth_angle(current_tilt_angle, target_tilt_angle, SMOOTHING_FACTOR)
            move_servo(s_pan, s_tilt)
        time.sleep(0.02)

# ==================== FACE DETECTION ====================

def init_face_detector():
    global face_cascade
    path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    face_cascade = cv2.CascadeClassifier(path)
    if face_cascade.empty():
        raise RuntimeError("Could not load face cascade")
    logger.info("✓ Face detector initialized")

def detect_and_track(frame):
    global face_detected, last_face_location
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 5, minSize=(30, 30))
    
    if len(faces) > 0:
        face = max(faces, key=lambda f: f[2] * f[3])
        x, y, w, h = face
        cx, cy = x + w//2, y + h//2
        face_detected = True
        last_face_location = (cx, cy, w, h)
        
        # Calculate PID
        global pan_error_sum, pan_last_error, tilt_error_sum, tilt_last_error, target_pan_angle, target_tilt_angle
        ex = (VIDEO_WIDTH // 2) - cx
        ey = (VIDEO_HEIGHT // 2) - cy
        
        if abs(ex) > DEAD_ZONE_X:
            pan_error_sum = clamp(pan_error_sum + ex, -1000, 1000)
            target_pan_angle += PAN_KP * ex + PAN_KI * pan_error_sum + PAN_KD * (ex - pan_last_error)
            pan_last_error = ex
            
        if abs(ey) > DEAD_ZONE_Y:
            tilt_error_sum = clamp(tilt_error_sum + ey, -1000, 1000)
            target_tilt_angle -= TILT_KP * ey + TILT_KI * tilt_error_sum + TILT_KD * (ey - tilt_last_error)
            tilt_last_error = ey
            
        # Draw overlay
        cv2.rectangle(frame, (x, y), (x+w, y+h), (255, 0, 0), 2)
        cv2.circle(frame, (cx, cy), 5, (0, 0, 255), -1)
    else:
        face_detected = False

# ==================== STREAMING ====================

def start_gst():
    global gst_process
    # Pipeline: appsrc (raw) -> videoconvert -> v4l2h264enc -> rtph264pay -> udpsink
    # On RPi, v4l2h264enc is hardware accelerated
    gst_cmd = [
        'gst-launch-1.0', 'appsrc', 'name=src', 'is-live=true', 'block=true', 'format=GST_FORMAT_TIME', 'caps=video/x-raw,format=BGR,width=640,height=480,framerate=30/1',
        '!', 'videoconvert', '!', 'video/x-raw,format=I420',
        '!', 'v4l2h264enc', f'extra-controls="controls,video_bitrate={VIDEO_BITRATE}"',
        '!', 'rtph264pay', 'config-interval=1', 'pt=96',
        '!', 'udpsink', f'host={RTP_HOST}', f'port={RTP_PORT}', 'sync=false'
    ]
    logger.info(f"Starting GStreamer: {' '.join(gst_cmd)}")
    gst_process = subprocess.Popen(gst_cmd, stdin=subprocess.PIPE)

def camera_thread():
    global picam2, running, streaming
    picam2 = Picamera2()
    config = picam2.create_video_configuration(main={"size": (VIDEO_WIDTH, VIDEO_HEIGHT), "format": "BGR888"})
    picam2.configure(config)
    picam2.start()
    
    start_gst()
    streaming = True
    
    while running:
        frame = picam2.capture_array()
        detect_and_track(frame)
        
        # Add timestamp/status
        cv2.putText(frame, f"Faces: {'YES' if face_detected else 'NO'}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        # Write to GStreamer
        try:
            gst_process.stdin.write(frame.tobytes())
        except:
            break
            
    picam2.stop()
    picam2.close()
    if gst_process: gst_process.terminate()

# ==================== FLASK ====================

@app.route('/health')
def health(): return jsonify({"status": "ok", "streaming": streaming})

@app.route('/api/stream/info')
def stream_info():
    return jsonify({
        'protocol': 'rtp', 'rtp_port': RTP_PORT, 'width': VIDEO_WIDTH, 'height': VIDEO_HEIGHT,
        'fps': VIDEO_FPS, 'codec': 'h264', 'streaming': streaming
    })

@app.route('/stream.sdp')
def sdp():
    import socket
    ip = socket.gethostbyname(socket.gethostname())
    return f"v=0\no=- 0 0 IN IP4 {ip}\ns=RPi Tracker\nc=IN IP4 {ip}\nt=0 0\nm=video {RTP_PORT} RTP/AVP 96\na=rtpmap:96 H264/90000\n", 200, {'Content-Type': 'application/sdp'}

if __name__ == '__main__':
    init_servos()
    init_face_detector()
    
    threading.Thread(target=tracking_loop, daemon=True).start()
    threading.Thread(target=camera_thread, daemon=True).start()
    
    app.run(host='0.0.0.0', port=API_PORT, debug=False, threaded=True)
