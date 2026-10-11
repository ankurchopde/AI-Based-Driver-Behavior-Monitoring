import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
from head_pose import HeadPoseEstimator

# Landmark Indices
# Driver's Right Eye (Image Left)
RIGHT_EYE_OUTER = 33
RIGHT_EYE_INNER = 133
RIGHT_EYE_TOP = 159
RIGHT_EYE_BOTTOM = 145
RIGHT_IRIS_CENTER = 468

# Driver's Left Eye (Image Right)
LEFT_EYE_INNER = 362
LEFT_EYE_OUTER = 263
LEFT_EYE_TOP = 386
LEFT_EYE_BOTTOM = 374
LEFT_IRIS_CENTER = 473

# CANDIDATE THRESHOLDS — NOT FORMALLY CALIBRATED
GAZE_X_LEFT_THRESHOLD = -0.20
GAZE_X_RIGHT_THRESHOLD = 0.20
GAZE_Y_UP_THRESHOLD = -0.30
GAZE_Y_DOWN_THRESHOLD = 0.40

def calculate_eye_gaze(landmarks, outer_idx, inner_idx, top_idx, bottom_idx, iris_idx):
    """
    Calculates normalized GAZE_X and GAZE_Y for a single eye.
    Returns gaze_x, gaze_y
    """
    outer = landmarks[outer_idx]
    inner = landmarks[inner_idx]
    top = landmarks[top_idx]
    bottom = landmarks[bottom_idx]
    iris = landmarks[iris_idx]
    
    # Calculate horizontal gaze (X)
    center_x = (inner.x + outer.x) / 2.0
    width_x = abs(inner.x - outer.x)
    
    # Calculate vertical gaze (Y)
    center_y = (top.y + bottom.y) / 2.0
    height_y = abs(bottom.y - top.y)
    
    if width_x == 0 or height_y == 0:
        return 0.0, 0.0
        
    gaze_x_raw = (iris.x - center_x) / (width_x / 2.0)
    gaze_y_raw = (iris.y - center_y) / (height_y / 2.0)
    
    return gaze_x_raw, gaze_y_raw

def main():
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

    ret, frame = cap.read()
    if not ret: return
    img_h, img_w, _ = frame.shape
    pose_estimator = HeadPoseEstimator((img_h, img_w))

    while True:
        ret, frame = cap.read()
        if not ret: break
        
        frame = cv2.flip(frame, 1)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        face_present = 0
        gaze_x = 0.0
        gaze_y = 0.0
        gaze_state = "NO_FACE"
        yaw, pitch, roll = 0.0, 0.0, 0.0
        
        if detection_result.face_landmarks:
            face_present = 1
            lms = detection_result.face_landmarks[0]
            
            # Head Pose
            y, p, r = pose_estimator.get_pose(lms)
            if y is not None:
                yaw, pitch, roll = y, p, r
                
            # Right Eye (Image Left)
            rx, ry = calculate_eye_gaze(lms, RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER)
            
            # Left Eye (Image Right)
            lx, ly = calculate_eye_gaze(lms, LEFT_EYE_OUTER, LEFT_EYE_INNER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER)
            
            # Average gaze
            avg_x_raw = (rx + lx) / 2.0
            avg_y_raw = (ry + ly) / 2.0
            
            # Sign Convention: Negative -> LEFT, Positive -> RIGHT
            # If Iris moves Image Right (positive X), that is Driver's LEFT.
            # avg_x_raw > 0 means Iris is Image Right (Driver Left).
            # To make GAZE_X match convention (Negative=LEFT, Positive=RIGHT), we invert it:
            gaze_x = -avg_x_raw
            
            # Sign Convention: Negative -> UP, Positive -> DOWN
            # If Iris moves Image UP (negative Y), avg_y_raw < 0.
            # To make GAZE_Y match convention, we keep it as is.
            gaze_y = avg_y_raw
            
            # Gaze State Logic
            if gaze_x < GAZE_X_LEFT_THRESHOLD:
                gaze_state = "LEFT"
            elif gaze_x > GAZE_X_RIGHT_THRESHOLD:
                gaze_state = "RIGHT"
            elif gaze_y < GAZE_Y_UP_THRESHOLD:
                gaze_state = "UP"
            elif gaze_y > GAZE_Y_DOWN_THRESHOLD:
                gaze_state = "DOWN"
            else:
                gaze_state = "CENTER"
                
            # Visualization: Draw Iris Centers
            for iris_idx in [RIGHT_IRIS_CENTER, LEFT_IRIS_CENTER]:
                ix = int(lms[iris_idx].x * img_w)
                iy = int(lms[iris_idx].y * img_h)
                cv2.circle(frame, (ix, iy), 3, (0, 255, 255), -1)
                
            # Visualization: Draw Eye Corners
            for corner_idx in [RIGHT_EYE_OUTER, RIGHT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_INNER]:
                cx = int(lms[corner_idx].x * img_w)
                cy = int(lms[corner_idx].y * img_h)
                cv2.circle(frame, (cx, cy), 2, (0, 0, 255), -1)

        # UI Overlay
        cv2.putText(frame, f"FACE: {face_present}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.putText(frame, f"GAZE_X: {gaze_x:.2f}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 0), 2)
        cv2.putText(frame, f"GAZE_Y: {gaze_y:.2f}", (20, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 0), 2)
        cv2.putText(frame, f"GAZE_STATE: {gaze_state}", (20, 160), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 3)
        
        cv2.putText(frame, f"YAW: {yaw:.1f}", (400, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2)
        cv2.putText(frame, f"PITCH: {pitch:.1f}", (400, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2)
        cv2.putText(frame, f"ROLL: {roll:.1f}", (400, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2)

        cv2.imshow('Eye Gaze Diagnostic', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    main()
