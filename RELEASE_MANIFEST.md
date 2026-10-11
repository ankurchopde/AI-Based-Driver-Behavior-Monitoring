# Release Manifest — AI-Based Driver Behavior Monitoring System

**Release Version:** `v1.0.0-Release`  
**Date:** October 2026  
**Target Repository:** `ankurchopde/AI-Based-Driver-Behavior-Monitoring`  
**Branch:** `main`

---

## 1. Executive Summary & Safety Scope

This release contains the complete, production-ready implementation of the **AI-Based Driver Behavior Monitoring System**, developed as an academic engineering project. The repository integrates computer-vision, deep-learning, and edge-telemetry algorithms to detect driver fatigue, distraction, and identity.

> [!IMPORTANT]
> **Safety Scope Boundary:** This system monitors driver behavior and generates deterministic warning telemetry. It does **not** implement automated vehicle actuation, steering control, acceleration, braking, or autonomous driving functions.

---

## 2. Subsystem Architecture

### Section 1 (S1) — Driver Drowsiness Detection
* **Author / Attribution:** Section 1 architecture was authored by **Tanmaygt1** ([GitHub: @Tanmaygt1](https://github.com/Tanmaygt1)).
* **Core Metrics:** Eye Aspect Ratio (EAR) using 6 facial landmarks per eye; Mouth Aspect Ratio (MAR) using 4 lip landmarks.
* **Temporal Logic:** 2.0-second persistence filter differentiating natural blinks from micro-sleeps.
* **Model Baseline:** Trained lightweight Decision Tree classifier achieving 99.68% accuracy on UTA-RLDD dataset features.

### Section 2 (S2) — Driver Distraction & Attention Detection
* **Gaze Orientation:** Iris offset tracking relative to eye inner and outer canthi.
* **Head Pose Estimation:** Perspective-n-Point (PnP) solver tracking Euler angles (Yaw, Pitch, Roll).
* **Hands-on-Wheel Monitoring:** Hand landmarker tracking hand proximity to steering rim.
* **Multi-Cue Distraction Logic:** Evaluates compound distraction states across head, gaze, and hand telemetry.

### Section 3 (S3) — Driver Identification
* **Face Alignment & Landmarking:** MediaPipe Tasks FaceLandmarker for robust facial bounding and landmark localization.
* **Feature Extraction:** OpenCV DNN SFace (`face_recognizer_fast.onnx`, 38.69 MB) generating 128-dimensional L2-normalized deep metric embeddings.
* **Verification Logic:** Cosine similarity comparison with configurable margin thresholding.
* **Temporal Stabilization:** 10-frame majority voting state machine preventing identity flickering during head motion.

---

## 3. Integrated Telemetry & Simulink Bridge

* **Telemetry Format:** Python UDP Bridge broadcasts 11 double-precision values (`<11d`, 88 bytes) at 20.5 Hz over UDP port 5000:
  `[timestamp, ear, mar, yaw, pitch, roll, gaze_x, gaze_y, hands_on_wheel, id_score, driver_id]`
* **Simulink Integration:**
  - `INTEGRATED_SYSTEM/Simulink/driver_monitor_sim_distraction.slx`: Real-time dashboard receiving UDP packets.
  - S-function UDP receiver block with zero-backlog non-blocking socket handling.
  - Multi-panel scope visualizations display real-time driver state, attention level, and alert conditions.
* **Edge AI Roadmap:** Supports headless execution (`--headless`) targeted for future deployment on Raspberry Pi 4/5 hardware.

---

## 4. Repository Directory Structure

```
.
├── .gitignore                                # Strict exclusion rules for datasets & private embeddings
├── LICENSE                                   # MIT License
├── README.md                                 # Comprehensive technical manual and guides
├── RELEASE_MANIFEST.md                       # This document
│
├── INTEGRATED_SYSTEM/                        # Real-time integrated monitoring system
│   ├── README.md                             # Integration execution guide
│   ├── Python_UDP_Bridge/                    # 11-channel UDP telemetry broadcaster
│   │   ├── master_driver_monitor_udp.py      # Master edge broadcast script
│   │   ├── Task3C_Enrollment.py              # S3 enrollment module
│   │   ├── Task3D_Recognition_Core.py        # S3 recognition engine
│   │   ├── Task3E_Confidence_Logic.py        # S3 confidence evaluator
│   │   └── Task3F_Temporal_Filter.py         # S3 temporal stabilizer
│   └── Simulink/                             # Simulink models & verification harnesses
│       ├── driver_monitor_sim_distraction.slx # Complete integrated Simulink model
│       ├── SteeringWheelDashboard.m          # Virtual steering wheel UI
│       └── UDPReceiverSystemDistraction.m    # UDP receiving block
│
├── SECTIONS/                                 # Subsystem source modules
│   ├── S1_Drowsiness/                        # Drowsiness detection algorithms & calibration
│   ├── S2_Distraction/                       # Distraction, gaze, and head pose algorithms
│   └── S3_Driver_Identification/             # Face recognition, enrollment & unit tests
│
├── PROJECT/                                  # Project assets, models & pipelines
│   ├── Models/                               # Canonical tracked model assets
│   │   ├── drowsiness/                       # Trained drowsiness classifiers (.mat)
│   │   ├── distraction/                      # Trained distraction classifiers (.mat)
│   │   ├── identification/                   # SFace ONNX model (face_recognizer_fast.onnx)
│   │   └── external_backends/                # MediaPipe task models (face_landmarker.task)
│   ├── Dataset_Pipeline/                     # Offline dataset processing & manifests
│   ├── Results_Generation/                   # Graph & CSV result generators
│   └── Tools/Robustness/                     # Lighting robustness testing scripts
│
├── Graph/                                    # Architectural diagrams & screenshots
│   ├── architecture.png                      # Verified end-to-end system architecture
│   └── Simulink_Screenshots/                 # Model screenshots from actual Simulink build
│
├── Results/                                  # Experimental results & benchmark CSVs
│   ├── CSV/                                  # Consolidated results tables
│   ├── Graphs/                               # Evaluation plots & ROC curves
│   └── Summary/                              # Metric summaries and tabular logs
│
└── Documentation/                            # Academic project reports & references
    ├── FINAL_COMPLETE_PROJECT_REPORT.md      # Comprehensive academic project report
    └── ARCHITECTURE_SPECIFICATION.md         # Detailed hardware/software architecture spec
```

---

## 5. Model Asset Integrity

| Model File | Path | Size | Description |
|:---|:---|:---|:---|
| `face_landmarker.task` | `PROJECT/Models/external_backends/` | 3.58 MB | MediaPipe 468-point 3D facial landmark model |
| `face_recognizer_fast.onnx` | `PROJECT/Models/identification/` | 38.69 MB | OpenCV SFace deep metric embedding model |
| `drowsiness_model.mat` | `PROJECT/Models/drowsiness/` | 16.5 KB | Trained decision tree drowsiness classifier |
| `distraction_model.mat` | `PROJECT/Models/distraction/` | 16.8 KB | Trained decision tree distraction classifier |
| `hand_landmarker.task` | `SECTIONS/S2_Distraction/` | 7.46 MB | MediaPipe hand keypoint tracking model |

---

## 6. Verification & Test Suite Summary

All unit tests and compilation checks have been executed and verified in this release:

1. **Bytecode Syntax Compilation:**
   - 44 Python scripts across all folders compiled cleanly via `python -m py_compile` with zero errors.
2. **Task 3C Enrollment Tests (`test_Task3C.py`):**
   - Single face valid enrollment: **PASS**
   - Blurry image rejection: **PASS** (variance threshold)
   - Multi-face rejection: **PASS**
   - Driver registry overwrite & multi-driver handling: **PASS**
3. **Task 3D Recognition Core Tests (`test_Task3D.py`):**
   - Known driver match score 1.000: **PASS**
   - Unknown driver separation: **PASS**
   - Non-face & poor quality graceful degradation: **PASS**
4. **Task 3E Confidence Logic Tests (`test_Task3E.py`):**
   - High-confidence known driver identification: **PASS**
   - Unknown driver threshold check: **PASS**
   - Low margin ambiguity detection: **PASS**
5. **Task 3F Temporal Stabilizer Tests (`test_Task3F.py`):**
   - 10-frame consecutive confirmation: **PASS**
   - Transient single-frame noise rejection: **PASS**
   - Stable identity preservation: **PASS**
6. **Task 3H UDP Telemetry Tests (`test_Task3H.py`):**
   - 88-byte binary packet packing & unpacking: **PASS**
   - Broadcast rate verified at strictly 20.5 Hz: **PASS**
   - Non-blocking socket operation with zero packet backlog: **PASS**

---

## 7. Pruned & Excluded Items

To ensure a lightweight release conforming to GitHub best practices and privacy standards:
- **Pruned Dead Weights:**
  - Removed duplicate 48.5 MB `fan2_68_landmark.onnx` models from S1 and S2 (saved 97 MB).
  - Removed third-party `reference/` videos and gifs (saved 23.5 MB).
  - Removed 17 MB `repository_inventory.csv` historical audit dump.
  - Removed 6 MB `Python_Execution_Log.txt` terminal log dump.
  - Removed internal docx templates and refactoring utilities.
- **Excluded by `.gitignore`:**
  - Raw video dataset archives (`dataset/`, `database/`, `mock_test_database/`).
  - Driver biometric embeddings (`embeddings.npy`, `**/embeddings.npy`).
  - MATLAB Simulink cache folders (`slprj/`, `_sfprj/`).
  - Python compiler caches (`__pycache__/`, `*.pyc`).

Total repository size is reduced to approximately **45 MB**, well within GitHub's standard limits.
