# TASK 3: DRIVER IDENTIFICATION - FINAL PROJECT REPORT

## 1. Objective
To design, implement, and integrate an AI-Based Driver Identification system into the existing Driver Monitoring project (Task 1: Drowsiness, Task 2: Distraction). The system required zero external network dependencies, high edge-compute efficiency, and strict non-interference with the existing telemetry and Simulink architectures.

## 2. Architecture
The final system extends the MediaPipe Vision pipeline utilizing the **OpenCV `FaceRecognizerSF` (SFace)** model. 
1. **Detection:** MediaPipe FaceLandmarker (Shared with Tasks 1/2)
2. **Alignment:** 5 facial keypoints extracted from the mesh and mapped to the SFace affine crop matrix.
3. **Extraction:** SFace ONNX model computes a 128-dimensional biometric embedding.
4. **Matching:** Cosine similarity compares the live embedding against an offline `database/`.
5. **Logic:** Threshold, Margin, and Temporal rules evaluate the similarity into a stable external state.

## 3. Implementation Summary
*   **Task 3C (Enrollment):** `Task3C_Enrollment.py` securely captures, validates (blur detection), and saves face embeddings directly to the local disk, updating a master `registry.json`.
*   **Task 3D (Recognition):** `Task3D_Recognition_Core.py` efficiently queries the offline database, performing real-time Cosine Distance calculations to find the closest match.
*   **Task 3E (Confidence Logic):** Evaluates the raw score against a prototype `0.363` threshold and a `0.05` margin to dynamically classify the state as `IDENTIFIED`, `UNKNOWN`, `LOW_CONFIDENCE`, or `NO_FACE`.
*   **Task 3F (Temporal Stabilization):** Buffers identity transitions through a `10-frame` state machine to strictly prevent identity flickering from anomalous or noisy frames.
*   **Task 3H (UDP Integration):** `Task3H_UDP_Sender.py` expands the native telemetry from an 8-value (64 byte) payload to an 11-value (88 byte) payload, transmitting precisely at a monotonic ~20.5 Hz without backlog.
*   **Task 3I (Simulink Integration):** `driver_monitor_sim_identification.slx` securely imports the 11-value packet, routing the new telemetry directly to distinct scopes while completely preserving the frozen drowsiness/distraction logic.

## 4. Validated Prototype Candidates
The following operational parameters govern the system. Because this project was structurally validated via synthetic/mock datasets, **these values are strictly documented as PROTOTYPE CANDIDATES**:
1. **SFace Similarity Threshold:** `0.363`
2. **Best-vs-Second-Best Margin:** `0.05`
3. **Temporal Persistence:** `10 frames` (approx. 0.5s at 20 Hz)

## 5. Raspberry Pi Feasibility
*   **PROTOTYPE / EXPECTED FEASIBILITY:** The pipeline operates entirely via local `cv2.dnn` and `mediapipe.tasks.vision`, completely avoiding heavy frameworks like TensorFlow or PyTorch. Because no native CUDA dependencies are required, and memory overhead is extremely limited, the system is expected to be highly feasible for real-time edge deployment on a Raspberry Pi 4/5. 
*   *Note: Real-world physical benchmarking on the Pi hardware was not performed in this phase.*

## 6. Limitations & Future Improvements
*   **Limitation:** The validation dataset utilized for genuine/impostor distribution (Task 3G) was artificially derived from a single human reference image.
*   **Improvement:** Conduct a physical, multi-driver data collection campaign to scientifically calibrate the False Acceptance Rate (FAR) and adjust the `0.363` Cosine threshold.
*   **Improvement:** Physically test and optimize the UDP stream latency natively on the target Raspberry Pi over Wi-Fi / Ethernet.

## 7. Final Status

All required components (3A through 3J) have been audited, documented, and logically verified. No frozen Task 1 or 2 files were corrupted or modified.

**TASK 3 — DRIVER IDENTIFICATION**
**COMPLETE / VALIDATED / FROZEN**
