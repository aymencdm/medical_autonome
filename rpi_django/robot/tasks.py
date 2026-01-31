import time
import cv2
import logging
import asyncio
try:
    from picamera2 import Picamera2
except ImportError:
    Picamera2 = None
    logging.warning("Picamera2 not found. Camera features will be disabled/mocked.")
from .hardware.config import CONFIG
from .hardware.state_machine import RobotMode
from .hardware_manager import hardware
from asgiref.sync import sync_to_async

logger = logging.getLogger(__name__)
picam2 = None

_tasks_started = False

def start_background_tasks(sio):
    """Start all background threads using SocketIO's start_background_task"""
    global _tasks_started
    if _tasks_started:
        logging.warning("Background tasks already running.")
        return
    
    _tasks_started = True
    logging.info("Starting background tasks...")
    sio.start_background_task(tracking_loop, sio)
    sio.start_background_task(camera_loop, sio)
    sio.start_background_task(arduino_listener, sio)

async def tracking_loop(sio):
    """Background task for smooth servo movement"""
    last_pan, last_tilt = -1, -1
    
    while hardware.state["running"]:
        curr_pan, curr_tilt = hardware.state["pan"], hardware.state["tilt"]
        
        if abs(curr_pan - last_pan) > 0.01 or abs(curr_tilt - last_tilt) > 0.01:
            hardware.servos.move(curr_pan, curr_tilt)
            last_pan, last_tilt = curr_pan, curr_tilt
        
        await sio.sleep(0.02)

async def camera_loop(sio):
    """Capture, Analysis, Face Tracking, and Stream Broadcast"""
    global picam2
    try:
        # Initialize Camera
        try: 
            picam2 = Picamera2()
            cfg = picam2.create_video_configuration(
                main={"size": (1640, 1232), "format": "BGR888"},
                controls={"FrameRate": CONFIG["VIDEO"]["FPS"]}
            )
            picam2.configure(cfg)
            picam2.start()
            logger.info("Camera online.")
        except Exception as e:
            logger.warning(f"Picamera2 init failed: {e}")
            if not CONFIG["HARDWARE"]["SERVOS_ENABLED"]: 
                pass # Continue in mock mode

        # Optimization: Reuse buffers
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), CONFIG["VIDEO"]["JPEG_QUALITY"]]
        
        while hardware.state["running"]:
            if picam2:
                # Capture is blocking in libcamera, might block event loop? 
                # Ideally run in executor, but for now kept simple as it's the main producer
                frame = picam2.capture_array()
            else:
                import numpy as np
                frame = np.zeros((480, 640, 3), dtype=np.uint8)
                await asyncio.sleep(1/30) # Async sleep for mock
            
            # Post-processing (Resize/Flip)
            if frame is not None:
                h, w = frame.shape[:2]
                zoom_factor = 1.3
                new_h, new_w = int(h / zoom_factor), int(w / zoom_factor)
                y_start, x_start = (h - new_h) // 2, (w - new_w) // 2
                frame = frame[y_start:y_start+new_h, x_start:x_start+new_w]
                frame = cv2.resize(frame, (CONFIG["VIDEO"]["WIDTH"], CONFIG["VIDEO"]["HEIGHT"]))
                
                if CONFIG["VIDEO"]["FLIP"]:
                    frame = cv2.flip(frame, -1)
                
                # Logic - CPU intensive, should be blocking? 
                # If safe, run directly. If slow, offload.
                await process_frame_logic(frame, sio)
                
                # Broadcast
                if hardware.state["streaming"]:
                    _, buf = cv2.imencode('.jpg', frame, encode_param)
                    await sio.emit('video_frame', buf.tobytes(), namespace=CONFIG["NETWORK"]["NAMESPACE"])
            
            await broadcast_state(sio)
            await sio.sleep(0.01)

    except Exception as e:
        logger.error(f"Camera Crash: {e}")
    finally:
        if picam2: picam2.stop()
        hardware.servos.cleanup()
        hardware.medicine_controller.cleanup()

