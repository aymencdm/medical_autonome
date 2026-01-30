"""
Updated Main Server for Medical Delivery Robot
Integrates: Face Tracking, Face Recognition, Medicine Dispensing, Arduino Communication, State Machine
"""
import cv2
import time
import logging
import threading
import asyncio
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
from picamera2 import Picamera2

from config import CONFIG
from servos import ServoController
from tracker import FaceTrackerPro
from state_machine import StateMachine, RobotMode
from medicine_controller import MedicineController
from face_recognizer import FaceRecognizer
from serial_comm import SerialComm

# --- Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# --- App ---
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# --- Globals ---
servos = ServoController()
tracker = FaceTrackerPro()
state_machine = StateMachine()
medicine_controller = MedicineController()
face_recognizer = FaceRecognizer(CONFIG["FACE_RECOGNITION"]["DATASET_PATH"])
arduino = SerialComm(CONFIG["ARDUINO"]["PORT"], CONFIG["ARDUINO"]["BAUDRATE"])
picam2 = None

# In-memory databases (replace with actual DB in production)
patients_db = {}
medicines_db = {}
assignments_db = {}

state = {
    "running": True,
    "streaming": False,
    "auto_tracking": True,
    "pan": CONFIG["SERVOS"]["CENTER_PAN"],
    "tilt": CONFIG["SERVOS"]["CENTER_TILT"],
    "face_detected_time": None,
    "last_recognized_patient": None,
}

# =============================================================================
# BACKGROUND TASKS
# =============================================================================

def tracking_loop():
    """Background task for smooth servo movement"""
    last_pan, last_tilt = -1, -1
    
    while state["running"]:
        curr_pan, curr_tilt = state["pan"], state["tilt"]
        
        if abs(curr_pan - last_pan) > 0.01 or abs(curr_tilt - last_tilt) > 0.01:
            servos.move(curr_pan, curr_tilt)
            last_pan, last_tilt = curr_pan, curr_tilt
        
        socketio.sleep(0.02)

