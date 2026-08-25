# Results & Validation

This section presents the visual and programmatic evidence validating the prototype system.

## Validation Approach
- **What was tested:** The algorithmic correctness of the EAR calculation, head pose detection, face recognition embeddings, and UDP state transmission.
- **How it was tested:** Through automated unit tests, programmatic data simulation, and Software-In-the-Loop (SIL) testing in MATLAB/Simulink.
- **Automated Results:** The core Python modules (MediaPipe, SFace) were unit tested.
- **Synthetic Results:** Plotted data represents programmatic validation (synthetic streams) designed to emulate physical constraints and verify state machine triggers. 
- **What has not yet been tested:** Real-world physical deployment on Raspberry Pi, live on-road human-driver accuracy metrics, and Edge AI thermal/framerate profiling.

## Validation Visuals

### Task 1: Drowsiness
- [EAR Behavior over Time](Task1_Drowsiness/01_EAR_behavior.png)
- [MAR Behavior over Time](Task1_Drowsiness/02_MAR_behavior.png)

### Task 2: Distraction
- [Head Pose (Yaw) Validation](Task2_Distraction/01_head_pose.png)

### Task 3: Driver Identification
- [Similarity Scores over Time](Task3_Driver_Identification/01_similarity_scores.png)

### System Integration
- [UDP 11-Value Packet Stream](Final_Integration/01_udp_11_values.png)

*All visualizations labeled "Synthetic / Programmatic Validation" are generated from exact simulated conditions reflecting the validated logic.*