async def process_frame_logic(frame, sio):
    # Manual Capture Check
    trigger_data = hardware.state.get("trigger_capture")
    if trigger_data:
        try:
            import os
            patient_id = trigger_data["patient_id"]
            save_dir = f"{CONFIG['FACE_RECOGNITION']['DATASET_PATH']}/{patient_id}"
            os.makedirs(save_dir, exist_ok=True)
            
            filename = f"{save_dir}/manual_{int(time.time())}.jpg"
            cv2.imwrite(filename, frame)
            logger.info(f"📸 Manual capture saved: {filename}")
            
            # Notify client
            await sio.emit('capture_success', {"filename": filename}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
        except Exception as e:
            logger.error(f"Manual capture failed: {e}")
        finally:
            hardware.state["trigger_capture"] = None

    current_mode = hardware.state_machine.current_state
    
    if current_mode == RobotMode.FACE_TRACKING:
        if hardware.state["auto_tracking"]:
            # Tracker is CPU bound
            nt_pan, nt_tilt = hardware.tracker.process_frame(frame, hardware.state["pan"], hardware.state["tilt"])
            hardware.state["pan"], hardware.state["tilt"] = nt_pan, nt_tilt
            
            if hardware.tracker.locked_face_center is not None:
                if hardware.state["face_detected_time"] is None:
                    hardware.state["face_detected_time"] = time.time()
                elif time.time() - hardware.state["face_detected_time"] >= CONFIG["FACE_RECOGNITION"]["DETECTION_TIME"]:
                     hardware.state_machine.transition_to(RobotMode.FACE_RECOGNITION)
                     hardware.state["face_detected_time"] = None
            else:
                hardware.state["face_detected_time"] = None

    elif current_mode == RobotMode.FACE_RECOGNITION:
        patient_name, confidence = hardware.face_recognizer.recognize(frame)
        if patient_name:
            hardware.state["last_recognized_patient"] = patient_name
            await sio.emit('patient_recognized', {"name": patient_name}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
            await handle_recognition_logic(patient_name, sio)
        else:
             hardware.state_machine.transition_to(RobotMode.FACE_TRACKING)

    elif current_mode == RobotMode.TRAINING_CAPTURE:
        # Track face to keep it centered
        nt_pan, nt_tilt = hardware.tracker.process_frame(frame, hardware.state["pan"], hardware.state["tilt"])
        hardware.state["pan"], hardware.state["tilt"] = nt_pan, nt_tilt
        
        # Check if face is locked/stable
        if hardware.tracker.locked_face_center is not None:
            data = hardware.state_machine.state_data
            current_time = time.time()
            
            # Check delay
            if current_time - data.get("last_capture_time", 0) > CONFIG["TRAINING"]["DELAY"]:
                # Save image
                patient_id = data.get("patient_id")
                capture_count = data.get("captured_count", 0)
                
                # Create directory if needed
                import os
                save_dir = f"{CONFIG['FACE_RECOGNITION']['DATASET_PATH']}/{patient_id}"
                os.makedirs(save_dir, exist_ok=True)
                
                # Save frame
                filename = f"{save_dir}/{int(current_time)}.jpg"
                cv2.imwrite(filename, frame)
                logger.info(f"Captured training image {capture_count + 1}: {filename}")
                
                # Update state
                data["captured_count"] = capture_count + 1
                data["last_capture_time"] = current_time
                
                # Notify client (optional progress update)
                # await sio.emit('capture_progress', {"count": capture_count + 1, "total": CONFIG["TRAINING"]["SAMPLES"]}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
                
                if data["captured_count"] >= CONFIG["TRAINING"]["SAMPLES"]:
                    logger.info("Face capture complete!")
                    hardware.state_machine.transition_to(RobotMode.IDLE)
                    # Trigger training implicitly? or wait for user?
                    # For now just stop capturing.

async def handle_recognition_logic(patient_name, sio):
    from .models import Assignment
    try:
        # DB Call must be async safe
        # use sync_to_async for ORM access
        @sync_to_async
        def get_assignment():
            return Assignment.objects.select_related('medicine').get(patient__name=patient_name)
            
        assignment = await get_assignment()
        medicine = assignment.medicine
        
        hardware.state_machine.transition_to(RobotMode.MEDICINE_DISPENSING, {
            "patient_name": patient_name,
            "medicine_name": medicine.name,
            "medicine_angle": medicine.angle
        })
        sio.start_background_task(dispense_medicine_task, medicine.angle)
            
    except Assignment.DoesNotExist:
         hardware.state_machine.set_error("No medicine assigned")

async def dispense_medicine_task(medicine_angle):
    success = hardware.medicine_controller.dispense_medicine(medicine_angle)
    if success:
        hardware.state_machine.transition_to(RobotMode.WAITING_FOR_PICKUP)
        hardware.state_machine.transition_to(RobotMode.RESUMING)
        hardware.arduino.send_resume()
        hardware.state_machine.transition_to(RobotMode.LINE_FOLLOWING)
    else:
        hardware.state_machine.set_error("Medicine dispensing failed")

async def arduino_listener(sio):
    hardware.arduino.connect()
    while hardware.state["running"]:
        # Blocking I/O! Should be threaded or async serial?
        # For now, running in async loop might block. 
        # Ideally use non-blocking serial or run in executor.
        # Check if bytes available first?
        if hardware.arduino.in_waiting() > 0:
             line = hardware.arduino.read_line()
             if line == "STOP":
                 hardware.state_machine.transition_to(RobotMode.STOPPED_WAITING)
                 await asyncio.sleep(0.5)
                 hardware.state_machine.transition_to(RobotMode.FACE_TRACKING)
        await sio.sleep(0.1)

async def broadcast_state(sio):
    await sio.emit('system_state_update', hardware.state_machine.get_state(), namespace=CONFIG["NETWORK"]["NAMESPACE"])
    await sio.emit('wheel_angle_update', {"angle": hardware.medicine_controller.current_angle}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
    await sio.emit('door_state_update', {"open": hardware.medicine_controller.is_door_open}, namespace=CONFIG["NETWORK"]["NAMESPACE"])
