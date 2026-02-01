"""
Servo Control Module for rpi_pro
"""
import logging
from config import CONFIG

# --- Logging ---
logger = logging.getLogger(__name__)

try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    GPIO_AVAILABLE = False
    logger.warning("GPIO not available. Running in SIMULATION mode.")

class ServoController:
    def __init__(self, initial_pan=None, initial_tilt=None):
        self.pan_pin = CONFIG["SERVOS"]["PAN_PIN"]
        self.tilt_pin = CONFIG["SERVOS"]["TILT_PIN"]
        self.freq = CONFIG["SERVOS"]["FREQ"]
        self.pan_pwm = None
        self.tilt_pwm = None
        
        # Use provided initials or defaults from CONFIG
        start_pan = initial_pan if initial_pan is not None else CONFIG["SERVOS"]["CENTER_PAN"]
        start_tilt = initial_tilt if initial_tilt is not None else CONFIG["SERVOS"]["CENTER_TILT"]
        
        if GPIO_AVAILABLE:
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            GPIO.setup([self.pan_pin, self.tilt_pin], GPIO.OUT)
            self.pan_pwm = GPIO.PWM(self.pan_pin, self.freq)
            self.tilt_pwm = GPIO.PWM(self.tilt_pin, self.freq)
            self.pan_pwm.start(self._angle_to_duty(start_pan))
            self.tilt_pwm.start(self._angle_to_duty(start_tilt))
            logger.info(f"Servos initialized (Pan:{start_pan}, Tilt:{start_tilt})")

    def _angle_to_duty(self, angle):
        return 2.5 + (angle / 180.0) * 10.0

    def move(self, pan, tilt):
        # Clamping
        p_min, p_max = CONFIG["SERVOS"]["PAN_LIMITS"]
        t_min, t_max = CONFIG["SERVOS"]["TILT_LIMITS"]
        
        pan = max(p_min, min(p_max, pan))
        tilt = max(t_min, min(t_max, tilt))
        
        if GPIO_AVAILABLE:
            if self.pan_pwm: self.pan_pwm.ChangeDutyCycle(self._angle_to_duty(pan))
            if self.tilt_pwm: self.tilt_pwm.ChangeDutyCycle(self._angle_to_duty(tilt))
        return pan, tilt

    def detach(self):
        """Stop sending PWM signal to stop jitter when holding position."""
        if GPIO_AVAILABLE:
            if self.pan_pwm: self.pan_pwm.ChangeDutyCycle(0)
            if self.tilt_pwm: self.tilt_pwm.ChangeDutyCycle(0)

    def cleanup(self):
        if GPIO_AVAILABLE:
            if self.pan_pwm: self.pan_pwm.stop()
            if self.tilt_pwm: self.tilt_pwm.stop()
            GPIO.cleanup()
