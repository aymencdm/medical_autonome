"""
Medicine Carousel Controller
Controls wheel rotation servo and door servo
Implements 180° backward rotation logic
"""
import time
import logging
from .config import CONFIG

logger = logging.getLogger(__name__)

try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    GPIO_AVAILABLE = False
    logger.warning("GPIO not available. Running in SIMULATION mode.")

class MedicineController:
    def __init__(self):
        self.wheel_pin = CONFIG["MEDICINE"]["WHEEL_PIN"]
        self.door_pin = CONFIG["MEDICINE"]["DOOR_PIN"]
        self.freq = CONFIG["SERVOS"]["FREQ"]
        
        self.current_angle = 0.0
        self.wheel_pwm = None
        self.door_pwm = None
        self.is_door_open = False
        
        if GPIO_AVAILABLE and CONFIG["HARDWARE"]["MEDICINE_WHEEL_ENABLED"]:
            GPIO.setup([self.wheel_pin, self.door_pin], GPIO.OUT)
            self.wheel_pwm = GPIO.PWM(self.wheel_pin, self.freq)
            self.door_pwm = GPIO.PWM(self.door_pin, self.freq)
            self.wheel_pwm.start(self._angle_to_duty(0))
            self.door_pwm.start(self._angle_to_duty(CONFIG["MEDICINE"]["DOOR_CLOSED_ANGLE"]))
            logger.info(f"Medicine controller initialized on pins {self.wheel_pin}, {self.door_pin}")
        else:
            logger.warning("⚠️ Medicine Wheel/Door Disabled in Config (Mock Mode)")
    
    def _angle_to_duty(self, angle):
        """Convert angle (0-360° for wheel, 0-180° for door) to PWM duty cycle"""
        if angle <= 180:
            return 2.5 + (angle / 180.0) * 10.0
        else:
            # Extended range for 360° wheel
            return 2.5 + ((angle - 180) / 180.0) * 10.0
    
    def rotate_to_angle(self, target_angle: float, speed: float = None):
        """Rotate wheel to specific angle"""
        if speed is None:
            speed = CONFIG["MEDICINE"]["ROTATION_SPEED"]
        
        logger.info(f"Rotating wheel from {self.current_angle}° to {target_angle}°")
        
        # Calculate rotation direction and distance
        target_angle = target_angle % 360
        angle_diff = target_angle - self.current_angle
        
        # Normalize to shortest path
        if angle_diff > 180:
            angle_diff -= 360
        elif angle_diff < -180:
            angle_diff += 360
        
        # Simulate rotation with small steps for smooth movement
        steps = int(abs(angle_diff) / speed)
        for i in range(steps):
            self.current_angle += speed if angle_diff > 0 else -speed
            self.current_angle = self.current_angle % 360
            
            if GPIO_AVAILABLE and self.wheel_pwm:
                self.wheel_pwm.ChangeDutyCycle(self._angle_to_duty(self.current_angle))
            
            time.sleep(0.02)  # 50Hz update
        
        # Final position
        self.current_angle = target_angle
        if GPIO_AVAILABLE and self.wheel_pwm:
            self.wheel_pwm.ChangeDutyCycle(self._angle_to_duty(self.current_angle))
        
        logger.info(f"Wheel rotation complete. Current angle: {self.current_angle}°")
    
    def dispense_medicine(self, medicine_angle: float):
        """
        Complete medicine dispensing sequence with 180° backward rotation
        
        Steps:
        1. Rotate 180° backward from current position
        2. Rotate forward to medicine's angle
        3. Open door
        4. Wait for pickup (10 seconds)
        5. Close door
        """
        logger.info(f"🎯 Starting medicine dispensing at angle {medicine_angle}°")
        
        try:
            # Step 1: Rotate 180° backward
            logger.info("Step 1/5: Rotating 180° backward...")
            backward_angle = (self.current_angle + 180) % 360
            self.rotate_to_angle(backward_angle)
            
            # Step 2: Rotate to medicine angle
            logger.info("Step 2/5: Rotating to medicine angle...")
            self.rotate_to_angle(medicine_angle)
            
            # Step 3: Open door
            logger.info("Step 3/5: Opening door...")
            self.open_door()
            
            # Step 4: Wait for pickup
            logger.info(f"Step 4/5: Waiting {CONFIG['MEDICINE']['PICKUP_WAIT_TIME']}s for pickup...")
            time.sleep(CONFIG["MEDICINE"]["PICKUP_WAIT_TIME"])
            
            # Step 5: Close door
            logger.info("Step 5/5: Closing door...")
            self.close_door()
            
            logger.info("✅ Medicine dispensing complete!")
            return True
            
        except Exception as e:
            logger.error(f"❌ Medicine dispensing failed: {e}")
            return False
    
    def open_door(self):
        """Open door servo"""
        if GPIO_AVAILABLE and self.door_pwm:
            self.door_pwm.ChangeDutyCycle(
                self._angle_to_duty(CONFIG["MEDICINE"]["DOOR_OPEN_ANGLE"])
            )
        self.is_door_open = True
        time.sleep(0.5)  # Wait for servo to move
        logger.info("Door opened")
    
    def close_door(self):
        """Close door servo"""
        if GPIO_AVAILABLE and self.door_pwm:
            self.door_pwm.ChangeDutyCycle(
                self._angle_to_duty(CONFIG["MEDICINE"]["DOOR_CLOSED_ANGLE"])
            )
        self.is_door_open = False
        time.sleep(0.5)
        logger.info("Door closed")
    
    def get_status(self):
        """Get controller status"""
        return {
            "current_angle": self.current_angle,
            "is_door_open": self.is_door_open,
        }
    
    def cleanup(self):
        """Cleanup GPIO resources"""
        if GPIO_AVAILABLE:
            if self.wheel_pwm:
                self.wheel_pwm.stop()
            if self.door_pwm:
                self.door_pwm.stop()
            if CONFIG["HARDWARE"]["MEDICINE_WHEEL_ENABLED"]:
                pass # Main cleanup should handle GPIO.cleanup()

