# Project Data Evaluation Plan

## Section 1: Drowsiness
- **Function**: Detects driver drowsiness based on facial features (EAR, MAR).
- **Parameters**: `EAR`, `MAR`, `Face_Detected` (inputs to Simulink); `Drowsiness_Prediction`, `Drowsiness_Alert` (Simulink outputs).
- **Existing Output**: Waveforms of EAR, MAR, and Drowsiness states.
- **Dataset Required**: Video/Image dataset with drowsy/alert drivers (e.g., UTA-RLDD).

## Section 2: Distraction
- **Function**: Detects driver distraction based on head pose, gaze, and hand position.
- **Parameters**: `Head_Pose_Yaw`, `Head_Pose_Pitch`, `Head_Pose_Roll`, `Gaze_Direction_X`, `Gaze_Direction_Y`, `Hands_On_Steering` (inputs); `Distraction_Prediction`, `Distraction_Alert` (outputs).
- **Existing Output**: Waveforms of head pose, hand status, and distraction alerts.
- **Dataset Required**: Video/Image dataset with distracted/attentive driving (e.g., State Farm Distracted Driver, Drive&Act).

## Section 3: Driver Identification
- **Function**: Identifies the driver for customized profiles and security.
- **Parameters**: `Face_Detected`, `Driver_ID_GroundTruth`, `Driver_ID_Prediction`, `Identification_Confidence`.
- **Existing Output**: Similarity scores and recognized identity.
- **Dataset Required**: Multi-driver video/image dataset for testing enrollment and recognition pipelines.

| Section | Function | Parameters | Existing Output | Dataset Required |
| ------- | -------- | ---------- | --------------- | ---------------- |
| 1. Drowsiness | EAR/MAR-based drowsiness tracking | EAR, MAR, Eye_State | EAR/MAR Waveforms | UTA-RLDD / NTHU |
| 2. Distraction | Head/Hand/Gaze-based distraction | Yaw, Pitch, Roll, Hands | Distraction Waveforms | State Farm / Drive&Act |
| 3. Identification | Driver enrollment & recognition | Face Embedding, ID | Similarity Scores | Multi-face benchmark |

