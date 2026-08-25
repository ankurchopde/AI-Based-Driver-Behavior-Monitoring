import cv2
import math
import socket
import struct
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from head_pose import HeadPoseEstimator
from gaze_diagnostic import (
    calculate_eye_gaze,
    RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER,
    LEFT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER
)

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

import time
import threading
import numpy as np

stop_thread = False
# Face, EAR, MAR, YAW, PITCH, ROLL, GAZE_X, GAZE_Y, HAND_LEFT, HAND_RIGHT, WRIST_LX, WRIST_LY, WRIST_RX, WRIST_RY
telemetry_data = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0, -1.0, -1.0, -1.0) 
telemetry_lock = threading.Lock()

def udp_worker():
    global telemetry_data
    next_time = time.perf_counter()
    interval = 1.0 / 20.0  # Exactly 20 Hz
    
    while not stop_thread:
        with telemetry_lock:
            face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, hl, hr, wlx, wly, wrx, wry = telemetry_data
            
        packet = struct.pack('<14d', face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, hl, hr, wlx, wly, wrx, wry)
        sock.sendto(packet, (UDP_IP, UDP_PORT))
        
        # Monotonic sleep
        next_time += interval
        sleep_time = next_time - time.perf_counter()
        if sleep_time > 0:
            time.sleep(sleep_time)

def main():
    global telemetry_data, stop_thread
    
    # Initialize Face Landmarker
    base_options = python.BaseOptions(model_asset_path='face_landmarker.task')
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
    
    # Initialize Hand Landmarker
    hand_base_options = python.BaseOptions(model_asset_path='hand_landmarker.task')
    hand_options = vision.HandLandmarkerOptions(
        base_options=hand_base_options,
        num_hands=2,
        min_hand_detection_confidence=0.5,
        min_hand_presence_confidence=0.5,
        min_tracking_confidence=0.5
    )
    hand_detector = vision.HandLandmarker.create_from_options(hand_options)
    
    pose_estimator = None

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    print(f"Streaming Telemetry to MATLAB at {UDP_IP}:{UDP_PORT} at exactly 20 Hz...")
    CANDIDATE_EAR_THRESHOLD = 0.15
    
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
        hand_detection_result = hand_detector.detect(mp_image)
        
        face_detected = 0.0
        mean_ear = 0.0
        mar = 0.0
        yaw, pitch, roll = 0.0, 0.0, 0.0
        gaze_x, gaze_y = 0.0, 0.0
        hand_left = 0.0
        hand_right = 0.0
        wrist_lx, wrist_ly = -1.0, -1.0
        wrist_rx, wrist_ry = -1.0, -1.0
        
        state = "NO FACE"
        color = (0, 0, 255)
        distraction_state = "NO_FACE"
        distraction_color = (0, 0, 255)
        
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
            
            for pts, indices in [(right_pts, RIGHT_EYE_INDICES), (left_pts, LEFT_EYE_INDICES)]:
                for i, pt in enumerate(pts):
                    cv2.circle(frame, pt, 3, (0, 255, 255), -1)
                cv2.line(frame, pts[1], pts[5], (255, 0, 255), 1)
                cv2.line(frame, pts[2], pts[4], (255, 0, 255), 1)
                cv2.line(frame, pts[0], pts[3], (255, 0, 255), 1)
                
            # Draw mouth
            for pt in mouth_pts:
                cv2.circle(frame, pt, 3, (0, 255, 0), -1)
            cv2.line(frame, mouth_pts[0], mouth_pts[1], (255, 255, 0), 1)
            cv2.line(frame, mouth_pts[2], mouth_pts[3], (255, 255, 0), 1)
            
            if mean_ear >= CANDIDATE_EAR_THRESHOLD:
                state = "EYES: OPEN"
                color = (0, 255, 0)
            else:
                state = "EYES: CLOSED"
                color = (0, 0, 255)
                
            # Distraction Direction
            if yaw < -20:
                distraction_state = "LOOKING RIGHT"
                distraction_color = (0, 165, 255)
            elif yaw > 20:
                distraction_state = "LOOKING LEFT"
                distraction_color = (0, 165, 255)
            elif pitch > 20:
                distraction_state = "LOOKING DOWN"
                distraction_color = (0, 165, 255)
            elif pitch < -20:
                distraction_state = "LOOKING UP"
                distraction_color = (0, 165, 255)
            else:
                distraction_state = "LOOKING FORWARD"
                distraction_color = (0, 255, 0)
        
        # Process Hands
        WHEEL_Y_MIN = 0.55
        cv2.line(frame, (0, int(img_h * WHEEL_Y_MIN)), (img_w, int(img_h * WHEEL_Y_MIN)), (255, 0, 0), 2)
        cv2.putText(frame, "STEERING WHEEL ROI", (10, int(img_h * WHEEL_Y_MIN) + 25), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
        
        if hand_detection_result.hand_landmarks:
            for i, hand_lms in enumerate(hand_detection_result.hand_landmarks):
                handedness = hand_detection_result.handedness[i][0].category_name
                wrist = hand_lms[0]
                
                # Check ROI intersection
                on_wheel = 1.0 if wrist.y > WHEEL_Y_MIN else -1.0
                
                if handedness == 'Left':
                    hand_left = on_wheel
                    wrist_lx, wrist_ly = wrist.x, wrist.y
                else:
                    hand_right = on_wheel
                    wrist_rx, wrist_ry = wrist.x, wrist.y
                    
                # Draw hand wrist
                wx, wy = int(wrist.x * img_w), int(wrist.y * img_h)
                hc = (0, 255, 0) if on_wheel == 1.0 else (0, 0, 255)
                cv2.circle(frame, (wx, wy), 8, hc, -1)
                cv2.putText(frame, handedness[0], (wx - 10, wy - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, hc, 2)
                
        # Thread-safe telemetry update
        with telemetry_lock:
            telemetry_data = (face_detected, mean_ear, mar, yaw, pitch, roll, gaze_x, gaze_y, hand_left, hand_right, wrist_lx, wrist_ly, wrist_rx, wrist_ry)
        
        # Determine Hand Status String
        hand_status_str = "UNKNOWN"
        hand_color = (200, 200, 200)
        
        if hand_left == 1.0 and hand_right == 1.0:
            hand_status_str = "BOTH HANDS ON WHEEL"
            hand_color = (0, 255, 0)
        elif hand_left == -1.0 and hand_right == -1.0:
            hand_status_str = "BOTH HANDS OFF WHEEL"
            hand_color = (0, 165, 255)
        elif hand_left == -1.0 or hand_right == -1.0:
            hand_status_str = "HAND OFF WHEEL"
            hand_color = (0, 165, 255)
        elif hand_left == 1.0 or hand_right == 1.0:
            hand_status_str = "ONE HAND ON WHEEL"
            hand_color = (0, 255, 255)
            
        # Telemetry UI
        cv2.putText(frame, f"EAR: {mean_ear:.3f} | MAR: {mar:.3f}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
        cv2.putText(frame, f"Y: {yaw:.1f} P: {pitch:.1f} R: {roll:.1f}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
        cv2.putText(frame, f"HANDS: {hand_status_str}", (20, 120), cv2.FONT_HERSHEY_SIMPLEX, 1.0, hand_color, 2)
        cv2.putText(frame, distraction_state, (20, 160), cv2.FONT_HERSHEY_SIMPLEX, 1.0, distraction_color, 2)
        
        cv2.imshow('MediaPipe -> MATLAB UDP Bridge', frame)
        
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
