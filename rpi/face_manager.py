"""
Face Manager Module
===================
Handles dataset creation, model training, and face recognition.
Uses `face_recognition` library (dlib).
"""
import os
import cv2
import pickle
import logging
import numpy as np

# Try importing face_recognition, handle failure gracefully if not installed yet
try:
    import face_recognition
    FACE_LIB_AVAILABLE = True
except ImportError:
    FACE_LIB_AVAILABLE = False

logger = logging.getLogger(__name__)

DATASET_DIR = "dataset"
ENCODINGS_FILE = "encodings.pickle"

class FaceManager:
    def __init__(self):
        self.known_encodings = []
        self.known_names = []
        self._ensure_dataset_dir()
        self.load_encodings()

    def _ensure_dataset_dir(self):
        if not os.path.exists(DATASET_DIR):
            os.makedirs(DATASET_DIR)

    def load_encodings(self):
        """Load known face encodings from pickle file."""
        if os.path.exists(ENCODINGS_FILE):
            try:
                data = pickle.loads(open(ENCODINGS_FILE, "rb").read())
                self.known_encodings = data["encodings"]
                self.known_names = data["names"]
                logger.info(f"Loaded {len(self.known_names)} known faces.")
            except Exception as e:
                logger.error(f"Error loading encodings: {e}")
        else:
            logger.info("No encodings file found. Model needs training.")

    def create_person(self, name):
        """Create a directory for a new person."""
        person_dir = os.path.join(DATASET_DIR, name)
        if not os.path.exists(person_dir):
            os.makedirs(person_dir)
            logger.info(f"Created dataset directory for: {name}")
            return True
        return False

    def save_training_image(self, name, image_bytes):
        """Save a training image for a person."""
        person_dir = os.path.join(DATASET_DIR, name)
        if not os.path.exists(person_dir):
            os.makedirs(person_dir)
        
        # Convert bytes to cv2 image
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            logger.error("Failed to decode image")
            return False

        filename = f"{len(os.listdir(person_dir)) + 1}.jpg"
        path = os.path.join(person_dir, filename)
        cv2.imwrite(path, img)
        logger.info(f"Saved training image: {path}")
        return True

    def train_model(self):
        """
        Process all images in dataset/ and create encodings.
        This is a blocking operation and might take time on RPi.
        """
        if not FACE_LIB_AVAILABLE:
            logger.error("face_recognition library not installed.")
            return False

        logger.info("Starting model training...")
        known_encodings = []
        known_names = []

        # Iterate dataset directory
        for person_name in os.listdir(DATASET_DIR):
            person_dir = os.path.join(DATASET_DIR, person_name)
            if not os.path.isdir(person_dir):
                continue
            
            for filename in os.listdir(person_dir):
                image_path = os.path.join(person_dir, filename)
                try:
                    image = cv2.imread(image_path)
                    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                    
                    # Detect coordinates first (faster)
                    boxes = face_recognition.face_locations(rgb, model="hog")
                    
                    # Compute encodings
                    encodings = face_recognition.face_encodings(rgb, boxes)
                    
                    for encoding in encodings:
                        known_encodings.append(encoding)
                        known_names.append(person_name)
                except Exception as e:
                    logger.warning(f"Skipping {image_path}: {e}")

        # Save to pickle
        data = {"encodings": known_encodings, "names": known_names}
        f = open(ENCODINGS_FILE, "wb")
        f.write(pickle.dumps(data))
        f.close()
        
        self.known_encodings = known_encodings
        self.known_names = known_names
        logger.info("Training complete. Encodings saved.")
        return True

    def recognize_faces(self, frame):
        """
        Detect faces in frame and annotate with names.
        Returns the annotated frame.
        """
        if not FACE_LIB_AVAILABLE:
            cv2.putText(frame, "Install face_recognition lib", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            return frame

        try:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Detect faces
            boxes = face_recognition.face_locations(rgb, model="hog")
            encodings = face_recognition.face_encodings(rgb, boxes)
            
            names = []
            for encoding in encodings:
                matches = face_recognition.compare_faces(self.known_encodings, encoding, tolerance=0.5) # 0.5 strictness
                name = "Unknown"
                
                if True in matches:
                    matchedIdxs = [i for (i, b) in enumerate(matches) if b]
                    counts = {}
                    for i in matchedIdxs:
                        name = self.known_names[i]
                        counts[name] = counts.get(name, 0) + 1
                    name = max(counts, key=counts.get)
                
                names.append(name)
            
            # Draw boxes
            for ((top, right, bottom, left), name) in zip(boxes, names):
                cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)
                y = top - 15 if top - 15 > 15 else top + 15
                cv2.putText(frame, name, (left, y), cv2.FONT_HERSHEY_SIMPLEX, 0.75, (0, 255, 0), 2)
                
            return frame
            
        except Exception as e:
            logger.error(f"Recognition error: {e}")
            return frame
    
    def get_persons(self):
        """Return list of person names in dataset."""
        if not os.path.exists(DATASET_DIR):
            return []
        return [name for name in os.listdir(DATASET_DIR) if os.path.isdir(os.path.join(DATASET_DIR, name))]
