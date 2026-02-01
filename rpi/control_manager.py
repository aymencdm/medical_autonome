"""
Control Manager for RPi Streamer
================================
Encapsulates all servo control, state management, and the background servo loop.
"""
import time
import logging
from config import CONFIG
from servos import ServoController

logger = logging.getLogger(__name__)

class ControlManager:
    def __init__(self, socket_interface):
        self.socketio = socket_interface
        self.servos = None
        
        # State
        self.state = {
            "mode": "normal",       # "normal", "manual"
            "pan": CONFIG["SERVOS"]["CENTER_PAN"],
            "tilt": CONFIG["SERVOS"]["CENTER_TILT"],
            "servos_active": False,
            "streaming": False,
            "running": True
        }

    def start_servos(self):
        """Initialize servos for manual mode."""
        if self.servos is None:
            # Initialize with current state to avoid jump
            self.servos = ServoController(initial_pan=self.state["pan"], initial_tilt=self.state["tilt"])
            logger.info("Servos STARTED")
        
        self.state["servos_active"] = True

    def stop_servos(self):
        """Stop and cleanup servos."""
        if self.servos is not None:
            self.servos.cleanup()
            self.servos = None
            logger.info("Servos STOPPED")
        
        self.state["servos_active"] = False

    def set_mode(self, new_mode):
        """Switch between normal, manual, and recognition modes."""
        if new_mode not in ["normal", "manual", "recognition"]:
            return False
        
        if new_mode == self.state["mode"]:
            return False
        
        self.state["mode"] = new_mode
        
        if new_mode == "manual":
            self.start_servos()
            logger.info("Switched to MANUAL mode")
        elif new_mode == "recognition":
             self.stop_servos() # Ensure servos OFF in recognition mode
             logger.info("Switched to RECOGNITION mode")
        else:
            self.stop_servos()
            logger.info("Switched to NORMAL mode")
            
        return True

    def update_manual_position(self, pan=None, tilt=None):
        """Update target position (Manual Mode Only)."""
        if self.state["mode"] != "manual":
            return

        if pan is not None:
            self.state["pan"] = float(pan)
        if tilt is not None:
            self.state["tilt"] = float(tilt)
            
        # Logging for debug
        # logger.info(f"Manual Command -> Pan: {self.state['pan']:.2f}, Tilt: {self.state['tilt']:.2f}")

    def center_servos(self):
        if self.state["mode"] != "manual":
            return
        self.state["pan"] = CONFIG["SERVOS"]["CENTER_PAN"]
        self.state["tilt"] = CONFIG["SERVOS"]["CENTER_TILT"]
        logger.info("Servos centered")

    def servo_loop(self):
        """
        Background task: Servo movement logic.
        """
        last_pan = -1
        last_tilt = -1
        last_move_time = time.time()
        
        logger.info("Servo loop started")
        
        while self.state["running"]:
            if self.state["servos_active"] and self.servos is not None:
                curr_pan = self.state["pan"]
                curr_tilt = self.state["tilt"]
                
                # Update Hardware (only if changed)
                if abs(curr_pan - last_pan) > 0.01 or abs(curr_tilt - last_tilt) > 0.01:
                    # logger.info(f"Servo Loop: Moving to Pan={curr_pan}, Tilt={curr_tilt}")
                    self.servos.move(curr_pan, curr_tilt)
                    last_pan = curr_pan
                    last_tilt = curr_tilt
                    last_move_time = time.time()
                elif time.time() - last_move_time > 0.1:
                    # If idle for 0.1s, stop PWM to prevent jitter (Aggressive detach)
                    if last_pan != -999: # Sentinel to verify we don't spam detach
                         # logger.info("Servo Loop: Detaching (Idle)")
                         self.servos.detach()
                         last_pan = -999 
                         last_tilt = -999
            else:
                last_pan = -1
                last_tilt = -1
            
            self.socketio.sleep(0.02)  # 50Hz

    def cleanup(self):
        self.state["running"] = False
        self.stop_servos()

    def set_streaming(self, is_streaming):
        self.state["streaming"] = is_streaming
