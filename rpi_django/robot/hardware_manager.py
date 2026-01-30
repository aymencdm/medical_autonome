from .hardware.servos import ServoController
from .hardware.tracker import FaceTrackerPro
from .hardware.state_machine import StateMachine
from .hardware.medicine_controller import MedicineController
from .hardware.face_recognizer import FaceRecognizer
from .hardware.serial_comm import SerialComm
from .hardware.config import CONFIG

class HardwareManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(HardwareManager, cls).__new__(cls)
            cls._instance.servos = ServoController()
            cls._instance.tracker = FaceTrackerPro()
            cls._instance.state_machine = StateMachine()
            cls._instance.medicine_controller = MedicineController()
            cls._instance.face_recognizer = FaceRecognizer(CONFIG["FACE_RECOGNITION"]["DATASET_PATH"])
            cls._instance.arduino = SerialComm(CONFIG["ARDUINO"]["PORT"], CONFIG["ARDUINO"]["BAUDRATE"])
            
            # Global State (migrated from main.py global dict)
            cls._instance.state = {
                "running": True,
                "streaming": False,
                "auto_tracking": True,
                "pan": CONFIG["SERVOS"]["CENTER_PAN"],
                "tilt": CONFIG["SERVOS"]["CENTER_TILT"],
                "face_detected_time": None,
                "last_recognized_patient": None,
            }
        return cls._instance

# Singleton instance
hardware = HardwareManager()
