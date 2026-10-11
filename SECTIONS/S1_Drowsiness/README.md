# Section 1: Driver Drowsiness Detection

[![S1 Drowsiness Architecture](../../DOCUMENTATION/architecture/02_task1_drowsiness_flow.png)](../../DOCUMENTATION/architecture/02_task1_drowsiness_flow.png)

> [!NOTE]
> **Academic Attribution:** The foundational architecture, core ocular calculation algorithms, and initial Simulink state models for this module (Section 1) were developed by **[Tanmaygt1](https://github.com/Tanmaygt1)**. This attribution applies exclusively to Section 1.

---

## 1. Purpose and Overview

The **Drowsiness Detection** subsystem is the foundational physiological monitoring layer of the vehicle safety system. It continuously analyzes driver facial landmarks to detect micro-sleeps, prolonged eyelid closure, and yawning events, triggering deterministic safety warnings before fatigue leads to an accident.

Under the project scope boundary, this system provides **in-cabin driver alerting only** (auditory and visual cues) and does not perform autonomous vehicle deceleration or steering.

---

## 2. Implemented Algorithms and Features

### Eye Aspect Ratio (EAR)
EAR quantifies vertical eyelid aperture relative to horizontal eye width using 6 coordinates per eye from the MediaPipe 468-point facial mesh:
$$\text{EAR} = \frac{\|p_2 - p_6\| + \|p_3 - p_5\|}{2 \|p_1 - p_4\|}$$
- **Right Eye Landmarks:** `[33, 160, 158, 133, 153, 144]`
- **Left Eye Landmarks:** `[362, 385, 387, 263, 373, 380]`
- **Operational Threshold:** $\text{EAR} < 0.20$ indicates eye closure.
- **Blink Normalization:** Averages left and right eye measurements to reject asymmetric blinks.

### Mouth Aspect Ratio (MAR) & Yawn Detection
MAR evaluates mouth opening to reliably isolate yawning from natural speech or yawning patterns:
- **Inner Lip Landmarks:** `[13, 14, 78, 308]`
- **Operational Threshold:** $\text{MAR} > 0.60$ flags an active yawn event.

### Blink Dynamics & PERCLOS
- **Blink Counter & Duration Integrator:** Distinguishes voluntary blinks (100–400 ms) from involuntary microsleeps (> 500 ms).
- **PERCLOS:** Calculates the percentage of eye closure over a rolling time window.

### Temporal Hysteresis & Filtering
Simulink implements a **2.0-second persistence timer**. The EAR must continuously remain below $0.20$ for $\ge 2.0\text{ s}$ before escalating from a normal blink to a persistent **DROWSY** alert state, preventing false positives from casual blinking.

---

## 3. Architecture & Data Flow

```
Webcam / Video Frame (640×480)
               │
               ▼
   MediaPipe Face Landmarker (468 3D Mesh)
         │                   │
         ▼                   ▼
    EAR Calculation     MAR Calculation
         │                   │
         └─────────┬─────────┘
                   ▼
     UDP Broadcast (Port 5000 / 20.5 Hz)
                   │
                   ▼
   Simulink State Machine (driver_monitor_sim.slx)
  [Blink Filter] ──> [2.0s Timer] ──> [Supervisory Alert]
```

---

## 4. Source Scripts and Models

| File | Type | Description |
| :--- | :--- | :--- |
| [`mediapipe_udp_sender.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S1_Drowsiness/mediapipe_udp_sender.py) | Python Script | Primary vision processing node and UDP transmitter |
| [`MediapipeBridge.py`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S1_Drowsiness/MediapipeBridge.py) | Python Utility | Helper wrapper managing landmark extraction |
| [`UDPReceiverSystem.m`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S1_Drowsiness/UDPReceiverSystem.m) | MATLAB System Object | Deserializes UDP datagrams in Simulink |
| [`driver_monitor_sim.slx`](file:///d:/Academics/TY_SEM1/AE/AI%20based%20Driver%20Detector/SECTIONS/S1_Drowsiness/driver_monitor_sim.slx) | Simulink Model | Real-time state machine and persistence logic |
| `face_landmarker.task` | Pretrained Model | Google MediaPipe 468-point 3D landmark model |

---

## 5. Simulink Model Screenshot & Results

### Simulink Model Architecture
A genuine 300 DPI vector capture of the Section 1 Simulink model is available at:
- **Screenshot:** [S1 Drowsiness Simulink Model](../../Graph/Simulink_Screenshots/02_s1_drowsiness_model.png)

### Performance & Validation Plots
- **Confusion Matrix:** [S1 Confusion Matrix](../../Graph/4_S1_Confusion_Matrix.png) (94.2% sensitivity on prolonged eye closures)
- **Signal Dynamics:** [S1 Drowsiness Feature Plot](../../Graph/FIG1_S1_Drowsiness_Final.png) (EAR threshold breach and 2.0s alert trip)

---

## 6. Execution Commands

### Prerequisites
```powershell
pip install -r ../../requirements.txt
```

### Standalone Python Node
```powershell
# Navigate to Section 1 directory
cd "SECTIONS\S1_Drowsiness"

# Run with live camera:
python mediapipe_udp_sender.py

# Run with recorded test video:
python mediapipe_udp_sender.py --video "..\..\PROJECT\Data\Raw_Videos\drowsy_driver.mp4"
```

### Simulink Model Execution
1. Open MATLAB and set current directory to `SECTIONS/S1_Drowsiness`.
2. Open the model:
   ```matlab
   open_system('driver_monitor_sim.slx');
   set_param('driver_monitor_sim', 'SimulationCommand', 'start');
   ```

---

## 7. Limitations & Troubleshooting

- **Lighting Sensitivity:** Deep shadows or complete darkness degrade landmark detection. The integrated system provides an Adaptive CLAHE preprocessor to mitigate this.
- **Sunglasses & Occlusion:** Dark polarized sunglasses obstruct eye landmarks, causing EAR calculation dropout. The system handles this by emitting `NaN` sentinels rather than triggering a false zero-EAR alarm.
- **Port Conflict:** If port 5000 is occupied, verify no orphaned Python background tasks are running.
