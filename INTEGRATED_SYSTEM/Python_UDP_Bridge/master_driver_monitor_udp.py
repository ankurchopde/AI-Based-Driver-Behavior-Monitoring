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
import argparse
import logging
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# Configure Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger('DriverMonitor')

# Import Task 2 utilities
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

# UDP Configuration (defaults)
UDP_IP = "127.0.0.1"
UDP_PORT = 5000
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]
MOUTH_INDICES = [13, 14, 78, 308]

def euclidean_distance(p1, p2):
    return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

def calculate_ear(landmarks, indices, img_w, img_h):
    pts = [(int(landmarks[i].x * img_w), int(landmarks[i].y * img_h)) for i in indices]
    p1, p2, p3, p4, p5, p6 = pts
    
    vertical1 = euclidean_distance(p2, p6)
    vertical2 = euclidean_distance(p3, p5)
    horizontal = euclidean_distance(p1, p4)
    
    if horizontal == 0: return 0.0, pts
    return (vertical1 + vertical2) / (2.0 * horizontal), pts

def calculate_mar(landmarks, img_w, img_h):
    p13 = (int(landmarks[13].x * img_w), int(landmarks[13].y * img_h))
    p14 = (int(landmarks[14].x * img_w), int(landmarks[14].y * img_h))
    p78 = (int(landmarks[78].x * img_w), int(landmarks[78].y * img_h))
    p308 = (int(landmarks[308].x * img_w), int(landmarks[308].y * img_h))
    
    vertical = euclidean_distance(p13, p14)
    horizontal = euclidean_distance(p78, p308)
    
    if horizontal == 0: return 0.0, [p13, p14, p78, p308]
    return vertical / horizontal, [p13, p14, p78, p308]

stop_thread = False
telemetry_data = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
telemetry_lock = threading.Lock()

def udp_worker(fps_target):
    global telemetry_data
    next_time = time.perf_counter()
    interval = 1.0 / fps_target
    
    while not stop_thread:
        with telemetry_lock:
            face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state = telemetry_data
            
        try:
            packet = struct.pack('<11d', face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state)
            sock.sendto(packet, (UDP_IP, UDP_PORT))
        except Exception as e:
            logger.error(f"UDP send failed: {e}")
            
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

def enhance_image(frame):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    if np.mean(gray) < 60:
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        cl = clahe.apply(l)
        return cv2.cvtColor(cv2.merge((cl,a,b)), cv2.COLOR_LAB2BGR)
    return frame

