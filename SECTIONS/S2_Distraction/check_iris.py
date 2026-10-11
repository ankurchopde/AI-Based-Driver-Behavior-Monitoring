import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

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
    if not ret:
        return
    frame = cv2.flip(frame, 1)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    detection_result = detector.detect(mp_image)
    if detection_result.face_landmarks:
        lms = detection_result.face_landmarks[0]
        print(f"Number of landmarks: {len(lms)}")
    cap.release()

if __name__ == '__main__':
    main()
