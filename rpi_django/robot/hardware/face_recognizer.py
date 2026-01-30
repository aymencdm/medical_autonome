"""
Face Recognition Module
Uses OpenCV LBPH for face recognition
"""
import cv2
import os
import numpy as np
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

class FaceRecognizer:
    def __init__(self, dataset_path="datasets/faces"):
        self.dataset_path = Path(dataset_path)
        self.dataset_path.mkdir(parents=True, exist_ok=True)
        
        # Use LBPH Face Recognizer
        self.recognizer = cv2.face.LBPHFaceRecognizer_create()
        self.face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        
        self.is_trained = False
        self.label_map = {}  # {label_id: patient_name}
        self.reverse_map = {}  # {patient_name: label_id}
        
        # Try to load existing model
        self.load_model()
    
    def add_patient_images(self, patient_id: int, patient_name: str, image_paths: list):
        """Save patient face images to dataset"""
        patient_dir = self.dataset_path / str(patient_id)
        patient_dir.mkdir(exist_ok=True)
        
        for idx, img_path in enumerate(image_paths):
            # Read and detect face
            img = cv2.imread(img_path)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
            
            if len(faces) == 0:
                logger.warning(f"No face detected in {img_path}")
                continue
            
            # Save cropped face
            (x, y, w, h) = faces[0]  # Use first detected face
            face_img = gray[y:y+h, x:x+w]
            save_path = patient_dir / f"{patient_name}_{idx}.jpg"
            cv2.imwrite(str(save_path), face_img)
            logger.info(f"Saved face image: {save_path}")
        
        # Update label map
        if patient_id not in self.label_map:
            self.label_map[patient_id] = patient_name
            self.reverse_map[patient_name] = patient_id
    
    def train(self):
        """Train face recognizer on all patient images"""
        faces = []
        labels = []
        
        logger.info("🧠 Starting face recognition training...")
        
        # Load all images from dataset
        for patient_dir in self.dataset_path.iterdir():
            if not patient_dir.is_dir():
                continue
            
            patient_id = int(patient_dir.name)
            
            for img_file in patient_dir.glob("*.jpg"):
                img = cv2.imread(str(img_file), cv2.IMREAD_GRAYSCALE)
                faces.append(img)
                labels.append(patient_id)
                logger.debug(f"Loaded {img_file.name} for patient {patient_id}")
        
        if len(faces) == 0:
            logger.error("❌ No face images found for training")
            return False
        
        # Train recognizer
        self.recognizer.train(faces, np.array(labels))
        self.is_trained = True
        
        # Save model
        self.save_model()
        
        logger.info(f"✅ Training complete! {len(faces)} images, {len(set(labels))} patients")
        return True
    
    def recognize(self, frame):
        """
        Recognize face in frame
        Returns: (patient_name, confidence) or (None, 0) if not recognized
        """
        if not self.is_trained:
            logger.warning("Recognizer not trained yet")
            return None, 0
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
        
        if len(faces) == 0:
            return None, 0
        
        # Use first detected face
        (x, y, w, h) = faces[0]
        face_img = gray[y:y+h, x:x+w]
        
        # Predict
        label_id, confidence = self.recognizer.predict(face_img)
        
        # Lower confidence value = better match (0 = perfect match)
        # Threshold: accept if confidence < 100
        if confidence < 100:
            patient_name = self.label_map.get(label_id, "Unknown")
            logger.info(f"👤 Recognized: {patient_name} (confidence: {confidence:.2f})")
            return patient_name, confidence
        else:
            logger.info(f"❓ Unknown face (confidence: {confidence:.2f})")
            return None, confidence
    
    def save_model(self):
        """Save trained model and label map"""
        model_file = "face_recognizer_model.yml"
        self.recognizer.write(model_file)
        
        # Save label map
        import json
        with open("label_map.json", "w") as f:
            json.dump(self.label_map, f)
        
        logger.info(f"💾 Model saved to {model_file}")
    
    def load_model(self):
        """Load existing model if available"""
        model_file = "face_recognizer_model.yml"
        if not os.path.exists(model_file):
            logger.info("No existing model found")
            return False
        
        try:
            self.recognizer.read(model_file)
            
            # Load label map
            import json
            with open("label_map.json", "r") as f:
                # Convert keys back to int
                self.label_map = {int(k): v for k, v in json.load(f).items()}
                self.reverse_map = {v: k for k, v in self.label_map.items()}
            
            self.is_trained = True
            logger.info(f"✅ Model loaded from {model_file}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to load model: {e}")
            return False
