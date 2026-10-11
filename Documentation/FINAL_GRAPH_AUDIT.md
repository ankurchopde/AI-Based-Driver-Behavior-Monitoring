# FINAL GRAPH AUDIT

## Section 1: Drowsiness
**Source CSV:** `Section1_Drowsiness_Results.csv` (1,652 samples)
- **EAR Distribution (`S1_EAR_Distribution.png`):** Generated from `EAR` column. Represents **DEMO DATA**, not benchmark dataset.
- **MAR Distribution (`S1_MAR_Distribution.png`):** Generated from `MAR` column. Represents **DEMO DATA**.
- **PERCLOS (`S1_PERCLOS.png`):** Generated from `PERCLOS` column. Represents **DEMO DATA**.
- **Drowsiness State (`S1_Drowsiness_State.png`):** Generated from `Drowsiness_Prediction` column. Represents **DEMO DATA**.

## Section 2: Distraction
**Source CSV:** `Section2_Distraction_Results.csv` (1,864 samples)
- **Head Pose (`S2_Head_Pose.png`):** Generated from `Head_Pose_Yaw`, `Head_Pose_Pitch`, `Head_Pose_Roll` columns. Represents **DEMO DATA**.
- **Distraction Prediction (`S2_Distraction_Prediction.png`):** Generated from `Distraction_Prediction` column. Represents **DEMO DATA**.

## Section 3: Identification
**Source CSV:** `Section3_Identification_Results.csv` (359 samples)
- **Confusion Matrix / Metrics:** Generated from `Driver_ID_GroundTruth` vs `Driver_ID_Prediction`. Represents **DATASET-BASED VALIDATION** (but sample size < 1,000).

## Performance (All Sections)
- **CPU / RAM / Processing Time:** Represents **SYSTEM PERFORMANCE MEASUREMENT** on **PC Hardware**, NOT Raspberry Pi.
