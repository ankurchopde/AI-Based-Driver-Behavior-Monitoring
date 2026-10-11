# Final Waveform to Data Mapping

| Section | Waveform | CSV Column | Data Source | Unit |
| ------- | -------- | ---------- | ----------- | ---- |
| 1. Drowsiness | EAR vs Frame | `EAR` | `Section1_Drowsiness_Results.csv` | Ratio |
| 1. Drowsiness | MAR vs Frame | `MAR` | `Section1_Drowsiness_Results.csv` | Ratio |
| 1. Drowsiness | Eye State vs Frame | `Eye_State` | `Section1_Drowsiness_Results.csv` | Binary (0/1) |
| 1. Drowsiness | PERCLOS vs Frame | `PERCLOS` | `Section1_Drowsiness_Results.csv` | Ratio (Percentage) |
| 1. Drowsiness | Drowsiness Prediction vs Frame | `Drowsiness_Prediction` | `Section1_Drowsiness_Results.csv` | Binary (0/1) |
| 2. Distraction | Head Yaw vs Frame | `Head_Pose_Yaw` | `Section2_Distraction_Results.csv` | Degrees |
| 2. Distraction | Head Pitch vs Frame | `Head_Pose_Pitch` | `Section2_Distraction_Results.csv` | Degrees |
| 2. Distraction | Hands On Steering vs Frame | `Hands_On_Steering` | `Section2_Distraction_Results.csv` | Binary (0/1) |
| 2. Distraction | Distraction Prediction vs Frame | `Distraction_Prediction` | `Section2_Distraction_Results.csv` | Binary (0/1) |
| 3. Identification | ID Confidence vs Frame | `Identification_Confidence` | `Section3_Identification_Results.csv` | Probability [0,1] |
| Performance | Processing Time vs Frame | `Processing_Time_ms` | `Driver_Monitoring_All_Sections.csv` | ms |
| Performance | CPU Usage vs Frame | `CPU_Usage_Percent` | `Driver_Monitoring_All_Sections.csv` | Percentage |
| Performance | RAM Usage vs Frame | `RAM_Usage_MB` | `Driver_Monitoring_All_Sections.csv` | MB |
| Performance | Pipeline FPS vs Frame | `FPS` | `Driver_Monitoring_All_Sections.csv` | Frames/sec |