def main():
    global telemetry_data, stop_thread
    
    parser = argparse.ArgumentParser(description="Real-Time Driver Behavior Monitor")
    parser.add_argument("--camera", type=int, default=0, help="Camera index (default: 0)")
    parser.add_argument("--video", type=str, default="", help="Path to recorded video file (for testing without webcam)")
    parser.add_argument("--headless", action="store_true", help="Run without UI (ideal for Raspberry Pi)")
    parser.add_argument("--fps", type=float, default=20.0, help="Processing and UDP broadcasting FPS target (default: 20)")
    parser.add_argument("--skip-frames", type=int, default=0, help="Skip N frames between processing to keep up with real-time (default: 0)")
    args = parser.parse_args()
    
    logger.info("SYSTEM START")
    
    ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    model_path = os.path.join(ROOT_DIR, "PROJECT", "Models", "external_backends", "face_landmarker.task")
    s3_model = os.path.join(ROOT_DIR, "PROJECT", "Models", "identification", "face_recognizer_fast.onnx")
    s3_db = os.path.join(ROOT_DIR, "SECTIONS", "S3_Driver_Identification", "database")
    
    logger.info("Loading MediaPipe Face Landmarker...")
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
    pose_estimator = None
    
    logger.info("Loading Recognition System Models...")
    rec_sys = RecognitionSystem(model_path=s3_model, db_path=s3_db, task_path=model_path)
    evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
    temporal_filter = TemporalStabilizer(evaluator, persistence_frames=10)
    logger.info("MODELS LOADED")

    if args.video:
        logger.info(f"Using recorded video: {args.video}")
        cap = cv2.VideoCapture(args.video)
    else:
        logger.info(f"Opening webcam at index {args.camera}...")
        cap = cv2.VideoCapture(args.camera)
        
    if not cap.isOpened():
        logger.error("Error: Could not open camera/video.")
        return
        
    logger.info("CAMERA CONNECTED")

    udp_thread = threading.Thread(target=udp_worker, args=(args.fps,), daemon=True)
    udp_thread.start()
    logger.info(f"Streaming telemetry to {UDP_IP}:{UDP_PORT} at {args.fps} Hz")
    
    fps_time = time.time()
    frame_count = 0
    frames_read = 0

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                if args.video:
                    logger.info("Video ended. Restarting...")
                    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                    continue
                else:
                    logger.error("Failed to read from camera.")
                    break
                    
            frames_read += 1
            if args.skip_frames > 0 and frames_read % (args.skip_frames + 1) != 0:
                continue
                
            frame = cv2.flip(frame, 1)
            frame = enhance_image(frame)
            img_h, img_w, _ = frame.shape
            
            t_start = time.perf_counter()
            
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            detection_result = detector.detect(mp_image)
            
            face_detected = 0.0
            mean_ear = float('nan')
            mar = float('nan')
            yaw, pitch, roll = float('nan'), float('nan'), float('nan')
            gaze_x, gaze_y = float('nan'), float('nan')
            
            c_state, c_id, r_state, r_id, raw_score, raw_msg = temporal_filter.process_frame(frame)
            d_id = float(c_id) if c_id is not None else -1.0
            id_state = get_state_code(c_state)
            id_conf = float(raw_score) if raw_score is not None else 0.0
            
            driver_name = "Unknown"
            if c_id is not None and c_state == "IDENTIFIED":
                if str(c_id) in rec_sys.registry:
                    driver_name = rec_sys.registry[str(c_id)].get("name", f"Driver {c_id}")
                else:
                    driver_name = f"Driver {c_id}"
            
            if pose_estimator is None:
                pose_estimator = HeadPoseEstimator((img_h, img_w))
                
            if detection_result.face_landmarks:
                face_detected = 1.0
                face_landmarks = detection_result.face_landmarks[0]
                
                yaw_val, pitch_val, roll_val = pose_estimator.get_pose(face_landmarks)
                if yaw_val is not None:
                    yaw, pitch, roll = yaw_val, pitch_val, roll_val
                
                right_ear, _ = calculate_ear(face_landmarks, RIGHT_EYE_INDICES, img_w, img_h)
                left_ear, _ = calculate_ear(face_landmarks, LEFT_EYE_INDICES, img_w, img_h)
                mean_ear = (right_ear + left_ear) / 2.0
                mar, _ = calculate_mar(face_landmarks, img_w, img_h)
                
                rx, ry = calculate_eye_gaze(face_landmarks, RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER)
                lx, ly = calculate_eye_gaze(face_landmarks, LEFT_EYE_OUTER, LEFT_EYE_INNER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER)
                gaze_x = -((rx + lx) / 2.0)
                gaze_y = (ry + ly) / 2.0
                    
            with telemetry_lock:
                telemetry_data = (face_detected, mean_ear, mar, yaw, pitch, roll, gaze_x, gaze_y, d_id, id_conf, id_state)
            
            t_end = time.perf_counter()
            process_ms = (t_end - t_start) * 1000
            
            frame_count += 1
            elapsed = time.time() - fps_time
            if elapsed > 0:
                fps = frame_count / elapsed
            else:
                fps = 0.0
                
            if elapsed > 1.0:
                fps_time = time.time()
                frame_count = 0
                
            if not args.headless:
                cv2.putText(frame, f"ID: {d_id} ({driver_name}) | STATE: {c_state} | CONF: {id_conf:.3f}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
                cv2.putText(frame, f"EAR: {mean_ear:.3f} | MAR: {mar:.3f}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                cv2.putText(frame, f"Y: {yaw:.1f} P: {pitch:.1f} R: {roll:.1f}", (20, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                cv2.putText(frame, f"FPS: {fps:.1f} | Latency: {process_ms:.1f}ms", (img_w - 300, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                
                cv2.imshow('MASTER RUNTIME - FINAL_AI_Driver_Monitoring', frame)
                
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q') or key == 27:
                    break
    except KeyboardInterrupt:
        logger.info("Interrupted by user.")
    except Exception as e:
        logger.error(f"SYSTEM ERROR: {e}")
        
    logger.info("SYSTEM STOP")
    stop_thread = True
    udp_thread.join(timeout=1.0)
    cap.release()
    if not args.headless:
        cv2.destroyAllWindows()

if __name__ == '__main__':
    main()

