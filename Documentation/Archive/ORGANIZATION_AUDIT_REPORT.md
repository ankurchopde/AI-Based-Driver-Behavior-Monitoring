# ORGANIZATION AUDIT REPORT

## 1. WHAT CURRENTLY EXISTS
Total Files: 59457

## 2. DUPLICATE DATASETS & MODELS
Duplicate .onnx Set (Hash: 8404d6d0):
  - AI-Based-Driver-Behavior-Monitoring\Section1_Drowsiness\fan2_68_landmark.onnx
  - AI-Based-Driver-Behavior-Monitoring\Section2_Distraction\fan2_68_landmark.onnx
  - Section1_Drowsiness\fan2_68_landmark.onnx
  - Section2_Distraction\fan2_68_landmark.onnx
  Action: KEEP ALL (Zero Deletion Rule)

Duplicate .onnx Set (Hash: 0ba9fbfa):
  - AI-Based-Driver-Behavior-Monitoring\Section3_Driver_Identification\models\face_recognizer_fast.onnx
  - dataset\section3_identification\eval_db\models\face_recognizer_fast.onnx
  - dataset\section3_identification\eval_db_real\models\face_recognizer_fast.onnx
  - dataset\section3_identification\eval_db_real_final\models\face_recognizer_fast.onnx
  - FINAL_AI_Driver_Monitoring\Models\face_recognizer_fast.onnx
  - models\identification\face_recognizer_fast.onnx
  - Section_3_Driver_Identification\models\face_recognizer_fast.onnx
  Action: KEEP ALL (Zero Deletion Rule)

Duplicate .csv Set (Hash: 2c537810):
  - Section1_Drowsiness\EAR_calibration_data.csv
  - Section2_Distraction\EAR_calibration_data.csv
  Action: KEEP ALL (Zero Deletion Rule)

Duplicate .csv Set (Hash: 45d379c9):
  - Section1_Drowsiness\EAR_calibration_data_v2.csv
  - Section2_Distraction\EAR_calibration_data_v2.csv
  Action: KEEP ALL (Zero Deletion Rule)


## 3. PROPOSED ORGANIZATION (TO BE EXECUTED IN PHASE 2)
```text
AI based Driver Detector/
├── 01_Source/
│   ├── S1_Drowsiness/
│   ├── S2_Distraction/
│   └── S3_Identification/
├── 02_Data/
├── 03_Models/
├── 04_Results/
├── 05_Simulink/
└── ...
```
*Note: Existing functional hierarchies like `Section1_Drowsiness` will be preserved if moving them breaks Simulink, or gently restructured with path updates.*