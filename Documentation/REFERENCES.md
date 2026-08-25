# Project References & Scientific Literature

This document lists the foundational algorithms, research papers, and technical documentation used to design and validate the AI-Based Driver Behavior Monitoring system.

## 1. Drowsiness Detection (EAR / MAR)

**Real-Time Eye Blink Detection using Facial Landmarks**
- **Authors:** Tereza Soukupová and Jan Čech (2016)
- **URL:** [Semantic Scholar](https://www.semanticscholar.org/paper/Real-Time-Eye-Blink-Detection-using-Facial-Soukupov%C3%A1-%C4%8Cech/235a9f604471f54313f8de174f85e50db32e92bc)
- **Usage in Project:** This paper is the primary source for the Eye Aspect Ratio (EAR) metric used in Task 1. We adapted the EAR calculation to operate on 3D landmarks provided by MediaPipe rather than standard 2D dlib landmarks.

## 2. Facial Landmark & Pose Tracking

**MediaPipe Face Landmarker**
- **Source:** Google AI Edge Documentation
- **URL:** [MediaPipe Vision Solutions](https://developers.google.com/mediapipe/solutions/vision/face_landmarker)
- **Usage in Project:** Provided the 468 dense 3D facial landmarks and blendshapes used for both Task 1 (Drowsiness) and Task 2 (Distraction/Head Pose). Used for robust, real-time edge processing.

**Perspective-n-Point (SolvePnP)**
- **Source:** OpenCV Documentation
- **URL:** [OpenCV Camera Calibration and 3D Reconstruction](https://docs.opencv.org/4.x/d9/d0c/group__calib3d.html)
- **Usage in Project:** Used in Task 2 to convert 2D facial landmarks into 3D head pose estimation (Yaw, Pitch, Roll) using a standard 3D generic face model.

## 3. Driver Identification

**SFace: Sigmoid-Constrained Hypersphere Loss for Robust Face Recognition**
- **Authors:** Yaoyao Zhong, Weihong Deng, Jiani Hu, Dongyue Zhao, Xian Li, Dongqi Wen (2021)
- **URL:** [arXiv:2104.11367](https://arxiv.org/abs/2104.11367) / [OpenCV Zoo](https://github.com/opencv/opencv_zoo)
- **Usage in Project:** This lightweight, edge-optimized face recognition model was selected for Task 3 to extract facial embeddings. It operates in real-time while maintaining strong discrimination margins.

## 4. System Integration & Control

**MATLAB and Simulink for System Simulation**
- **Source:** MathWorks Documentation
- **URL:** [MathWorks Desktop Simulation](https://www.mathworks.com/help/simulink/)
- **Usage in Project:** The entire control logic, state machines, and temporal filtering algorithms (e.g., hysteresis, debouncing) were validated using Simulink before targeting physical hardware.
