# Section 2: Driver Distraction and Attention Detection

[![S2 Distraction Architecture](../../DOCUMENTATION/architecture/03_task2_distraction_flow.png)](../../DOCUMENTATION/architecture/03_task2_distraction_flow.png)

---

## 1. Purpose and Overview

The **Distraction and Attention Detection** subsystem extends driver monitoring beyond eyelid closures to spatial awareness. By estimating 3D head rotation and iris gaze direction, the module identifies cognitive and visual distraction—such as texting, interacting with in-car infotainment, or conversing with rear passengers—and warns the driver to redirect their focus to the roadway.

The system adheres strictly to the project safety boundary: **passive monitoring and auditory/visual risk warnings only**. It does not perform active steering, lane-centering, or braking interventions.

---

## 2. Implemented Algorithms and Features

### 3D Head Pose Estimation (Eulerian Angles)
Implemented via OpenCV `cv2.solvePnP` in [`head_pose.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/head_pose.py):
- **Anthropometric 3D Reference Model:** Standardized coordinates for nose tip `(0, 0, 0)`, chin `(0, -330, -65)`, left eye corner `(-225, 170, -135)`, right eye corner `(225, 170, -135)`, left mouth corner `(-150, -150, -125)`, and right mouth corner `(150, -150, -125)`.
- **Perspective Camera Matrix:** Calibrated focal length assuming principal point at frame center:
  $$f_x = f_y = \text{img\_width}, \quad c_x = \frac{\text{img\_width}}{2}, \quad c_y = \frac{\text{img\_height}}{2}$$
- **Euler Angle Decomposition:** Maps the rotation matrix into intuitive degrees:
  - **Yaw ($\psi$):** Horizontal rotation (left/right window checks).
  - **Pitch ($\theta$):** Vertical tilt (looking down at mobile phone or upward).
  - **Roll ($\phi$):** Lateral tilt (head resting against shoulder).

### Gaze Direction Vectoring
Implemented in [`gaze_diagnostic.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/gaze_diagnostic.py):
- Tracks the iris center relative to 4 bounding eye landmarks (inner, outer, superior, inferior).
- Computes normalized ratios:
  $$\text{Gaze}_X = \frac{x_{\text{iris}} - x_{\text{inner}}}{x_{\text{outer}} - x_{\text{inner}}} - 0.5, \quad \text{Gaze}_Y = \frac{y_{\text{iris}} - y_{\text{top}}}{y_{\text{bottom}} - y_{\text{top}}} - 0.5$$
- Detects peripheral glances where the head remains facing forward but eyes are off-road.

### Spatial Boundaries & Attention Logic
Evaluated inside the Simulink state machine:
- **Yaw Inattention Limits:** $|\text{Yaw}| > 25^\circ$ (exceeds normal forward-facing driving cone).
- **Pitch Inattention Limits:** $\text{Pitch} < -15^\circ$ (looking down at lap/phone) or $\text{Pitch} > 20^\circ$.
- **Temporal Debounce:** Requires the boundary violation to persist continuously for **$\ge 2.0\text{ seconds}$** before triggering a **DISTRACTED** alert, permitting routine side-mirror checks without false alarms.

---

## 3. Architecture & Data Flow

```
Webcam Frame (640×480)
           │
           ▼
MediaPipe FaceMesh (468 3D Landmarks)
     │                     │
     ▼                     ▼
SolvePnP Solver       Iris Gaze Ratios
(Yaw, Pitch, Roll)   (Gaze_X, Gaze_Y)
     │                     │
     └──────────┬──────────┘
                ▼
  UDP Telemetry (8 Doubles, Port 5000)
                │
                ▼
Simulink Model (driver_monitor_sim_distraction.slx)
  [Angular Comparators] ──> [2.0s Timer] ──> [Distraction Alarm]
```

---

## 4. Key Source Scripts and Models

| File | Type | Description |
| :--- | :--- | :--- |
| [`head_pose.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/head_pose.py) | Python Module | `HeadPoseEstimator` class implementing `solvePnP` |
| [`gaze_diagnostic.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/gaze_diagnostic.py) | Python Module | Iris landmark extraction and eye gaze ratio solver |
| [`attention_scorer.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/reference/Driver-State-Detection-master/driver_state_detection/attention_scorer.py) | Python Module | Attention scoring reference algorithm |
| [`DistractionLogicSystem.m`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/DistractionLogicSystem.m) | MATLAB System Object | Simulink logic engine applying threshold bounds and timers |
| [`driver_monitor_sim_distraction.slx`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S2_Distraction/driver_monitor_sim_distraction.slx) | Simulink Model | Real-time distraction state machine model |

---

## 5. Simulink Model Screenshots & Results

### Simulink Model Architecture
- **Full Model Overview:** [S2 Distraction Simulink Model](../../Graph/Simulink_Screenshots/03_s2_distraction_model.png)
- **Subsystem Close-up:** [Distraction Detection Logic Subsystem](../../Graph/Simulink_Screenshots/01_subsystem_DRIVER_DISTRACTION_DETECTION.png)

### Performance & Validation Plots
- **Confusion Matrix:** [S2 Confusion Matrix](../../Graph/5_S2_Confusion_Matrix.png) (91.8% accuracy distinguishing Attentive vs. Distracted head poses)
- **Signal Dynamics:** [S2 Distraction Feature Plot](../../Graph/FIG2_S2_Distraction_Final.png) (Yaw/Pitch angular deviations and alert triggers)

---

## 6. Execution Commands

### Prerequisites
```powershell
pip install -r ../../requirements.txt
```

### Standalone Python Head Pose Node
```powershell
cd "SECTIONS\S2_Distraction"

# Run head pose diagnostic tool:
python head_pose_diagnostic.py

# Run eye gaze diagnostic tool:
python gaze_diagnostic.py
```

### Simulink Distraction Model Execution
1. Open MATLAB and navigate to `SECTIONS/S2_Distraction`.
2. Add necessary folders to path:
   ```matlab
   addpath(pwd);
   ```
3. Open and run the model:
   ```matlab
   open_system('driver_monitor_sim_distraction.slx');
   set_param('driver_monitor_sim_distraction', 'SimulationCommand', 'start');
   ```

---

## 7. Limitations & Troubleshooting

- **Extreme Head Turn Occlusion:** When the driver turns their head beyond $\pm 75^\circ$, one side of the face becomes fully occluded, degrading PnP accuracy. The system marks tracking confidence as low and falls back to holding the last valid state.
- **Eyeglasses Distortion:** Strong prescription lenses can distort iris landmark detection, producing noisier gaze estimates. In these cases, the head-pose metric acts as the primary distraction indicator.
- **Coordinate System Orientation:** MediaPipe coordinates use an inverted Y-axis relative to standard camera projections. Inverted pitch values are mathematically corrected in `head_pose.py`.
