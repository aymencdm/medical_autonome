"""
Arduino Serial Communication
Handles communication with Arduino for line following
"""
import serial
import time
import logging

logger = logging.getLogger(__name__)

class SerialComm:
    def __init__(self, port='/dev/ttyUSB0', baudrate=9600):
        self.port = port
        self.baudrate = baudrate
        self.serial = None
        self.is_connected = False
        
        # Check if hardware is enabled
        from config import CONFIG
        self.enabled = CONFIG["HARDWARE"]["ARDUINO_ENABLED"]
        if not self.enabled:
            logger.warning("⚠️ Arduino Disabled in Config (Mock Mode)")
        
    def connect(self):
        """Establish serial connection with Arduino"""
        if not self.enabled:
            self.is_connected = True
            logger.info("✅ Mock Arduino Connected")
            return True

        try:
            self.serial = serial.Serial(self.port, self.baudrate, timeout=1)
            time.sleep(2)  # Wait for Arduino to reset
            self.is_connected = True
            logger.info(f"✅ Connected to Arduino on {self.port}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to connect to Arduino: {e}")
            self.is_connected = False
            return False
    
    def read_line(self):
        """Read a line from Arduino"""
        if not self.enabled:
            # In mock mode, we never receive STOP signal automatically unless simulated
            return None

        if not self.is_connected or not self.serial:
            return None
        
        try:
            if self.serial.in_waiting > 0:
                line = self.serial.readline().decode('utf-8').strip()
                return line
        except Exception as e:
            logger.error(f"Serial read error: {e}")
            return None
    
    def send_resume(self):
        """Send RESUME command to Arduino"""
        return self.send_command("RESUME")
    
    def send_command(self, command: str):
        """Send command to Arduino"""
        if not self.enabled:
            logger.info(f"📤 [MOCK] Sent to Arduino: {command}")
            return True

        if not self.is_connected or not self.serial:
            logger.warning("Cannot send command: not connected")
            return False
        
        try:
            self.serial.write(f"{command}\n".encode('utf-8'))
            logger.info(f"📤 Sent to Arduino: {command}")
            return True
        except Exception as e:
            logger.error(f"Serial write error: {e}")
            return False
    
    def close(self):
        """Close serial connection"""
        if self.serial:
            self.serial.close()
            self.is_connected = False
            logger.info("Serial connection closed")
