# Integrated Driver Monitoring System

[![System Architecture](../Graph/architecture.png)](../Graph/architecture.png)

## 1. Purpose of the Integrated System

The **Integrated Driver Monitoring System** unifies all three behavioral subsystems into a single, cohesive, real-time safety pipeline:
- **S1 — Drowsiness Detection:** Eye Aspect Ratio (EAR), blink persistence, Mouth Aspect Ratio (MAR) yawning analysis, and PERCLOS.
- **S2 — Distraction & Attention Detection:** 3D Head Pose estimation (Yaw, Pitch, Roll) and 2D iris pupil gaze vectoring.
- **S3 — Driver Identification:** 128-dimensional biometric face embeddings, cosine similarity matching, unknown-driver lockout, and 10-frame temporal stabilization.

The integrated system operates under a strict automotive scope boundary: **driver state monitoring, risk assessment, and auditory/visual alerts only**. It does **not** perform autonomous vehicle steering, acceleration, or braking control.

---

## 2. Core Components and Responsibilities

The system is decoupled into two coordinated execution runtimes:

```
┌──────────────────────────────────────────────┐
│         Python Computer Vision Engine        │
│   (master_driver_monitor_udp.py @ 20.5 Hz)   │
│  - MediaPipe FaceMesh (468/478 Landmarks)    │
│  - SolvePnP Head Pose & Iris Gaze Tracking   │
│  - FaceNet 128-D Biometric Verification      │
│  - Adaptive CLAHE Illumination Preprocessor  │
└──────────────────────┬───────────────────────┘
                       │ UDP Socket (Port 5000, '<11d', 88 Bytes)
                       ▼
┌──────────────────────────────────────────────┐
│        MATLAB / Simulink Safety Engine       │
│  (driver_monitor_sim_identification.slx)     │
│  - Non-blocking UDP Packet Deserialization   │
│  - NaN Sentinel Missing-Face Filter          │
│  - Multi-Level Supervisory State Machine     │
│  - Real-Time Diagnostic Scopes & Telemetry   │
└──────────────────────────────────────────────┘
```

### Component Breakdown
1. **Python Vision & Telemetry Engine (`master_driver_monitor_udp.py`):**
   - High-throughput video ingestion from webcam or pre-recorded MP4/AVI videos.
   - Low-light enhancement via Adaptive CLAHE (L channel in LAB space, clip limit 2.0).
   - Multi-task feature extraction executing in under 22 ms per frame.
   - Serializes telemetry into a little-endian IEEE-754 double binary packet (`struct.pack('<11d', ...)`).
   - Injects `NaN` sentinels when face tracking is lost to prevent false zero-EAR alarms in Simulink.

2. **MATLAB / Simulink Supervisory Logic (`driver_monitor_sim_identification.slx`):**
   - Ingests UDP packets via `UDPReceiverSystemIdentification.m` at Port 5000.
   - Demultiplexes the 11 channels:
     `[Face_Detected, Mean_EAR, MAR, Yaw, Pitch, Roll, Gaze_X, Gaze_Y, Driver_ID, ID_Confidence, ID_State]`
   - Implements temporal hysteresis timers to reject fleeting blinks or shoulder checks.
   - Coordinates multi-level alert escalations: Normal (0), Caution (1), Warning (2), and Critical Drowsiness (3).

3. **Master MATLAB Evaluation Runner (`MASTER_DRIVER_MONITORING_REAL.m`):**
   - Automates batch pipeline execution across datasets.
   - Synchronizes Python outputs, parses CSV performance logs, and generates formal evaluation summaries in `results/`.

---

## 3. Architecture & Genuine Simulink Screenshots

### System Architecture
The complete data flow, from physical camera input to supervisory warnings, is documented in the system architecture diagram:
- [High-Resolution System Architecture Diagram](../Graph/architecture.png)
- [Vector Architecture Source (SVG)](../Graph/architecture.svg)
- [Architecture Flow Diagram Source (Mermaid)](../Graph/architecture.mmd)

### Genuine Model Screenshots
The following screenshots were captured directly from the verified Simulink model files (`.slx`) at 300 DPI:

| Screenshot | Description | Direct Link |
| :--- | :--- | :--- |
| **Integrated Model Overview** | Complete 11-channel Simulink model with UDP Receiver, Demux, and scopes | [View Overview](../Graph/Simulink_Screenshots/01_integrated_simulink_model.png) |
| **Distraction Detection Subsystem** | Angular thresholding logic, bounding comparators, and timers | [View Subsystem](../Graph/Simulink_Screenshots/01_subsystem_DRIVER_DISTRACTION_DETECTION.png) |
| **Supervisory State Machine** | Multi-level supervisory warning and risk escalation logic | [View State Machine](../Graph/Simulink_Screenshots/01_subsystem_State_Machine.png) |
| **Yawn Event Subsystem** | MAR thresholding integrator for yawning detection | [View Yawn Logic](../Graph/Simulink_Screenshots/01_subsystem_YAWN_EVENT.png) |
| **Blink End Detection** | Edge detector and blink persistence integrator | [View Blink Logic](../Graph/Simulink_Screenshots/01_subsystem_Detect_Blink_End.png) |
| **S1 Standalone Model** | Baseline Drowsiness Simulink model | [View S1 Model](../Graph/Simulink_Screenshots/02_s1_drowsiness_model.png) |
| **S2 Standalone Model** | Baseline Distraction Simulink model | [View S2 Model](../Graph/Simulink_Screenshots/03_s2_distraction_model.png) |

