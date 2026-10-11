# Dataset Parameter Mapping

| Section | Project Parameter | Dataset Source | Direct/Derived/Measured | Extraction Method |
| ------- | ----------------- | -------------- | ----------------------- | ----------------- |
| 1 | Frame | Video File | DIRECT | File read |
| 1 | Timestamp_s | Video File | DERIVED | Frame / Source FPS |
| 1 | Driver_ID | Metadata | DIRECT | Folder name parsing |
| 1 | Face_Detected | Video Frame | MODEL_OUTPUT | MediaPipe Face Landmarker |
| 1 | EAR | Video Frame | DERIVED | MediaPipe Landmarks Geometry |
| 1 | MAR | Video Frame | DERIVED | MediaPipe Landmarks Geometry |
| 1 | Eye_State | Video Frame | DERIVED | Condition: EAR < 0.15 |
| 1 | Blink | Video Frame | DERIVED | Edge detection on Eye_State |
| 1 | PERCLOS | Video Frame | DERIVED | Sliding window on Eye_State (Requires Temporal Buffer) |
| 1 | Yawning | Video Frame | DERIVED | Condition: MAR > 0.5 |
| 1 | Drowsiness_Prediction | System | MODEL_OUTPUT | Temporal thresholding |
| 1 | Drowsiness_GroundTruth| Annotations | ANNOTATED | Parsed from dataset metadata |
| 1 | Drowsiness_Alert | System | MODEL_OUTPUT | Condition logic |
| 2 | Hands_On_Steering | Video Frame | DERIVED | MediaPipe Hand Tracking over ROI |
| 2 | Hands_Off_Steering | Video Frame | DERIVED | Inverse of Hands_On_Steering |
| 2 | Phone_Use | Annotations | ANNOTATED | Derived from Kaggle Classes |
| 2 | Eating_Drinking | Annotations | ANNOTATED | Derived from Kaggle Classes |
| 2 | Head_Pose_Yaw | Video Frame | DERIVED | PnP on Facial Landmarks |
| 2 | Head_Pose_Pitch | Video Frame | DERIVED | PnP on Facial Landmarks |
| 2 | Head_Pose_Roll | Video Frame | DERIVED | PnP on Facial Landmarks |
| 2 | Gaze_Direction_X | Video Frame | DERIVED | Iris/Corner geometry |
| 2 | Gaze_Direction_Y | Video Frame | DERIVED | Iris/Corner geometry |
| 2 | Looking_Away | Video Frame | DERIVED | Thresholding Yaw/Pitch |
| 2 | Distraction_Prediction| System | MODEL_OUTPUT | System Logic |
| 2 | Distraction_GroundTruth| Annotations| ANNOTATED | Parsed from dataset labels |
| 3 | Driver_ID_GroundTruth | Annotations | ANNOTATED | Parsed from dataset metadata |
| 3 | Face_Embedding | Video Frame | MODEL_OUTPUT | FaceNet / Custom Extractor |
| 3 | Driver_ID_Prediction | System | MODEL_OUTPUT | Distance matching |
| 3 | Identification_Confidence| System | MODEL_OUTPUT | Distance score |
| ALL | Processing_Time_ms | System | MEASURED_RUNTIME | Python `time.perf_counter` |
| ALL | FPS | System | MEASURED_RUNTIME | 1000 / Processing_Time_ms |
| ALL | CPU_Usage_Percent | System | MEASURED_RUNTIME | `psutil.cpu_percent` |
| ALL | RAM_Usage_MB | System | MEASURED_RUNTIME | `psutil` RSS Memory |
