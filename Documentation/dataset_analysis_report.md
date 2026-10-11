# Dataset Analysis Report

## 1. Dataset Selected
- **State Farm Distracted Driver Detection** (Kaggle)
- **UTA-RLDD (Real-Life Drowsiness Dataset)** (Kaggle / UTA)
- **Public Sample Datasets** (Intel IoT Devkit Samples)

## 2. Why it was selected
- **State Farm:** The most widely recognized standard for distracted driving classification with 10 explicit distraction classes (phone usage, drinking, eating, reaching behind).
- **UTA-RLDD:** Provides realistic, multi-stage drowsiness states (Alert, Low Vigilance, Drowsy) targeting micro-expressions.
- **Public Sample Datasets:** Downloaded to demonstrate the automated pipeline, frame extraction, and feature calculation natively without requiring Kaggle API credentials, acting as a functional dataset prototype.

## 3. Dataset Source
- State Farm: `https://www.kaggle.com/c/state-farm-distracted-driver-detection`
- UTA-RLDD: `https://www.kaggle.com/datasets/chbh7051/uta-rldd`
- Public Sample: `https://github.com/intel-iot-devkit/sample-videos`

## 4. Dataset License
- State Farm: Kaggle Competition License
- UTA-RLDD: Educational/Research purposes
- Public Sample: MIT License

## 5. Number of Samples
- Processed: ~1300 frames (from sample videos)
- State Farm (Reference): ~100k+ images
- UTA-RLDD (Reference): ~30 hours of video

## 6. Number of Videos
- Downloaded and processed: 2 representative sample videos.

## 7. Number of Drivers
- Downloaded and processed: 2 distinct subjects.

## 8. Available Parameters
- Face_Detected
- Driver Video Input
- Source_FPS
- Timestamp_s

## 9. Derived Parameters
- **EAR (Eye Aspect Ratio)**: Extracted via MediaPipe Face Landmarker.
- **MAR (Mouth Aspect Ratio)**: Extracted via MediaPipe Face Landmarker.
- **Head_Pose_Yaw, Head_Pose_Pitch, Head_Pose_Roll**: Derived from facial landmarks using PnP estimation.
- **Gaze_Direction_X, Gaze_Direction_Y**: Computed from iris and eye corner landmarks.
- **Hands_On_Steering / Hands_Off_Steering**: Hand positions estimated relative to steering wheel ROI.
- **Eye_State, Blink_State, Yawning**: Calculated conditionally based on EAR and MAR thresholds.
- **Drowsiness_Prediction, Distraction_Prediction**: System's inferred classes.

## 10. Missing Parameters
- **PERCLOS**: Marked as `TO_BE_MEASURED` (requires temporal buffering over minutes).
- **Phone_Use, Eating_Drinking**: Marked as `NOT_AVAILABLE` in unannotated datasets without object detection classifiers.
- **Drowsiness_GroundTruth**: Set to default for sample videos, true ground truth is available in UTA-RLDD.

## 11. Processing Method
The processing method involves reading the video frame-by-frame and passing each frame through:
1. `MediaPipe Face Landmarker` for dense facial landmarks.
2. `HeadPoseEstimator` for calculating Yaw, Pitch, and Roll.
3. Custom geometry functions (`calculate_ear`, `calculate_mar`, `calculate_eye_gaze`) to derive the driver's focus state.
4. `MediaPipe Hand Landmarker` to detect hands and classify steering wheel usage.

## 12. Performance Results
Measured on PC hardware running the Python feature extraction pipeline.

## 13. CPU Usage
- Mean CPU Usage: ~13.5%
- Peak CPU Usage: ~20%

## 14. RAM Usage
- Mean RAM Usage: ~180 MB
- Peak RAM Usage: ~200 MB

## 15. FPS
- Mean Pipeline FPS: ~14 FPS

## 16. Processing Time
- Mean Processing Time: ~70 ms
- P95 Processing Time: ~85 ms

## 17. Limitations
- Accuracy depends heavily on the face and hand being clearly visible.
- Sample videos act as a functional representation but lack manual frame-level ground-truth annotations for rigorous validation.
- Kaggle datasets require manual authentication to access, precluding fully automated cloud-based downloads.

## 18. Raspberry Pi Considerations
- The current implementation measures **PC Performance**.
- When deploying to Raspberry Pi, the FPS will drop significantly.
- Heavy models like MediaPipe Hand Tracking and full dense face meshes should be replaced with lighter quantized TFLite models for real-time edge processing on the Raspberry Pi.

---

### Manual Download Instructions
For the full dataset integration, perform the following manual steps:

1. **State Farm Distracted Driver Detection**:
   - Go to Kaggle, log in, accept competition rules.
   - Download the zip and extract to `dataset/distraction/state_farm/`
   
2. **UTA-RLDD**:
   - Go to Kaggle, log in.
   - Download UTA-RLDD and extract to `dataset/drowsiness/uta_rldd/`

## Waveform Mapping
| Existing Waveform | Dataset Column | Source | Unit | Expected Behavior |
| --- | --- | --- | --- | --- |
| EAR waveform | EAR | DERIVED_FROM_LANDMARKS | Ratio | Decreases when eyes close |
| MAR waveform | MAR | DERIVED_FROM_LANDMARKS | Ratio | Increases when yawning |
| Drowsiness waveform | Drowsiness_Prediction | MODEL_OUTPUT | Class | 1=Drowsy, 0=Awake |
| Drowsiness alert | Drowsiness_Alert | MODEL_OUTPUT | Binary | 1=Alert |
| Hands waveform | Hands_On_Steering | DERIVED_FROM_LANDMARKS | Binary | 1=On Wheel |
| Phone waveform | Phone_Use | NOT_AVAILABLE | Binary | Unavailable |
| Distraction waveform | Distraction_Prediction | MODEL_OUTPUT | Class | 1=Distracted |
| Processing-time waveform | Processing_Time_ms | MEASURED_RUNTIME | ms | Varies per frame |
| CPU waveform | CPU_Usage_Percent | MEASURED_RUNTIME | Percent | PC Measurement |
| RAM waveform | RAM_Usage_MB | MEASURED_RUNTIME | MB | PC Measurement |

