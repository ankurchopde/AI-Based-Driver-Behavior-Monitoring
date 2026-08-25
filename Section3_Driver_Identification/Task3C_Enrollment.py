import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
import os
import json
import argparse
import sys
import shutil

class EnrollmentSystem:
    def __init__(self, db_path="database", model_path="models/face_recognizer_fast.onnx", task_path="../Section1_Drowsiness/face_landmarker.task"):
        self.db_path = db_path
        self.registry_path = os.path.join(self.db_path, "registry.json")
        self.model_path = model_path
        
        if not os.path.exists(self.db_path):
            os.makedirs(self.db_path)
            
        if not os.path.exists(self.registry_path):
            with open(self.registry_path, "w") as f:
                json.dump({}, f)
                
        # Initialize MediaPipe Tasks Vision FaceLandmarker
        base_options = python.BaseOptions(model_asset_path=task_path)
        options = vision.FaceLandmarkerOptions(
            base_options=base_options,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
            num_faces=2,  # We need to detect multiple faces to reject them
            min_face_detection_confidence=0.5,
            min_face_presence_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.detector = vision.FaceLandmarker.create_from_options(options)
            
        # Initialize OpenCV SFace
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model not found at {self.model_path}")
        self.recognizer = cv2.FaceRecognizerSF.create(self.model_path, "")
        
    def process_frame(self, frame):
        """
        Processes a frame and returns (status, embedding, message).
        """
        # Convert to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Check blur (poor quality)
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        laplacian_var = cv2.Laplacian(gray_frame, cv2.CV_64F).var()
        if laplacian_var < 20.0:  # Threshold for blur (lowered for testing)
            return "POOR_QUALITY", None, f"Face is too blurry (variance: {laplacian_var:.1f})"
            
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        results = self.detector.detect(mp_image)
        
        if not results.face_landmarks:
            return "NO_FACE", None, "No face detected"
            
        if len(results.face_landmarks) > 1:
            return "MULTIPLE_FACES", None, "Multiple faces detected."
            
        face_landmarks = results.face_landmarks[0]
        h, w, _ = frame.shape
        
        def get_pt(idx):
            pt = face_landmarks[idx]
            return [pt.x * w, pt.y * h]
            
        right_eye = get_pt(33)
        left_eye = get_pt(263)
        nose = get_pt(1)
        right_mouth = get_pt(61)
        left_mouth = get_pt(291)
        
        xs = [pt.x * w for pt in face_landmarks]
        ys = [pt.y * h for pt in face_landmarks]
        bbox_x = min(xs)
        bbox_y = min(ys)
        bbox_w = max(xs) - bbox_x
        bbox_h = max(ys) - bbox_y
        
        face_box = np.array([
            bbox_x, bbox_y, bbox_w, bbox_h,
            right_eye[0], right_eye[1],
            left_eye[0], left_eye[1],
            nose[0], nose[1],
            right_mouth[0], right_mouth[1],
            left_mouth[0], left_mouth[1],
            1.0 # confidence
        ], dtype=np.float32)
        
        try:
            aligned_face = self.recognizer.alignCrop(frame, face_box)
            embedding = self.recognizer.feature(aligned_face)
            return "SUCCESS", embedding, "Successfully extracted feature"
        except Exception as e:
            return "POOR_QUALITY", None, f"Alignment failed: {str(e)}"
            
    def enroll_driver(self, driver_id, driver_name, frames, min_samples=15, overwrite=False):
        driver_dir = os.path.join(self.db_path, f"driver_{driver_id:02d}")
        
        if os.path.exists(driver_dir):
            if not overwrite:
                return False, f"Driver {driver_id} already exists."
            else:
                for f in os.listdir(driver_dir):
                    try: os.remove(os.path.join(driver_dir, f))
                    except: pass
        else:
            os.makedirs(driver_dir)
        
        embeddings = []
        for i, frame in enumerate(frames):
            status, emb, msg = self.process_frame(frame)
            if status == "SUCCESS":
                embeddings.append(emb)
            if len(embeddings) >= min_samples:
                break
                
        if len(embeddings) < min_samples:
            for f in os.listdir(driver_dir):
                try: os.remove(os.path.join(driver_dir, f))
                except: pass
            return False, f"Failed to collect enough samples. Got {len(embeddings)}/{min_samples}"
            
        embeddings_np = np.vstack(embeddings)
        np.save(os.path.join(driver_dir, "embeddings.npy"), embeddings_np)
        
        with open(self.registry_path, "r") as f:
            registry = json.load(f)
            
        registry[str(driver_id)] = driver_name
        
        with open(self.registry_path, "w") as f:
            json.dump(registry, f, indent=4)
            
        return True, f"Successfully enrolled Driver {driver_id}: {driver_name} with {len(embeddings)} samples."

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", type=int, required=True)
    parser.add_argument("--name", type=str, required=True)
    parser.add_argument("--samples", type=int, default=15)
    parser.add_argument("--source", type=str, default="0")
    args = parser.parse_args()
    
    system = EnrollmentSystem()
    print(f"Starting enrollment for {args.name} (ID: {args.id})")
    
    # In a real scenario, we'd open cv2.VideoCapture(int(args.source)) and loop until we get args.samples
    # For now, this acts as the backend library.
    print("Use EnrollmentSystem class directly to pass frames.")
    
if __name__ == "__main__":
    main()
