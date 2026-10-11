# Section 3: Driver Identification & Verification

[![S3 Identification Architecture](../../DOCUMENTATION/architecture/04_task3_identification_flow.png)](../../DOCUMENTATION/architecture/04_task3_identification_flow.png)

---

## 1. Purpose and Overview

The **Driver Identification** module operates as an intelligent biometric verification interlock. It ensures that the individual seated in the driver's seat is an authorized, registered driver. Using lightweight deep metric learning, the system continuously verifies driver identity locally without relying on external cloud APIs.

Under the project scope boundary, this module provides **identity verification, personalization profiles, and safety logging only**. It does not perform autonomous vehicle operations.

---

## 2. Implemented Architecture and Logic Pipeline

The identification subsystem is structured into modular, independently verified stages:

```
Physical Camera Frame (640×480)
               │
               ▼
   Face Detection & Crop (160×160 RGB)
   [Laplacian Blur Check: Var > 100.0]
               │
               ▼
   FaceNet 128-D Feature Embedding
               │
               ▼
  Cosine Distance vs. Enrolled Registry
  [Distance Metric: d(u, v) = 1 - (u·v)/(||u|| ||v||)]
               │
               ▼
   Two-Tiered Confidence Evaluator
   - Candidate Threshold: d_best < 0.363
   - Ambiguity Margin: d_second - d_best > 0.05
               │
               ▼
  10-Frame Temporal Persistence Filter
  (Prevents state flickering & false lockouts)
               │
               ▼
  Telemetry Export [ID, Confidence, State]
```

### Module Responsibilities
1. **Enrollment System ([`Task3C_Enrollment.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3C_Enrollment.py)):**
   - Captures 10 distinct facial frames across slight head poses.
   - Rejects blurred frames using OpenCV Laplacian variance checking (`Var(Laplacian) > 100`).
   - Normalizes and averages the 10 extracted 128-D feature vectors.
   - Enrolls driver metadata into `database/registry.json`.

2. **Recognition Core ([`Task3D_Recognition_Core.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3D_Recognition_Core.py)):**
   - Extracts 128-dimensional L2-normalized embeddings from live crops.
   - Calculates pairwise cosine distances against enrolled templates in the database.

3. **Confidence Evaluator ([`Task3E_Confidence_Logic.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3E_Confidence_Logic.py)):**
   - **Candidate Threshold (`0.363`):** Minimum distance needed for a match. If best match $> 0.363$, driver is marked `UNKNOWN`.
   - **Ambiguity Margin (`0.05`):** If the top two enrolled candidates are within $0.05$ distance of each other, marks the result as `LOW_CONFIDENCE` to avoid false identification.

4. **Temporal Stabilizer ([`Task3F_Temporal_Filter.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3F_Temporal_Filter.py)):**
   - Implements a 10-frame hysteresis window (`persistence_frames = 10`).
   - Requires 10 consecutive matching frames to transition between driver states, preventing alert flicker caused by transient face occlusions.

---

## 3. Key Source Files and Models

| File | Type | Description |
| :--- | :--- | :--- |
| [`Task3C_Enrollment.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3C_Enrollment.py) | Python Module | Driver enrollment and multi-sample template generation |
| [`Task3D_Recognition_Core.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3D_Recognition_Core.py) | Python Module | Cosine similarity calculation against database |
| [`Task3E_Confidence_Logic.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3E_Confidence_Logic.py) | Python Module | Two-tiered thresholding and ambiguity detection |
| [`Task3F_Temporal_Filter.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3F_Temporal_Filter.py) | Python Module | 10-frame persistence buffer and state stabilizer |
| [`Task3H_UDP_Sender.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/Task3H_UDP_Sender.py) | Python Module | Standalone 88-byte UDP sender testing utility |
| [`live_enrollment.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/live_enrollment.py) | Python Script | Interactive CLI script to enroll a new driver |
| [`live_recognition.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/live_recognition.py) | Python Script | Interactive visual recognition test harness |
| [`driver_monitor_sim_identification.slx`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx) | Simulink Model | Integrated 11-channel Simulink model with ID scopes |

---

## 4. Privacy & Biometric Data Handling

> [!IMPORTANT]
> **Data Privacy Notice:** In compliance with public academic repository safety rules, actual driver biometric embeddings (`embeddings.npy`) and personal facial photographs are **strictly excluded** from Git version control via `.gitignore`. 
> 
> The project provides schema definitions, enrollment scripts, and mock test fixtures (`mock_test_database`) so users can enroll their own drivers locally without redistributing private biometric data.

---

## 5. Execution Commands

### Prerequisites
```powershell
pip install -r ../../requirements.txt
```

### Enrolling a New Driver
```powershell
cd "SECTIONS\S3_Driver_Identification"
python live_enrollment.py --name "Driver_Alice"
```
*Follow on-screen instructions to tilt head slightly for 10 distinct, clear frames.*

### Live Recognition Test Harness
```powershell
python live_recognition.py
```

### Running Comprehensive S3 Unit Tests
```powershell
python test_Task3C.py
python test_Task3D.py
python test_Task3E.py
python test_Task3F.py
python test_Task3H.py
```
*(All 5 test suites validate enrollment, thresholds, temporal debouncing, and 88-byte UDP serialization with 100% pass rate).*

---

## 6. Simulink Model Screenshot & Results

### Simulink Model Architecture
- **Integrated Model Screenshot:** [Integrated 11-Channel Simulink Model](../../Graph/Simulink_Screenshots/01_integrated_simulink_model.png)

### Performance & Validation Plots
- **Confusion Matrix:** [S3 Confusion Matrix](../../Graph/6_S3_Confusion_Matrix.png) (97.5% verification accuracy between authorized and unknown drivers)
- **Signal Dynamics:** [S3 Identification Feature Plot](../../Graph/FIG3_S3_Identification_Final.png) (Cosine distance margins and temporal persistence lock)

---

## 7. Limitations & Troubleshooting

- **Lighting Extremes:** Backlit conditions can reduce face detection confidence. The integrated system uses Adaptive CLAHE to recover facial landmarks.
- **Multiple Faces in Frame:** The system intentionally isolates the largest frontal face bounding box corresponding to the vehicle driver, ignoring passengers in the background.
