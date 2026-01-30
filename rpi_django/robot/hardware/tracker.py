"""
MediaPipe Face Tracking Logic - Feature Locked
Features:
- "Center & Stop" (Deadzone)
- "Nearest Neighbor" Locking (Prevents jumping to false positives)
- "Hysteresis" (Requires persistence to switch targets)
"""
import cv2
import mediapipe as mp
import time
import math
from config import CONFIG

class FaceTrackerPro:
    def __init__(self):
        self.mp_face_detection = mp.solutions.face_detection
        self.detector = self.mp_face_detection.FaceDetection(
            model_selection=0, 
            min_detection_confidence=CONFIG["TRACKING"]["CONFIDENCE"]
        )
        self.cam_w = CONFIG["VIDEO"]["WIDTH"]
        self.cam_h = CONFIG["VIDEO"]["HEIGHT"]
        
        # Calibration
        self.pixels_per_degree_x = self.cam_w / CONFIG["TRACKING"]["FOV_H"]
        self.pixels_per_degree_y = self.cam_h / (CONFIG["TRACKING"]["FOV_H"] * (self.cam_h/self.cam_w))
        
        # State
        self.last_face_time = time.time()
        self.locked_face_center = None # (x, y) relative 0.0-1.0
        self.candidate_face_center = None # Potential new target
        self.candidate_frames = 0
        
        self.search_pan_dir = 1
        self.search_tilt_dir = 1

    def _get_center(self, detection):
        bbox = detection.location_data.relative_bounding_box
        cx = bbox.xmin + bbox.width / 2
        cy = bbox.ymin + bbox.height / 2
        return cx, cy

    def process_frame(self, frame, current_pan, current_tilt):
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.detector.process(rgb)
        
        target_pan, target_tilt = current_pan, current_tilt
        valid_face_found = False
        
        curr_time = time.time()
        
        if results.detections:
            all_faces = results.detections
            
            # --- SELECTION LOGIC ---
            selected_face = None
            
            if self.locked_face_center:
                # 1. We are locked on someone. Find the face CLOSEST to where we last saw them.
                # Since we move the camera, the face should stay roughly in center (0.5, 0.5) OR 
                # strictly speaking, relative to the frame, it shouldn't jump massively unless they sprint.
                # Actually, if we track well, the face stays near center.
                
                # Check distance to LAST KNOWN RETINAL POSITION (pixel coordinates)
                lx, ly = self.locked_face_center
                
                # Sort by distance to last position
                all_faces_sorted = sorted(all_faces, key=lambda d: math.hypot(self._get_center(d)[0] - lx, self._get_center(d)[1] - ly))
                
                nearest = all_faces_sorted[0]
                nx, ny = self._get_center(nearest)
                dist = math.hypot(nx - lx, ny - ly)
                
                # If nearest is within jump limit, keep it.
                if dist < CONFIG["TRACKING"]["MAX_JUMP_DIST"]:
                    selected_face = nearest
                    self.candidate_frames = 0 # Reset candidate counter
                else:
                    # The nearest face is TOO FAR. It's either a new person or a false positive.
                    # We treat it as a candidate.
                    # Don't move servos yet (or keep moving based on old momentum? No, hold position).
                    self._handle_candidate(nx, ny)
                    if self.candidate_frames > CONFIG["TRACKING"]["LOCK_FRAMES"]:
                        # We used to ignore it, but it has persisted. Switch lock.
                        selected_face = nearest
                        self.locked_face_center = (nx, ny)
                        self.candidate_frames = 0
            
            else:
                # 2. No lock (Search Mode). Pick the largest face.
                largest = max(all_faces, key=lambda d: d.location_data.relative_bounding_box.width * d.location_data.relative_bounding_box.height)
                # We should require a few frames to lock on initially too, but for responsiveness, let's grab it.
                selected_face = largest
                self.locked_face_center = self._get_center(largest)

            # --- MOVEMENT LOGIC ---
            if selected_face:
                valid_face_found = True
                self.last_face_time = curr_time
                
                cx_rel, cy_rel = self._get_center(selected_face)
                self.locked_face_center = (cx_rel, cy_rel)
                
                # Calculations in pixels
                cx_pix = cx_rel * self.cam_w
                cy_pix = cy_rel * self.cam_h
                
                error_x = cx_pix - (self.cam_w / 2)
                error_y = cy_pix - (self.cam_h / 2)
                
                deg_err_x = error_x / self.pixels_per_degree_x
                deg_err_y = error_y / self.pixels_per_degree_y
                
                dz = CONFIG["TRACKING"]["DEAD_ZONE_ANGLE"]
                speed = CONFIG["TRACKING"]["SPEED"]
                
                # Pan
                if abs(deg_err_x) > dz:
                    move = deg_err_x * speed
                    if CONFIG["TRACKING"].get("INVERT_PAN"): target_pan += move
                    else: target_pan -= move
                
                # Tilt
                if abs(deg_err_y) > dz:
                    move = deg_err_y * speed
                    if CONFIG["TRACKING"].get("INVERT_TILT"): target_tilt -= move
                    else: target_tilt += move
                
                # Visualization
                bbox = selected_face.location_data.relative_bounding_box
                cv2.rectangle(frame, (int(bbox.xmin*self.cam_w), int(bbox.ymin*self.cam_h)),
                              (int((bbox.xmin+bbox.width)*self.cam_w), int((bbox.ymin+bbox.height)*self.cam_h)),
                              (0, 255, 0), 2)
                cv2.circle(frame, (int(cx_pix), int(cy_pix)), 5, (0, 0, 255), -1)

        # Check Limits
        p_min, p_max = CONFIG["SERVOS"]["PAN_LIMITS"]
        t_min, t_max = CONFIG["SERVOS"]["TILT_LIMITS"]
        target_pan = max(p_min, min(p_max, target_pan))
        target_tilt = max(t_min, min(t_max, target_tilt))
        
        # --- SEARCH LOGIC (Only if truly lost) ---
        if not valid_face_found:
            # If we lost the face, we don't immediately search. We wait.
            if curr_time - self.last_face_time > CONFIG["TRACKING"]["LOST_TIMEOUT"]:
                self.locked_face_center = None # Reset lock
                
                p_speed = CONFIG["SEARCH"]["PAN_SPEED"]
                target_pan += p_speed * self.search_pan_dir
                
                t_speed = CONFIG["SEARCH"]["TILT_SPEED"]
                target_tilt += t_speed * self.search_tilt_dir
                
                # Bounce Pan
                if target_pan >= p_max: self.search_pan_dir = -1
                if target_pan <= p_min: self.search_pan_dir = 1
                
                # Bounce Tilt (Search Limits)
                t_min_s = max(90, CONFIG["SEARCH"]["TILT_MIN"])
                t_max_s = CONFIG["SEARCH"]["TILT_MAX"]
                if target_tilt >= t_max_s: self.search_tilt_dir = -1
                if target_tilt <= t_min_s: self.search_tilt_dir = 1
                target_tilt = max(t_min_s, min(t_max_s, target_tilt))

        return target_pan, target_tilt

    def _handle_candidate(self, nx, ny):
        # If we have no candidate, or this candidate is close to the old candidate
        if self.candidate_face_center is None:
            self.candidate_face_center = (nx, ny)
            self.candidate_frames = 1
        else:
            cx, cy = self.candidate_face_center
            if math.hypot(nx-cx, ny-cy) < 0.1: # 10% screen width tolerance
                self.candidate_frames += 1
                self.candidate_face_center = (nx, ny)
            else:
                # Candidate moved too much or is different, reset
                self.candidate_face_center = (nx, ny)
                self.candidate_frames = 1
