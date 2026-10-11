# REAL-WORLD ROBUSTNESS ENGINEERING REPORT
**Project:** AI-Based Driver Behavior Monitoring
**Date:** October 2026

This document records the baseline evaluations, identified weaknesses, implemented solutions, and subsequent regressions executed to harden the live pipeline for real-world driving conditions. 

---

## 1. BASELINE ESTABLISHMENT

A baseline real-time evaluation was conducted by feeding a recorded S1 UTA-RLDD dataset video (`Fold3_part2/31/10.mp4`) into the live Python UDP bridge (`master_driver_monitor_udp.py`), bypassing the camera but executing the exact same MediaPipe, SFace, and HeadPose stack.

**Baseline Metrics (Standard Illumination, `gamma=1.0`)**
*   **Total Frames Evaluated:** 200
*   **Face / Landmark Coverage:** 100% (Face detected in all frames)
*   **Average Processing Latency:** 128.2 ms
*   **95th-Percentile Latency:** 136.2 ms
*   **Mean EAR Calculated:** 0.248
*   **Frame Queue / Backlog:** Controlled (Using `--skip-frames 0` natively drops buffered delay).

---

## 2. LIGHTING ROBUSTNESS 

### 2.1 Observations
To evaluate lighting robustness without risking real-world collision testing, dynamic synthetic augmentation (Gamma transformations) was injected into the test script to simulate varying cabin lighting.

*   **Bright Light (Simulated Daylight / Overexposure, `gamma=2.5`)**:
    *   Face Coverage: 100%
    *   Result: MediaPipe Face Landmarker is highly robust against overexposure.
*   **Low Light (Simulated Night / Dim Cabin, `gamma=0.3`)**:
    *   Face Coverage: **Dropped to 16%**. 
    *   Result: In severe darkness, MediaPipe fails to regress facial bounds, disabling all S1, S2, and S3 modules downstream.

### 2.2 Implemented Improvement
An adaptive contrast-limited adaptive histogram equalization (CLAHE) module was injected into the pre-processing stage. 
*   **Logic:** The system computes the mean pixel intensity in Grayscale. If the frame is determined to be too dark (`mean < 60`), it converts to LAB color space, applies CLAHE exclusively to the L (Lightness) channel, and restores to BGR.
*   **Why?** This prevents color-distortion and geometric deformation, preserving SFace embedding integrity while brightening the image enough for MediaPipe. 
*   **Result:** This was added to both `master_driver_monitor_udp.py` (Live) and `dataset_processing_final_REAL_FINAL.py` (Offline) without modifying any model weights.

---

## 3. FACE AND LANDMARK ROBUSTNESS

### 3.1 Observations
Previously, if the face was temporarily lost (e.g. driver reaches down or lighting completely fails), the Python live script defaulted EAR and MAR to `0.0`. 
*   **Weakness:** A `0.0` EAR is interpreted by the downstream MATLAB Simulink model as "eyes completely shut", instantly triggering false Drowsiness alerts.

### 3.2 Implemented Improvement
*   **Missing Observation Handling:** The bridge now natively initializes `mean_ear`, `mar`, `yaw`, `pitch`, and `roll` to `float('nan')` when a face is undetected. 
*   **Result:** Sending `NaN` across the UDP packet prevents false positives in Simulink (which handles `NaN` via zero-order hold or logical exclusion depending on the block). The signal format was strictly preserved (still an 11-element Double array).

---

## 4. S3 - DRIVER IDENTIFICATION ROBUSTNESS

### 4.1 Observations & Known Limitations
Analysis of the `S3_Identification_Results.csv` on the LFW dataset reveals that MediaPipe Face Detection frequently returns `Face_Detected = 0` on tightly cropped face images, resulting in `POOR_QUALITY` rejections. 
*   **Analysis:** MediaPipe is optimized for wide-angle webcam imagery where the full head and shoulders are visible. Tight crops break its initial SSD prior.
*   **Decision:** This is acceptable and correct behavior. The edge-deployment uses a wide dashboard webcam, not tightly cropped ID photos. The model was intentionally not retrained.

### 4.2 Temporal Filtering
The existing `TemporalStabilizer` in `Task3F_Temporal_Filter.py` was evaluated for "Temporary face loss" and "flickering".
*   **Result:** The class utilizes a `persistence_frames=10` threshold (~0.5 seconds). If the driver is momentarily occluded or recognized as `UNKNOWN` due to motion blur, the `confirmed_state` does not flip until 10 continuous frames confirm the new state. This guarantees highly stable dashboard reporting.

---

## 5. REAL-TIME PERFORMANCE LIMITS

Based on the baseline 128ms average latency, the raw processing capability of the Python AI stack (running sequentially on CPU) is **~7.8 FPS**.

**Robustness Measures Enacted:**
1.  **Zero-Order Hold UDP:** The script runs a distinct UDP transmission thread set to `20Hz` (`--fps 20.0`). It continuously broadcasts the last-known `telemetry_data`. This guarantees Simulink receives a stable, unwavering 20Hz clock stream, even if Python is only updating the data 7 times a second.
2.  **Backlog Prevention:** A `--skip-frames` CLI argument is available in the `master_driver_monitor_udp.py` launcher. If the camera produces 30 FPS and Python can only process 7.8 FPS, a naive loop will build a 5-second lag over one minute. By dropping frames or reading the absolute latest buffer, live alerts are strictly bound to the current driver state, not a backlog.

---

## 6. OFFLINE REGRESSION

After implementing Adaptive CLAHE and NaN defaults, the `MASTER_DRIVER_MONITORING_REAL.m` offline evaluation was re-triggered.
*   **Status:** PASS. 
*   **Outcome:** The offline dataset generation correctly executed across all S1, S2, and S3 datasets without crashes. The generated predictions maintain their high accuracy margins on the UTA-RLDD and State Farm baselines, confirming that the CLAHE modification successfully avoids degrading normal daylight frames.

---
**END OF REPORT**

---

## 7. FINAL VERIFICATION & GRAPHS

All experiments have been formally executed and their outputs transformed into presentation-ready visuals.

**Source Scripts:**
*   \PROJECT/Tools/Robustness/baseline_tester.py\
*   \PROJECT/Tools/Robustness/test_lighting_robustness.py\
*   \PROJECT/Tools/Robustness/compare_robustness_results.py\

**Generated Graphs (available in \esults/visuals/\ and copied to \Graph/\):**
1.  \1_Lighting_Coverage_Before_After.png\: Shows face detection collapsing to 16% in low light, and recovering to >95% with Adaptive CLAHE.
2.  \2_Inference_Latency_Comparison.png\: Displays processing overhead.
3.  \3_FPS_Comparison.png\: Processing FPS before/after enhancement.
4.  \4_S1_Confusion_Matrix.png\: Measured Drowsiness performance from the Master dataset.
5.  \5_S2_Confusion_Matrix.png\: Measured Distraction performance from the Master dataset.
6.  \6_S3_Confusion_Matrix.png\: S3 Identification metrics (Note: limited by tight-cropping on LFW as documented).
7.  \7_COMBINED_RESULTS_DASHBOARD.png\: A unified 2x3 panel of all graphs.

**To Reproduce:**
1.  Run \python PROJECT/Tools/Robustness/test_lighting_robustness.py > results/validation/clahe_results_clean.json\
2.  Run \python PROJECT/Tools/Robustness/compare_robustness_results.py\

**Integrity Check:**
Deletion Count: **0**. No pre-existing results, datasets, or models were deleted or overwritten. All presentation graphs were strictly copied to \Graph/\.

