import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from head_pose import HeadPoseEstimator
import time

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
    img_h, img_w, _ = frame.shape
    pose_estimator = HeadPoseEstimator((img_h, img_w))
    
    YAW_THRESH = 20.0
    PITCH_THRESH = 20.0
    ROLL_THRESH = 20.0
    
    DISTRACTION_DURATION = 1.5
    
    distracted_start_time = None
    
    while True:
        ret, frame = cap.read()
        if not ret: break
        
        frame = cv2.flip(frame, 1)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        detection_result = detector.detect(mp_image)
        
        valid_meas = "NO FACE"
        head_dir = "UNKNOWN"
        alert = 0
        state = "NO_FACE"
        
        if detection_result.face_landmarks:
            yaw, pitch, roll = pose_estimator.get_pose(detection_result.face_landmarks[0])
            
            if yaw is not None:
                valid_meas = "VALID"
                
                # Yaw convention: >0 is right in image (Driver looking LEFT)
                # Pitch convention: >0 is down in image (Driver looking DOWN)
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
                
                # Temporal Distraction Logic (CANDIDATE — NOT FORMALLY CALIBRATED)
                if head_dir != "FORWARD":
                    if distracted_start_time is None:
                        distracted_start_time = time.time()
                    elif (time.time() - distracted_start_time) >= DISTRACTION_DURATION:
                        state = "DISTRACTED"
                        alert = 1
                    else:
                        state = head_dir
                else:
                    distracted_start_time = None
                    state = head_dir
                    alert = 0
                    
                cv2.putText(frame, f"YAW: {yaw:.1f}", (20, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
                cv2.putText(frame, f"PITCH: {pitch:.1f}", (20, 140), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
                cv2.putText(frame, f"ROLL: {roll:.1f}", (20, 180), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
        else:
            distracted_start_time = None
            state = "NO_FACE"
            alert = 0

        color = (0, 0, 255) if alert else ((0, 255, 0) if head_dir == "FORWARD" else (0, 165, 255))
        
        cv2.putText(frame, f"STATUS: {valid_meas}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (200, 200, 200), 2)
        cv2.putText(frame, f"HEAD: {head_dir}", (20, 240), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 255, 255), 3)
        cv2.putText(frame, f"STATE: {state}", (20, 290), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
        cv2.putText(frame, f"ALERT: {alert}", (20, 340), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
        
        cv2.imshow('Head Pose Diagnostic', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    main()
