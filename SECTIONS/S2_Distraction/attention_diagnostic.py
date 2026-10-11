import cv2
import time
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from head_pose import HeadPoseEstimator
from gaze_diagnostic import (
    calculate_eye_gaze,
    RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER,
    LEFT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER,
    GAZE_X_LEFT_THRESHOLD, GAZE_X_RIGHT_THRESHOLD,
    GAZE_Y_UP_THRESHOLD, GAZE_Y_DOWN_THRESHOLD
)

# CANDIDATE THRESHOLDS (HEAD POSE)
YAW_THRESH = 20.0
PITCH_THRESH = 20.0
ROLL_THRESH = 20.0
DISTRACTION_DURATION = 1.5

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

    distracted_start_time = None
    last_logged_attention = None
    last_logged_distraction = None
    last_face_status = None

    while True:
        ret, frame = cap.read()
        if not ret: break
        
        frame = cv2.flip(frame, 1)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        face_present = 0
        gaze_x, gaze_y = 0.0, 0.0
        yaw, pitch, roll = 0.0, 0.0, 0.0
        
        head_dir = "NO_FACE"
        gaze_dir = "NO_FACE"
        combined_attention = "NO_FACE"
        distraction_candidate = False
        distraction_state = "NO_FACE"
        distraction_alert = 0
        timer_val = 0.0
        
        if detection_result.face_landmarks:
            face_present = 1
            lms = detection_result.face_landmarks[0]
            
            # 1. HEAD POSE
            y, p, r = pose_estimator.get_pose(lms)
            if y is not None:
                yaw, pitch, roll = y, p, r
                if yaw > YAW_THRESH:
                    head_dir = "LEFT"
                elif yaw < -YAW_THRESH:
                    head_dir = "RIGHT"
                elif pitch > PITCH_THRESH:
                    head_dir = "DOWN"
                elif pitch < -PITCH_THRESH:
                    head_dir = "UP"
                else:
                    head_dir = "FORWARD"
            else:
                head_dir = "FORWARD"
                
            # 2. GAZE DIRECTION
            rx, ry = calculate_eye_gaze(lms, RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER)
            lx, ly = calculate_eye_gaze(lms, LEFT_EYE_OUTER, LEFT_EYE_INNER, LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER)
            
            avg_x_raw = (rx + lx) / 2.0
            avg_y_raw = (ry + ly) / 2.0
            gaze_x = -avg_x_raw
            gaze_y = avg_y_raw
            
            if gaze_x < GAZE_X_LEFT_THRESHOLD:
                gaze_dir = "LEFT"
            elif gaze_x > GAZE_X_RIGHT_THRESHOLD:
                gaze_dir = "RIGHT"
            elif gaze_y < GAZE_Y_UP_THRESHOLD:
                gaze_dir = "UP"
            elif gaze_y > GAZE_Y_DOWN_THRESHOLD:
                gaze_dir = "DOWN"
            else:
                gaze_dir = "CENTER"
                
            # 3. COMBINED ATTENTION LOGIC
            if head_dir == "FORWARD" and gaze_dir == "CENTER":
                combined_attention = "FORWARD"
                distraction_candidate = False
            elif head_dir == "FORWARD" and gaze_dir in ["LEFT", "RIGHT", "UP", "DOWN"]:
                combined_attention = f"POTENTIAL_{gaze_dir}"
                distraction_candidate = True
            elif head_dir == "LEFT" and gaze_dir == "LEFT":
                combined_attention = "DISTRACTION_CANDIDATE"
                distraction_candidate = True
            elif head_dir == "RIGHT" and gaze_dir == "RIGHT":
                combined_attention = "DISTRACTION_CANDIDATE"
                distraction_candidate = True
            elif head_dir == "DOWN" and gaze_dir == "DOWN":
                combined_attention = "DISTRACTION_CANDIDATE"
                distraction_candidate = True
            elif head_dir in ["LEFT", "RIGHT", "UP", "DOWN"] and gaze_dir == "CENTER":
                combined_attention = "HEAD_MOVEMENT_ONLY"
                distraction_candidate = False
            elif (head_dir == "LEFT" and gaze_dir == "RIGHT") or (head_dir == "RIGHT" and gaze_dir == "LEFT"):
                combined_attention = "FORWARD_COMPENSATED"
                distraction_candidate = False
            else:
                # Any other off-road case
                combined_attention = "DISTRACTION_CANDIDATE"
                distraction_candidate = True
                
            # 4. TEMPORAL DISTRACTION STATE
            if distraction_candidate:
                if distracted_start_time is None:
                    distracted_start_time = time.time()
                
                timer_val = time.time() - distracted_start_time
                if timer_val >= DISTRACTION_DURATION:
                    distraction_state = "DISTRACTED"
                    distraction_alert = 1
                else:
                    distraction_state = combined_attention
                    distraction_alert = 0
            else:
                distracted_start_time = None
                timer_val = 0.0
                distraction_state = combined_attention
                distraction_alert = 0
                
            if last_face_status == "NO_FACE":
                print("[FACE] DETECTED")
            last_face_status = "DETECTED"
                
        else:
            # NO FACE
            distracted_start_time = None
            timer_val = 0.0
            distraction_alert = 0
            if last_face_status != "NO_FACE":
                print("[FACE] NO_FACE")
            last_face_status = "NO_FACE"
            
        # Logging
        if combined_attention != last_logged_attention:
            print(f"[ATTENTION] {combined_attention}")
            last_logged_attention = combined_attention
            
        if distraction_alert != last_logged_distraction:
            if distraction_alert == 1:
                print("[DISTRACTION] ACTIVE")
            elif distraction_alert == 0 and last_logged_distraction is not None:
                print("[DISTRACTION] CLEARED")
            last_logged_distraction = distraction_alert

        # UI Overlay
        color_alert = (0, 0, 255) if distraction_alert else (0, 255, 0)
        
        cv2.putText(frame, f"FACE: {'YES' if face_present else 'NO'}", (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,255,255), 2)
        
        cv2.putText(frame, f"YAW: {yaw:.1f}", (20, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200,200,200), 2)
        cv2.putText(frame, f"PITCH: {pitch:.1f}", (20, 100), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200,200,200), 2)
        cv2.putText(frame, f"ROLL: {roll:.1f}", (20, 130), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200,200,200), 2)
        
        cv2.putText(frame, f"GAZE_X: {gaze_x:.3f}", (200, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        cv2.putText(frame, f"GAZE_Y: {gaze_y:.3f}", (200, 100), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,0), 2)
        
        cv2.putText(frame, f"HEAD: {head_dir}", (20, 170), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255,255,255), 2)
        cv2.putText(frame, f"GAZE: {gaze_dir}", (20, 210), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255,255,255), 2)
        
        cv2.putText(frame, f"ATTENTION: {combined_attention}", (20, 260), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255,165,0), 2)
        cv2.putText(frame, f"CANDIDATE: {distraction_candidate}", (20, 300), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,165,0), 2)
        
        cv2.putText(frame, f"DISTRACTION: {distraction_alert}", (20, 350), cv2.FONT_HERSHEY_SIMPLEX, 1.0, color_alert, 3)
        cv2.putText(frame, f"TIMER: {timer_val:.2f} s", (20, 390), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color_alert, 2)
        
        # Optional: draw landmarks if face present
        if face_present:
            lms = detection_result.face_landmarks[0]
            for iris_idx in [RIGHT_IRIS_CENTER, LEFT_IRIS_CENTER]:
                ix = int(lms[iris_idx].x * img_w)
                iy = int(lms[iris_idx].y * img_h)
                cv2.circle(frame, (ix, iy), 3, (0, 255, 255), -1)

        cv2.imshow('Attention Diagnostic', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    main()
