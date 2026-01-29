"""
Configuration for the RPi Pro Face Tracker
"""

CONFIG = {
    "VIDEO": {
        "WIDTH": 640,
        "HEIGHT": 480,
        "FPS": 30,
        "JPEG_QUALITY": 60,
        "FLIP": True
    },
    "SERVOS": {
        "PAN_PIN": 17,
        "TILT_PIN": 27,
        "FREQ": 50,
        "PAN_LIMITS": (0, 180),
        "TILT_LIMITS": (90, 180), # STRICT: Never look down (<90)
        "CENTER_PAN": 90,
        "CENTER_TILT": 110
    },
    "TRACKING": {
        "FOV_H": 62, 
        "DEAD_ZONE_ANGLE": 3.0, 
        "SPEED": 0.03, 
        "LOST_TIMEOUT": 3.0,
        "CONFIDENCE": 0.75, # Balanced confidence for 1.3x zoom
        "INVERT_PAN": True,
        "INVERT_TILT": True,
        "MAX_JUMP_DIST": 0.2, 
        "LOCK_FRAMES": 5      
    },
    "SEARCH": {
        "PAN_SPEED": 0.4, # Increased for visible search
        "TILT_SPEED": 0.1,
        "TILT_MIN": 90,
        "TILT_MAX": 130
    },
    "NETWORK": {
        "PORT": 8080,
        "NAMESPACE": "/stream"
    }
}
