"""
State Machine for Medical Delivery Robot
Handles all robot modes and transitions
"""
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class RobotMode(Enum):
    LINE_FOLLOWING = "line_following"
    STOPPED_WAITING = "stopped_waiting"
    FACE_TRACKING = "face_tracking"
    FACE_RECOGNITION = "face_recognition"
    MEDICINE_DISPENSING = "medicine_dispensing"
    WAITING_FOR_PICKUP = "waiting_for_pickup"
    RESUMING = "resuming"
    TRAINING_CAPTURE = "training_capture"
    ERROR = "error"
    IDLE = "idle"

class StateMachine:
    def __init__(self):
        self.current_state = RobotMode.IDLE
        self.previous_state = None
        self.state_data = {}
        
    def transition_to(self, new_state: RobotMode, data: dict = None):
        """Transition to a new state with optional data"""
        if self._is_valid_transition(self.current_state, new_state):
            self.previous_state = self.current_state
            self.current_state = new_state
            if data:
                self.state_data.update(data)
            logger.info(f"State transition: {self.previous_state.value} → {self.current_state.value}")
            return True
        else:
            logger.warning(f"Invalid transition: {self.current_state.value} → {new_state.value}")
            return False
    
    def _is_valid_transition(self, from_state: RobotMode, to_state: RobotMode) -> bool:
        """Define valid state transitions"""
        valid_transitions = {
            RobotMode.IDLE: [RobotMode.LINE_FOLLOWING, RobotMode.FACE_TRACKING, RobotMode.TRAINING_CAPTURE, RobotMode.ERROR],
            RobotMode.LINE_FOLLOWING: [RobotMode.STOPPED_WAITING, RobotMode.ERROR],
            RobotMode.STOPPED_WAITING: [RobotMode.FACE_TRACKING, RobotMode.LINE_FOLLOWING, RobotMode.ERROR],
            RobotMode.FACE_TRACKING: [RobotMode.FACE_RECOGNITION, RobotMode.STOPPED_WAITING, RobotMode.LINE_FOLLOWING, RobotMode.ERROR],
            RobotMode.FACE_RECOGNITION: [RobotMode.MEDICINE_DISPENSING, RobotMode.FACE_TRACKING, RobotMode.ERROR],
            RobotMode.MEDICINE_DISPENSING: [RobotMode.WAITING_FOR_PICKUP, RobotMode.ERROR],
            RobotMode.WAITING_FOR_PICKUP: [RobotMode.RESUMING, RobotMode.ERROR],
            RobotMode.RESUMING: [RobotMode.LINE_FOLLOWING, RobotMode.ERROR],
            RobotMode.TRAINING_CAPTURE: [RobotMode.IDLE, RobotMode.FACE_TRACKING, RobotMode.ERROR],
            RobotMode.ERROR: [RobotMode.IDLE, RobotMode.LINE_FOLLOWING],
        }
        
        return to_state in valid_transitions.get(from_state, [])
    
    def get_state(self) -> dict:
        """Get current state as dictionary"""
        return {
            "mode": self.current_state.value,
            "previous_mode": self.previous_state.value if self.previous_state else None,
            **self.state_data
        }
    
    def set_error(self, error_message: str):
        """Set error state with message"""
        self.transition_to(RobotMode.ERROR, {"error_message": error_message})
    
    def clear_error(self):
        """Clear error and return to idle"""
        self.state_data.pop("error_message", None)
        self.transition_to(RobotMode.IDLE)
