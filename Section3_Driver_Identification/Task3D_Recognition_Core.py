import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
import os
import json

class RecognitionSystem:
    def __init__(self, db_path="database", model_path="models/face_recognizer_fast.onnx", task_path="../Section1_Drowsiness/face_landmarker.task"):
        self.db_path = db_path
        self.registry_path = os.path.join(self.db_path, "registry.json")
        self.model_path = model_path
        
        # Load registry
        if not os.path.exists(self.registry_path):
            self.registry = {}
        else:
            with open(self.registry_path, "r") as f:
                self.registry = json.load(f)
                
        # Load embeddings
        self.driver_embeddings = {}
        for driver_id_str, name in self.registry.items():
            driver_dir = os.path.join(self.db_path, f"driver_{int(driver_id_str):02d}")
            emb_file = os.path.join(driver_dir, "embeddings.npy")
            if os.path.exists(emb_file):
                self.driver_embeddings[int(driver_id_str)] = np.load(emb_file)
                
        # Initialize MediaPipe Tasks Vision FaceLandmarker
        base_options = python.BaseOptions(model_asset_path=task_path)
        options = vision.FaceLandmarkerOptions(
            base_options=base_options,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
            num_faces=1,  # Only care about main face for recognition
            min_face_detection_confidence=0.5,
            min_face_presence_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.detector = vision.FaceLandmarker.create_from_options(options)
            
        # Initialize OpenCV SFace
        self.recognizer = cv2.FaceRecognizerSF.create(self.model_path, "")
        
    def get_embedding(self, frame):
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        laplacian_var = cv2.Laplacian(gray_frame, cv2.CV_64F).var()
        if laplacian_var < 20.0:
            return None, "POOR_QUALITY"
            
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        results = self.detector.detect(mp_image)
        
        if not results.face_landmarks:
            return None, "NO_FACE"
            
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
            1.0 
        ], dtype=np.float32)
        
        try:
            aligned_face = self.recognizer.alignCrop(frame, face_box)
            embedding = self.recognizer.feature(aligned_face)
            return embedding, "SUCCESS"
        except Exception:
            return None, "POOR_QUALITY"
            
    def recognize_frame(self, frame):
        """
        Returns: (best_driver_id, similarity_score, message)
        Does NOT implement thresholding/unknown logic yet. Just raw best match.
        """
        embedding, status = self.get_embedding(frame)
        if embedding is None:
            return None, 0.0, status
            
        if not self.driver_embeddings:
            return None, 0.0, "NO_DRIVERS_ENROLLED"
            
        best_id = None
        best_score = -1.0
        
        # Compare against all enrolled drivers using Cosine Similarity
        for driver_id, enrolled_embs in self.driver_embeddings.items():
            for ref_emb in enrolled_embs:
                score = self.recognizer.match(embedding, ref_emb, cv2.FaceRecognizerSF_FR_COSINE)
                if score > best_score:
                    best_score = score
                    best_id = driver_id
                    
        driver_name = self.registry.get(str(best_id), 'Unknown')
        return best_id, best_score, f"Matched Driver {best_id} ({driver_name}) with score {best_score:.4f}"
