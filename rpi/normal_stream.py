"""
Normal Streaming Module - No Face Tracking, No Servo Control
This module provides simple video streaming without any AI processing.

Usage:
    from normal_stream import NormalStreamer
    streamer = NormalStreamer(picam2, socketio, config)
    streamer.stream_frame()  # Call in main loop
"""
import cv2
import logging

logger = logging.getLogger(__name__)


class NormalStreamer:
    """
    Simple video streamer that captures and broadcasts frames.
    No face detection, no servo movement - just pure video streaming.
    """
    
    def __init__(self, config):
        """
        Initialize the normal streamer.
        
        Args:
            config: Configuration dictionary with VIDEO settings
        """
        self.config = config
        self.frame_count = 0
        logger.info("NormalStreamer initialized - Pure streaming mode")
    
    def process_frame(self, frame):
        """
        Process a frame for streaming (minimal processing).
        
        Args:
            frame: Raw camera frame (BGR format)
            
        Returns:
            Processed frame ready for encoding
        """
        # Apply digital zoom (same as face tracker for consistency)
        h, w = frame.shape[:2]
        zoom_factor = 1.3
        new_h, new_w = int(h / zoom_factor), int(w / zoom_factor)
        y_start = (h - new_h) // 2
        x_start = (w - new_w) // 2
        
        frame = frame[y_start:y_start+new_h, x_start:x_start+new_w]
        
        # Resize to standard streaming size
        frame = cv2.resize(frame, (
            self.config["VIDEO"]["WIDTH"],
            self.config["VIDEO"]["HEIGHT"]
        ))
        
        # Apply flip if configured
        if self.config["VIDEO"]["FLIP"]:
            frame = cv2.flip(frame, -1)
        
        self.frame_count += 1
        return frame
    
    def encode_frame(self, frame):
        """
        Encode frame to JPEG bytes for transmission.
        
        Args:
            frame: Processed BGR frame
            
        Returns:
            JPEG encoded bytes
        """
        quality = self.config["VIDEO"]["JPEG_QUALITY"]
        _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
        return buffer.tobytes()
    
    def get_stats(self):
        """
        Get streaming statistics.
        
        Returns:
            Dictionary with frame count and mode info
        """
        return {
            "mode": "normal",
            "frames_processed": self.frame_count,
            "tracking_enabled": False
        }
