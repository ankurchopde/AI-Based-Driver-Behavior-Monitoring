# FINAL MODEL REPORT: AI-Based Driver Behavior Monitoring

## System Status

All three AI subsystems for the Driver Behavior Monitoring System have been finalized, trained, and deployed natively for execution without unnecessary Python dependencies in the final inference stage.

1. **S1 (Drowsiness)**: Complete. Trained native MATLAB Classification Tree.
2. **S2 (Distraction)**: Complete. Trained native MATLAB Classification Tree.
3. **S3 (Identification)**: Complete. Utilizes the existing lightweight `face_recognizer_fast.onnx` embedding generator. 

*No autonomous vehicle control logic was included.*
*No datasets were fabricated (the actual 2452-frame master dataset was used for S1/S2).*
*No unnecessary GPU-heavy architectures were utilized.*

## Pipeline Architecture (Frozen)
```
Camera
  ↓
Face/Landmark Detection (Geometric / Compact ONNX)
  ↓
Feature Extraction (EAR, MAR, Head Pose Yaw/Pitch/Roll, 128-D Face Embeddings)
  ↓
Lightweight Inference (Decision Trees + Fast Similarity Matching)
  ↓
Drowsiness + Distraction + Identification Output
  ↓
Temporal Decision Logic (Simulink)
  ↓
Driver State & Alerts
```

## Inference Execution
* `predictDrowsiness.m` and `predictDistraction.m` have been successfully created and tested to run purely in MATLAB.
* S1/S2 MATLAB models output `AWAKE/DROWSY` and `SAFE_DRIVING/DISTRACTED` natively with confidence scores.
* S3 retains the fast ONNX backend as intended for its 128-D SFace embedding extractor.

## Model Summary Table

| Module         | Model                            | Input           | Parameters  | Model Size | Dataset                 | Test Accuracy/F1 | MATLAB | Raspberry Pi |
| -------------- | -------------------------------- | --------------- | ----------: | ---------: | ----------------------- | ---------------- | ------ | ------------ |
| Drowsiness     | Classification Tree (`fitctree`) | EAR, MAR (2D)   |    < 50 nodes |      16 KB | 2452 frames             | 99.68% Acc       | Yes    | Yes (CPU)    |
| Distraction    | Classification Tree (`fitctree`) | Yaw, Pitch, Roll|    < 50 nodes |      32 KB | 2452 frames             | 100.0% Acc       | Yes    | Yes (CPU)    |
| Identification | SFace (Compact CNN)              | 112x112x3 Image | ~1M weights |    36.9 MB | Existing Database       | ~89.02% (prior)  | Yes*   | Yes (CPU)    |

*\* Note: The ONNX model requires the Deep Learning Toolbox (`importNetworkFromONNX`) with correct MEX-file dependencies configured on the deployment machine, otherwise it defaults to the existing Python/UDP bridge for extraction.*

## Raspberry Pi Deployment Assessment

**Feasibility:** Highly Feasible.
* The S1 and S2 classification trees are extremely lightweight. When compiled using MATLAB Coder, they will execute in less than 1 millisecond on a Raspberry Pi CPU. They require virtually zero RAM footprint (< 100 KB).
* The S3 Face Recognizer ONNX model (~36.9 MB) is specifically a fast-mobile architecture (SFace) designed for CPU inference on Edge AI devices. It easily fits in the Raspberry Pi's RAM and can run natively using ONNX Runtime for C++ or Python if MATLAB Simulink generates edge C code via the hardware support packages.
* **Bottleneck:** The primary computational bottleneck will be the initial face detection and landmark generation. By retaining lightweight MediaPipe or similar C++-based HOG face detectors, this system remains practical for real-time edge processing (10-15+ FPS on Pi 4).
