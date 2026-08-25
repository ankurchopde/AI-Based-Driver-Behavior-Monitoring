import cv2
import math
import socket
import struct
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

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

stop_thread = False
telemetry_data = (0.0, 0.0, 0.0)
telemetry_lock = threading.Lock()

def udp_worker():
    global telemetry_data
    next_time = time.perf_counter()
    interval = 1.0 / 20.0  # Exactly 20 Hz
    
    while not stop_thread:
        with telemetry_lock:
            face, ear, mar = telemetry_data
            
        packet = struct.pack('<3d', face, ear, mar)
        sock.sendto(packet, (UDP_IP, UDP_PORT))
        
        # Monotonic sleep
        next_time += interval
        sleep_time = next_time - time.perf_counter()
        if sleep_time > 0:
            time.sleep(sleep_time)

def main():
    global telemetry_data, stop_thread
    
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
        
        face_detected = 0.0
        mean_ear = 0.0
        mar = 0.0
        
        state = "NO FACE"
        color = (0, 0, 255)
        
        if detection_result.face_landmarks:
            face_detected = 1.0
            face_landmarks = detection_result.face_landmarks[0]
            
            right_ear, right_pts = calculate_ear(face_landmarks, RIGHT_EYE_INDICES, img_w, img_h)
            left_ear, left_pts = calculate_ear(face_landmarks, LEFT_EYE_INDICES, img_w, img_h)
            mean_ear = (right_ear + left_ear) / 2.0
            
            mar, mouth_pts = calculate_mar(face_landmarks, img_w, img_h)
            
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
                
        # Thread-safe telemetry update
        with telemetry_lock:
            telemetry_data = (face_detected, mean_ear, mar)
        
        # Telemetry UI
        cv2.putText(frame, f"EAR: {mean_ear:.3f} | MAR: {mar:.3f}", (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 255, 255), 3)
        cv2.putText(frame, state, (20, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
        cv2.putText(frame, f"UDP Stream -> {UDP_PORT} @ 20Hz", (20, 140), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 200), 2)
        
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
