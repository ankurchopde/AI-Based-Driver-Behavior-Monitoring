# FINAL CSV AUDIT

## Section 1: Drowsiness
**File:** `Section1_Drowsiness_Results.csv`
- **Source:** `demo_new.mp4` (Functional Demo Video, NOT a labeled research dataset).
- **Rows (Samples):** 1,652
- **Columns:** 20
- **Important Non-NaN Counts:**
  - `Face_Detected`: 1652
  - `EAR`: 1619
  - `MAR`: 1619
  - `PERCLOS`: 1652
  - `Drowsiness_GroundTruth`: 0 (Ground truth unavailable in demo video)
  - `Drowsiness_Prediction`: 1619
  - `Processing_Time_ms`: 1652
- **Classification:** **DEMO / FUNCTIONAL VALIDATION** (No ground truth available).

## Section 2: Distraction
**File:** `Section2_Distraction_Results.csv`
- **Source:** `demo.mp4` (Functional Demo Video, NOT a labeled research dataset).
- **Rows (Samples):** 1,864
- **Columns:** 25
- **Important Non-NaN Counts:**
  - `Face_Detected`: 1864
  - `Head_Pose_Yaw`: 1864
  - `Distraction_GroundTruth`: 0 (Ground truth unavailable in demo video)
  - `Distraction_Prediction`: 1864
  - `Hands_On_Steering`: 0 (Hands not detected on wheel)
  - `Phone_Use` / `Eating_Drinking`: 0
- **Classification:** **DEMO / FUNCTIONAL VALIDATION** (No ground truth available).

## Section 3: Identification
**File:** `Section3_Identification_Results.csv`
- **Source:** Labeled Faces in the Wild (LFW)
- **Rows (Test Samples):** 359
- **Columns:** 15
- **Important Non-NaN Counts:**
  - `Face_Detected`: 359 (116 successfully extracted by SFace, rest failed bounding box)
  - `Driver_ID_GroundTruth`: 359
  - `Driver_ID_Prediction`: 116
- **Classification:** **DATASET-BASED VALIDATION (PRELIMINARY)**
- **Limitations:** Only 359 test samples were evaluated, which is `< 1,000`. LFW is a generic face dataset, not driver-specific.
