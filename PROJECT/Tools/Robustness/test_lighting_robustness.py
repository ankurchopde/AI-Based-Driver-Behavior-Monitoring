import sys
import os
import cv2
import time
import numpy as np
import pandas as pd
import json

# Setup paths
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if os.path.basename(ROOT_DIR) == "PROJECT": ROOT_DIR = os.path.dirname(ROOT_DIR)
sys.path.append(os.path.join(ROOT_DIR, "INTEGRATED_SYSTEM", "Python_UDP_Bridge"))

from head_pose import HeadPoseEstimator
from gaze_diagnostic import calculate_eye_gaze, RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER, LEFT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER
from Task3D_Recognition_Core import RecognitionSystem
from Task3E_Confidence_Logic import ConfidenceEvaluator
from Task3F_Temporal_Filter import TemporalStabilizer
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import math

RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]

def euclidean_distance(p1, p2):
    return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

def calculate_ear(landmarks, indices, img_w, img_h):
    pts = [(int(landmarks[i].x * img_w), int(landmarks[i].y * img_h)) for i in indices]
    p1, p2, p3, p4, p5, p6 = pts
    vertical1 = euclidean_distance(p2, p6)
    vertical2 = euclidean_distance(p3, p5)
    horizontal = euclidean_distance(p1, p4)
    if horizontal == 0: return float('nan')
    return (vertical1 + vertical2) / (2.0 * horizontal)

def adjust_gamma(image, gamma=1.0):
    invGamma = 1.0 / gamma
    table = np.array([((i / 255.0) ** invGamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
    return cv2.LUT(image, table)

def enhance_image(frame):
    # Convert to grayscale to check brightness
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    mean_brightness = np.mean(gray)
    
    # If image is very dark, apply CLAHE to the L channel in LAB color space
    if mean_brightness < 60:
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        cl = clahe.apply(l)
        limg = cv2.merge((cl,a,b))
        enhanced = cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)
        return enhanced
    return frame

def run_evaluation_with_clahe(video_path, gamma=1.0, max_frames=200):
    model_path = os.path.join(ROOT_DIR, "PROJECT", "Models", "external_backends", "face_landmarker.task")
    s3_model = os.path.join(ROOT_DIR, "PROJECT", "Models", "identification", "face_recognizer_fast.onnx")
    s3_db = os.path.join(ROOT_DIR, "SECTIONS", "S3_Driver_Identification", "database")
    
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
    detector = vision.FaceLandmarker.create_from_options(options)
    
    rec_sys = RecognitionSystem(model_path=s3_model, db_path=s3_db, task_path=model_path)
    evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
    temporal_filter = TemporalStabilizer(evaluator, persistence_frames=10)

    cap = cv2.VideoCapture(video_path)
    results = {
        'frames': 0, 'faces_detected': 0, 'latencies': [], 
        'mean_ear': [], 'states': []
    }
    
    while results['frames'] < max_frames:
        ret, frame = cap.read()
        if not ret: break
        
        frame = cv2.flip(frame, 1)
        if gamma != 1.0:
            frame = adjust_gamma(frame, gamma)
            
        t_start = time.perf_counter()
        
        # APPLY EXPERIMENTAL ENHANCEMENT
        enhanced_frame = enhance_image(frame)
        
        img_h, img_w, _ = enhanced_frame.shape
        
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(enhanced_frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        c_state, c_id, r_state, r_id, raw_score, raw_msg = temporal_filter.process_frame(enhanced_frame)
        
        if detection_result.face_landmarks:
            results['faces_detected'] += 1
            face_landmarks = detection_result.face_landmarks[0]
            right_ear = calculate_ear(face_landmarks, RIGHT_EYE_INDICES, img_w, img_h)
            left_ear = calculate_ear(face_landmarks, LEFT_EYE_INDICES, img_w, img_h)
            results['mean_ear'].append((right_ear + left_ear) / 2.0)
            
        t_end = time.perf_counter()
        results['latencies'].append((t_end - t_start) * 1000)
        results['frames'] += 1

    cap.release()
    
    return {
        'gamma': gamma,
        'face_coverage': results['faces_detected'] / max(1, results['frames']),
        'avg_latency_ms': np.mean(results['latencies']),
        'avg_ear': np.mean(results['mean_ear']) if results['mean_ear'] else 0,
    }

if __name__ == '__main__':
    test_video = os.path.join(ROOT_DIR, "PROJECT", "Data", "section1_drowsiness", "Fold3_part2", "Fold3_part2", "31", "10.mp4")
    print("Testing CLAHE improvement on Low Light...")
    res = run_evaluation_with_clahe(test_video, gamma=0.3)
    print("Improved Low Light:", json.dumps(res, indent=2))