---

## 4. Dependencies & Prerequisites

### Python Environment
- Python 3.8+ (tested on Python 3.10 / 3.11)
- Install required packages:
  ```powershell
  pip install -r ../requirements.txt
  ```

### MATLAB / Simulink Environment
- MATLAB R2022b or newer with:
  - Simulink
  - DSP System Toolbox (for `dsp.UDPReceiver`)
  - Computer Vision Toolbox (optional, for offline MATLAB processing)

---

## 5. Startup Sequence & Execution Order

To prevent UDP socket timeout warnings, always start the runtimes in the following order:

```
Step 1: Launch Python Bridge (Streams UDP packets to localhost:5000)
                              ▼
Step 2: Start Simulink Model (Binds to socket and receives active stream)
```

---

## 6. Exact Execution Commands

### Mode A: Live Physical Webcam
```powershell
# 1. From the project root, navigate to the Python UDP Bridge directory:
cd "INTEGRATED_SYSTEM\Python_UDP_Bridge"

# 2. Start the live multi-task computer vision bridge:
python master_driver_monitor_udp.py --camera 0 --fps 20.0
```

### Mode B: Offline Video File Testing (Webcam-Free)
If testing without a physical webcam, pass any recorded test video:
```powershell
cd "INTEGRATED_SYSTEM\Python_UDP_Bridge"
python master_driver_monitor_udp.py --video "..\..\PROJECT\Data\Raw_Videos\test_driver.mp4" --fps 20.0
```

### Mode C: Headless Execution (Edge AI / Raspberry Pi Simulation)
To run without rendering the OpenCV display window (`cv2.imshow`):
```powershell
python master_driver_monitor_udp.py --camera 0 --headless --fps 20.0
```

### Mode D: Running the Integrated Simulink Model
1. Open MATLAB.
2. In the MATLAB Command Window, add required folders to the path:
   ```matlab
   cd('d:\Academics\TY_SEM1\AE\AI based Driver Detector');
   addpath(genpath('SECTIONS'));
   addpath(genpath('INTEGRATED_SYSTEM'));
   ```
3. Open and run the integrated model:
   ```matlab
   open_system('SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx');
   set_param('driver_monitor_sim_identification', 'SimulationCommand', 'start');
   ```

### Mode E: Batch Evaluation Runner
To execute the automated MATLAB evaluation pipeline across all test logs:
```matlab
cd('d:\Academics\TY_SEM1\AE\AI based Driver Detector\INTEGRATED_SYSTEM');
MASTER_DRIVER_MONITORING_REAL
```

---

## 7. Model, Configuration, and Result Artifacts

- **MediaPipe Landmark Model:** `PROJECT/Models/external_backends/face_landmarker.task`
- **FaceNet ONNX Model:** `PROJECT/Models/identification/face_recognizer_fast.onnx`
- **Authorized Driver Database:** `SECTIONS/S3_Driver_Identification/database/` (contains `registry.json`)
- **Simulink Model:** `SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx`
- **Presentation Graphs:** `Graph/` and `results/visuals/`
- **CSV Evaluation Summaries:** `results/Summary/`

---

## 8. Common Errors and Troubleshooting

| Symptom / Error | Root Cause | Solution |
| :--- | :--- | :--- |
| `Address already in use` | Another process is holding UDP Port 5000 | Terminate orphaned Python or MATLAB instances, or restart MATLAB. |
| `Could not open camera/video` | Camera 0 is in use by another app or index is invalid | Close video conferencing tools (Teams, Zoom); try `--camera 1`. |
| `face_landmarker.task not found` | Relative path error when running from nested folder | Ensure command is executed with working directory at `INTEGRATED_SYSTEM/Python_UDP_Bridge`. |
| Simulink displays all zeros | Simulink was started before the Python stream began | Stop Simulink, launch Python bridge, verify frames are processing, then restart Simulink. |
| Scope shows spikes to 0 when face is lost | Historical code sent `0.0` for EAR on face loss | Verify latest `master_driver_monitor_udp.py` is in use; it transmits `NaN` to maintain previous state. |
| `DistractionLogicSystem not found` | MATLAB path missing `SECTIONS/S2_Distraction` | Run `addpath(genpath('SECTIONS'))` in MATLAB before loading model. |