def camera_loop():
    """Capture, Analysis, Face Tracking, and Stream Broadcast"""
    global picam2
    try:
        picam2 = Picamera2()
        cfg = picam2.create_video_configuration(
            main={"size": (1640, 1232), "format": "BGR888"},
            controls={"FrameRate": CONFIG["VIDEO"]["FPS"]}
        )
        picam2.configure(cfg)
        picam2.start()
        logger.info("Camera online.")

        while state["running"]:
            frame = picam2.capture_array()
            
            # Digital zoom
            h, w = frame.shape[:2]
            zoom_factor = 1.3
            new_h, new_w = int(h / zoom_factor), int(w / zoom_factor)
            y_start, x_start = (h - new_h) // 2, (w - new_w) // 2
            frame = frame[y_start:y_start+new_h, x_start:x_start+new_w]
            frame = cv2.resize(frame, (CONFIG["VIDEO"]["WIDTH"], CONFIG["VIDEO"]["HEIGHT"]))
            
            if CONFIG["VIDEO"]["FLIP"]:
                frame = cv2.flip(frame, -1)
            
            # Process based on current state
            current_mode = state_machine.current_state
            
            if current_mode == RobotMode.FACE_TRACKING:
                if state["auto_tracking"]:
                    nt_pan, nt_tilt = tracker.process_frame(frame, state["pan"], state["tilt"])
                    state["pan"], state["tilt"] = nt_pan, nt_tilt
                    
                    # Check if face has been detected continuously for 3 seconds
                    if tracker.locked_face_center is not None:
                        if state["face_detected_time"] is None:
                            state["face_detected_time"] = time.time()
                        elif time.time() - state["face_detected_time"] >= CONFIG["FACE_RECOGNITION"]["DETECTION_TIME"]:
                            # Transition to face recognition
                            state_machine.transition_to(RobotMode.FACE_RECOGNITION)
                            state["face_detected_time"] = None
                    else:
                        state["face_detected_time"] = None
            
            elif current_mode == RobotMode.FACE_RECOGNITION:
                # Attempt to recognize face
                patient_name, confidence = face_recognizer.recognize(frame)
                
                if patient_name:
                    state["last_recognized_patient"] = patient_name
                    socketio.emit('patient_recognized', {"name": patient_name}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
                    
                    # Get assigned medicine
                    patient_id = None
                    for pid, data in patients_db.items():
                        if data["name"] == patient_name:
                            patient_id = pid
                            break
                    
                    if patient_id and patient_id in assignments_db:
                        medicine_id = assignments_db[patient_id]
                        medicine = medicines_db.get(medicine_id)
                        
                        if medicine:
                            # Transition to dispensing
                            state_machine.transition_to(RobotMode.MEDICINE_DISPENSING, {
                                "patient_name": patient_name,
                                "medicine_name": medicine["name"],
                                "medicine_angle": medicine["angle"]
                            })
                            
                            # Start dispensing in background
                            socketio.start_background_task(dispense_medicine_task, medicine["angle"])
                        else:
                            logger.error(f"❌ No medicine assigned to {patient_name}")
                            state_machine.set_error("No medicine assigned")
                    else:
                        logger.error(f"❌ Patient {patient_name} not found in assignments")
                        state_machine.set_error("Patient not assigned")
                else:
                    # Unknown face - return to face tracking
                    logger.warning("Unknown face detected")
                    state_machine.transition_to(RobotMode.FACE_TRACKING)
            
            # Broadcast frame
            if state["streaming"]:
                _, buf = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, CONFIG["VIDEO"]["JPEG_QUALITY"]])
                socketio.emit('video_frame', buf.tobytes(), namespace=CONFIG["NETWORK"]["NAMESPACE"])
            
            # Broadcast system state
            socketio.emit('system_state_update', state_machine.get_state(), namespace=CONFIG["NETWORK"]["NAMESPACE"])
            socketio.emit('wheel_angle_update', {"angle": medicine_controller.current_angle}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
            socketio.emit('door_state_update', {"open": medicine_controller.is_door_open}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
            
            socketio.sleep(0.01)

    except Exception as e:
        logger.error(f"Camera Crash: {e}")
    finally:
        if picam2: picam2.stop()
        servos.cleanup()
        medicine_controller.cleanup()

async def dispense_medicine_task(medicine_angle):
    """Async task for medicine dispensing"""
    success = await medicine_controller.dispense_medicine(medicine_angle)
    
    if success:
        state_machine.transition_to(RobotMode.WAITING_FOR_PICKUP)
        # No additional wait needed (already waited in dispense_medicine)
        state_machine.transition_to(RobotMode.RESUMING)
        
        # Send RESUME to Arduino
        arduino.send_resume()
        
        # Return to line following
        state_machine.transition_to(RobotMode.LINE_FOLLOWING)
    else:
        state_machine.set_error("Medicine dispensing failed")

def arduino_listener():
    """Listen for STOP signal from Arduino"""
    arduino.connect()
    
    while state["running"]:
        line = arduino.read_line()
        if line == "STOP":
            logger.info("🛑 Arduino STOP signal received")
            state_machine.transition_to(RobotMode.STOPPED_WAITING)
            time.sleep(0.5)
            state_machine.transition_to(RobotMode.FACE_TRACKING)
        time.sleep(0.1)

# =============================================================================
# REST API ENDPOINTS
# =============================================================================

@app.route('/api/patients', methods=['GET', 'POST'])
def handle_patients():
    if request.method == 'GET':
        return jsonify(list(patients_db.values()))
    else:
        data = request.json
        patient_id = len(patients_db) + 1
        patients_db[patient_id] = {
            "id": patient_id,
            "name": data["name"],
            "is_trained": False
        }
        return jsonify({"id": patient_id}), 201

@app.route('/api/patients/<int:patient_id>', methods=['DELETE'])
def delete_patient(patient_id):
    if patient_id in patients_db:
        del patients_db[patient_id]
        return jsonify({"success": True})
    return jsonify({"error": "Not found"}), 404

@app.route('/api/patients/<int:patient_id>/faces', methods=['POST'])
def upload_faces(patient_id):
    # Handle face image uploads
    # Save to dataset and add to face_recognizer
    return jsonify({"success": True})

@app.route('/api/train', methods=['POST'])
def train_model():
    success = face_recognizer.train()
    return jsonify({"success": success})

@app.route('/api/medicines', methods=['GET', 'POST'])
def handle_medicines():
    if request.method == 'GET':
        return jsonify(list(medicines_db.values()))
    else:
        data = request.json
        medicine_id = len(medicines_db) + 1
        medicines_db[medicine_id] = {
            "id": medicine_id,
            "name": data["name"],
            "angle": data["angle"],
            "slotIndex": data["slotIndex"]
        }
        return jsonify({"id": medicine_id}), 201

@app.route('/api/assignments', methods=['GET', 'POST'])
def handle_assignments():
    if request.method == 'GET':
        result = []
        for patient_id, medicine_id in assignments_db.items():
            result.append({
                "patientId": patient_id,
                "medicineId": medicine_id,
                "patientName": patients_db.get(patient_id, {}).get("name"),
                "medicineName": medicines_db.get(medicine_id, {}).get("name"),
                "medicineAngle": medicines_db.get(medicine_id, {}).get("angle")
            })
        return jsonify(result)
    else:
        data = request.json
        assignments_db[data["patientId"]] = data["medicineId"]
        return jsonify({"success": True}), 201

@app.route('/api/system/status', methods=['GET'])
def get_status():
    return jsonify({
        **state_machine.get_state(),
        "wheelAngle": medicine_controller.current_angle,
        "isDoorOpen": medicine_controller.is_door_open,
        "recognizedPatientName": state.get("last_recognized_patient")
    })

@app.route('/api/system/emergency_stop', methods=['POST'])
def emergency_stop():
    state_machine.set_error("Emergency stop activated")
    medicine_controller.close_door()
    return jsonify({"success": True})

@app.route('/api/wheel/rotate', methods=['POST'])
def rotate_wheel():
    data = request.json
    asyncio.run(medicine_controller.rotate_to_angle(data["angle"]))
    return jsonify({"success": True})

@app.route('/api/wheel/door', methods=['POST'])
def control_door():
    data = request.json
    if data["open"]:
        asyncio.run(medicine_controller.open_door())
    else:
        asyncio.run(medicine_controller.close_door())
    return jsonify({"success": True})

# =============================================================================
# WEBSOCKET HANDLERS
# =============================================================================

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

# =============================================================================
# MAIN
# =============================================================================

if __name__ == '__main__':
    # Start background tasks
    socketio.start_background_task(tracking_loop)
    socketio.start_background_task(camera_loop)
    socketio.start_background_task(arduino_listener)
    
    # Initialize state machine
    state_machine.transition_to(RobotMode.LINE_FOLLOWING)
    
    logger.info(f"🤖 Medical Delivery Robot Server starting on port {CONFIG['NETWORK']['PORT']}...")
    socketio.run(app, host='0.0.0.0', port=CONFIG["NETWORK"]["PORT"], debug=False)
