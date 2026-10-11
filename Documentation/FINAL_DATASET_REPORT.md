# AI-Based Driver Behavior Monitoring — Final Dataset Report

## 1. Executive Summary

This report documents the experimental dataset evaluation for all three project sections.
Following a strict scientific audit, it is determined that **DATASET VALIDATION IS INCOMPLETE** because the requirement of >=1,000 genuine real dataset samples with ground truth was not met for all sections. 

## 2. Dataset Acquisition & Classification

### Section 1 (Drowsiness)
- **Status:** **DEMO / FUNCTIONAL VALIDATION**
- We utilized the `demo_new.mp4` reference video (1,652 frames).
- **Limitation:** This is a demonstration video without ground-truth labels. Final labeled-dataset validation (e.g., UTA-RLDD) is pending.

### Section 2 (Distraction)
- **Status:** **DEMO / FUNCTIONAL VALIDATION**
- We utilized the `demo.mp4` reference video (1,864 frames).
- **Limitation:** This is a demonstration video without ground-truth labels. Final labeled-dataset validation (e.g., State Farm) is pending.

### Section 3 (Driver Identification)
- **Status:** **PRELIMINARY DATASET-BASED VALIDATION**
- We acquired the **Labeled Faces in the Wild (LFW)** dataset. 
- **Enrollment/Test Split:** Distinct images of the same individuals were used. (20 images per identity for enrollment, the remaining for testing).
- **Limitation:** Only 359 test samples were processed, which is below the 1,000 sample requirement. Furthermore, LFW is a generic face recognition dataset, not a driver-specific dataset.

### Datasets Requiring Manual Authentication
To run the evaluation on Kaggle-gated datasets, you must authenticate manually:
1. **State Farm Distracted Driver Dataset**
   - *Requirement:* Kaggle account + Rules acceptance
   - *Action:* Run `kaggle competitions download -c state-farm-distracted-driver-detection`
2. **UTA-RLDD (Drowsiness)**
   - *Requirement:* Kaggle account
   - *Action:* Run `kaggle datasets download -c uta-rldd`

## 3. Section 1 (Drowsiness) Results
- **Frames Processed:** 1,652
- **Faces Successfully Detected:** 1,619 (98.0%)
- **Data Gap Resolved:** Previously, the `sample_drowsy.mp4` only yielded 10 valid face detections. The new reference dataset gives a near-complete time series for MATLAB evaluation.

## 4. Section 2 (Distraction) Results
- **Frames Processed:** 1,864
- **Faces Successfully Detected:** 1,864 (100%)
- **Data Gap Resolved:** We now have continuous pose estimation (yaw, pitch, roll) across all 1,864 frames.

## 5. Section 3 (Identification) Validation Metrics
On the **Labeled Faces in the Wild** dataset:
- **Total Test Samples:** 359 images
- **Face Detections (SFace bounding box):** 116 images
- **Detection Rate:** 116 / 359 = 32.31%
  *(Note: MediaPipe Face Landmarker expects full head context and often rejects heavily cropped LFW faces).*

**Recognition Metrics (calculated ONLY on the 116 successfully detected faces):**
- **Recognition Accuracy on Detected Faces:** 100.0%
- **Overall Test Accuracy (including detection failures):** 32.31%

## 6. PC vs. Raspberry Pi Performance Gap

**Status:** **SYSTEM PERFORMANCE MEASUREMENT (PC)** / **PROJECTION (Raspberry Pi)**
- **PC FPS:** The processing pipeline consistently maintained ~40-60 FPS with CPU utilization around 10-15%.
- **Raspberry Pi Projection:** On a Raspberry Pi 4/5, expect MediaPipe inference to drop to **5-12 FPS**, with CPU utilization >85%. Do NOT assume PC latencies will hold true in Edge deployment.

## 7. FINAL VERDICT
**DATASET VALIDATION INCOMPLETE**
- `Driver_Monitoring_Master_Dataset.xlsx` (with 9 dedicated sheets and full time-series)
- `Section1_Drowsiness_Results.csv`
- `Section2_Distraction_Results.csv`
- `Section3_Identification_Results.csv`
- MATLAB Export `.mat` files generated via `export_matlab_dataset.m`
- Evaluation Waveform Graphs in `results/`
