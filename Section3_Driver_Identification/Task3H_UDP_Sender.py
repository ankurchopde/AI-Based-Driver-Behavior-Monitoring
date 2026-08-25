import sys
import os
import cv2
import mediapipe as mp
import socket
import struct
import math
import time
import threading
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# Add Section 2 to path to import proven utilities
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../Section2_Distraction')))
from head_pose import HeadPoseEstimator
from gaze_diagnostic import (
    calculate_eye_gaze,
    RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER,
    LEFT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER
)

# Import Task 3 components
from Task3C_Enrollment import EnrollmentSystem
from Task3D_Recognition_Core import RecognitionSystem
from Task3E_Confidence_Logic import ConfidenceEvaluator
from Task3F_Temporal_Filter import TemporalStabilizer

# UDP Configuration
UDP_IP = "127.0.0.1"
UDP_PORT = 5000
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]
MOUTH_INDICES = [13, 14, 78, 308]

def euclidean_distance(p1, p2):
    return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

def calculate_ear(landmarks, indices, img_w, img_h):
    pts = []
    for i in indices:
        lm = landmarks[i]
        pts.append((int(lm.x * img_w), int(lm.y * img_h)))
        
    p1, p2, p3, p4, p5, p6 = pts
    
    vertical1 = euclidean_distance(p2, p6)
    vertical2 = euclidean_distance(p3, p5)
    horizontal = euclidean_distance(p1, p4)
    
    if horizontal == 0:
        return 0.0, pts
        
    ear = (vertical1 + vertical2) / (2.0 * horizontal)
    return ear, pts

def calculate_mar(landmarks, img_w, img_h):
    p13 = (int(landmarks[13].x * img_w), int(landmarks[13].y * img_h))
    p14 = (int(landmarks[14].x * img_w), int(landmarks[14].y * img_h))
    p78 = (int(landmarks[78].x * img_w), int(landmarks[78].y * img_h))
    p308 = (int(landmarks[308].x * img_w), int(landmarks[308].y * img_h))
    
    vertical = euclidean_distance(p13, p14)
    horizontal = euclidean_distance(p78, p308)
    
    if horizontal == 0:
        return 0.0, [p13, p14, p78, p308]
    return vertical / horizontal, [p13, p14, p78, p308]


stop_thread = False
# 11 values = 88 bytes
telemetry_data = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
telemetry_lock = threading.Lock()

def udp_worker():
    global telemetry_data
    next_time = time.perf_counter()
    interval = 1.0 / 20.0  # Exactly 20 Hz
    
    while not stop_thread:
        with telemetry_lock:
            # 11-value array
            face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state = telemetry_data
            
        # Packing 11 doubles
        packet = struct.pack('<11d', face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state)
        sock.sendto(packet, (UDP_IP, UDP_PORT))
        
        # Monotonic sleep
        next_time += interval
        sleep_time = next_time - time.perf_counter()
        if sleep_time > 0:
            time.sleep(sleep_time)

def get_state_code(state_str):
    if state_str == "NO_FACE": return 0.0
    if state_str == "UNKNOWN": return 1.0
    if state_str == "IDENTIFIED": return 2.0
    if state_str == "LOW_CONFIDENCE": return 3.0
    return 0.0

def main():
    global telemetry_data, stop_thread
    
    # Init Models
    base_options = python.BaseOptions(model_asset_path='../Section1_Drowsiness/face_landmarker.task')
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
    pose_estimator = None
    
    # Init Task 3 Identity System
    rec_sys = RecognitionSystem()
    evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
    temporal_filter = TemporalStabilizer(evaluator, persistence_frames=10)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    print(f"Streaming 11-value Telemetry to MATLAB at {UDP_IP}:{UDP_PORT} at exactly 20 Hz...")
    
    # Start UDP Thread
    udp_thread = threading.Thread(target=udp_worker, daemon=True)
    udp_thread.start()

    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        frame = cv2.flip(frame, 1)
        img_h, img_w, _ = frame.shape
        
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        face_detected = 0.0
        mean_ear = 0.0
        mar = 0.0
        yaw, pitch, roll = 0.0, 0.0, 0.0
        gaze_x, gaze_y = 0.0, 0.0
        
        # Identity logic
        c_state, c_id, r_state, r_id, raw_score, raw_msg = temporal_filter.process_frame(frame)
        d_id = float(c_id) if c_id is not None else -1.0
        id_state = get_state_code(c_state)
        id_conf = float(raw_score) if raw_score is not None else 0.0
        
        if pose_estimator is None:
            pose_estimator = HeadPoseEstimator((img_h, img_w))
            
        if detection_result.face_landmarks:
            face_detected = 1.0
            face_landmarks = detection_result.face_landmarks[0]
            
            # Head Pose
            yaw_val, pitch_val, roll_val = pose_estimator.get_pose(face_landmarks)
            if yaw_val is not None:
                yaw, pitch, roll = yaw_val, pitch_val, roll_val
            
            # EAR & MAR
            right_ear, right_pts = calculate_ear(face_landmarks, RIGHT_EYE_INDICES, img_w, img_h)
            left_ear, left_pts = calculate_ear(face_landmarks, LEFT_EYE_INDICES, img_w, img_h)
            mean_ear = (right_ear + left_ear) / 2.0
            mar, mouth_pts = calculate_mar(face_landmarks, img_w, img_h)
            
            # Gaze
            rx, ry = calculate_eye_gaze(face_landmarks, RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER)
            lx, ly = calculate_eye_gaze(face_landmarks, LEFT_EYE_OUTER, LEFT_EYE_INNER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER)
            gaze_x = -((rx + lx) / 2.0)
            gaze_y = (ry + ly) / 2.0
                
        # Thread-safe telemetry update
        with telemetry_lock:
            telemetry_data = (face_detected, mean_ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state)
        
        # Telemetry UI
        cv2.putText(frame, f"ID: {d_id} | STATE: {c_state} | CONF: {id_conf:.3f}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
        cv2.putText(frame, f"EAR: {mean_ear:.3f} | MAR: {mar:.3f}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        cv2.putText(frame, f"Y: {yaw:.1f} P: {pitch:.1f} R: {roll:.1f}", (20, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        cv2.imshow('Identity + Drowsiness/Distraction UDP Bridge', frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            break
            
    stop_thread = True
    udp_thread.join(timeout=1.0)
    cap.release()
    cv2.destroyAllWindows()
    print("Test finished.")

if __name__ == '__main__':
    main()
