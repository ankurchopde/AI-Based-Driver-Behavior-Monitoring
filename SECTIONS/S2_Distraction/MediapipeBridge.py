import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
import math

class MediapipeBridge:
    def __init__(self, model_path='face_landmarker.task'):
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.FaceLandmarkerOptions(
            base_options=base_options,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
            num_faces=1,
            min_face_detection_confidence=0.5,
            min_face_presence_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.detector = vision.FaceLandmarker.create_from_options(options)
        self.RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
        self.LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]

    def _euclidean_distance(self, p1, p2):
        return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

    def _calculate_ear(self, landmarks, indices):
        pts = [landmarks[i] for i in indices]
        p1, p2, p3, p4, p5, p6 = pts
        
        vertical1 = self._euclidean_distance((p2.x, p2.y), (p6.x, p6.y))
        vertical2 = self._euclidean_distance((p3.x, p3.y), (p5.x, p5.y))
        horizontal = self._euclidean_distance((p1.x, p1.y), (p4.x, p4.y))
        
        if horizontal == 0:
            return 0.0
            
        return (vertical1 + vertical2) / (2.0 * horizontal)

    def process_frame(self, frame_data, width, height, channels):
        # Decode the raw byte array from MATLAB into a numpy array
        # This is extremely fast compared to complex mxArray translations
        arr = np.frombuffer(frame_data, dtype=np.uint8).reshape((height, width, channels))
        
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=arr)
        detection_result = self.detector.detect(mp_image)
        
        face_detected = 0.0
        ear = 0.0
        eye_pts = []
        
        if detection_result.face_landmarks:
            face_detected = 1.0
            landmarks = detection_result.face_landmarks[0]
            
            right_ear = self._calculate_ear(landmarks, self.RIGHT_EYE_INDICES)
            left_ear = self._calculate_ear(landmarks, self.LEFT_EYE_INDICES)
            ear = (right_ear + left_ear) / 2.0
            
            for idx in self.RIGHT_EYE_INDICES + self.LEFT_EYE_INDICES:
                lm = landmarks[idx]
                # Return raw normalized coordinates
                eye_pts.extend([float(lm.x), float(lm.y)])
                
        # Return tuple: (faceDetected, eyeDetected, EAR, list_of_points)
        return face_detected, face_detected, ear, eye_pts
