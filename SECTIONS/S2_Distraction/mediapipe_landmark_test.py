import cv2
import math
import sys
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]

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

def main():
    test_mode = len(sys.argv) > 1 and sys.argv[1] == '--test_mode'
    
    try:
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
        print("Model loaded successfully!")
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        # If testing in background without cam, just exit cleanly
        if test_mode: return
        return

    print("Starting Modern MediaPipe Tasks API EAR Test...")
    EAR_THRESHOLD = 0.22
    
    frame_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        frame = cv2.flip(frame, 1)
        img_h, img_w, _ = frame.shape
        
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        mean_ear = 0.0
        state = "NO FACE"
        color = (0, 0, 255)
        
        if detection_result.face_landmarks:
            face_landmarks = detection_result.face_landmarks[0]
            
            right_ear, right_pts = calculate_ear(face_landmarks, RIGHT_EYE_INDICES, img_w, img_h)
            left_ear, left_pts = calculate_ear(face_landmarks, LEFT_EYE_INDICES, img_w, img_h)
            mean_ear = (right_ear + left_ear) / 2.0
            
            if not test_mode:
                for lm in face_landmarks:
                    x, y = int(lm.x * img_w), int(lm.y * img_h)
                    cv2.circle(frame, (x, y), 1, (100, 100, 100), -1)
                    
                for pts, indices in [(right_pts, RIGHT_EYE_INDICES), (left_pts, LEFT_EYE_INDICES)]:
                    for i, pt in enumerate(pts):
                        cv2.circle(frame, pt, 3, (0, 255, 255), -1)
                        cv2.putText(frame, f"p{i+1}", (pt[0]+5, pt[1]-5), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 255, 255), 1)
                        
                    cv2.line(frame, pts[1], pts[5], (255, 0, 255), 1)
                    cv2.line(frame, pts[2], pts[4], (255, 0, 255), 1)
                    cv2.line(frame, pts[0], pts[3], (255, 0, 255), 1)
            
            if mean_ear >= EAR_THRESHOLD:
                state = "EYES: OPEN"
                color = (0, 255, 0)
            else:
                state = "EYES: CLOSED"
                color = (0, 0, 255)
                
        if not test_mode:
            cv2.putText(frame, f"EAR: {mean_ear:.3f}", (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 255, 255), 3)
            cv2.putText(frame, state, (20, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
            cv2.putText(frame, f"Threshold: {EAR_THRESHOLD}", (20, 140), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 200), 2)
            cv2.putText(frame, "Press 'q' to quit", (20, img_h - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            cv2.imshow('Mediapipe Tasks EAR Validation Test', frame)
            
        print(f"EAR: {mean_ear:.3f} | STATE: {state}")
        
        if test_mode:
            frame_count += 1
            if frame_count > 10: break
        else:
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q') or key == 27:
                break
            
    cap.release()
    if not test_mode: cv2.destroyAllWindows()
    print("Test finished.")

if __name__ == '__main__':
    main()
