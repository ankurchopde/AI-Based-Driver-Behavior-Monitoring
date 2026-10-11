# TASK 3B: FINAL DRIVER IDENTIFICATION ARCHITECTURE

## 1. Final Data Flow
The proposed pipeline ensures identification is solely reliant on vision processing without disrupting the existing system.
1. **Camera Input:** Frame captured from the existing Python webcam loop.
2. **Face Detection (MediaPipe):** The existing pipeline detects the face and provides 468 3D landmarks.
3. **Face Crop & Alignment:** Extract 5 key landmarks (eyes, nose, mouth corners) from MediaPipe's output. Compute an affine transform to crop and align the face to a standard 112x112 image.
4. **OpenCV SFace Feature Extraction:** Pass the aligned 112x112 face crop through `cv2.FaceRecognizerSF`.
5. **Face Embedding:** SFace outputs a 128-dimensional L2-normalized float32 vector.
6. **Enrollment Database Lookup:** Load all stored reference embeddings for known drivers.
7. **Similarity Matching:** Compute the Cosine Similarity between the current embedding and all database embeddings.
8. **Candidate Identity & Confidence Evaluation:** Find the best matching driver and evaluate the score against a threshold and the margin to the second-best match.
9. **Unknown / Low-Confidence Handling:** Classify the raw frame as `IDENTIFIED`, `UNKNOWN`, `LOW_CONFIDENCE`, or `NO_FACE`.
10. **Temporal Identity Stabilization:** Pass the raw frame state through a temporal filter (state machine) to prevent rapid flickering.
11. **Final Output:** Final `DRIVER_ID`, `CONFIDENCE`, and `IDENTIFICATION_STATE` are ready for UDP transmission.

## 2. SFace Integration
*   **Required Face Crop & Dimensions:** SFace expects a 112x112 pixel RGB image.
*   **Alignment Requirements:** To achieve high accuracy, the face must be aligned using a similarity transform based on 5 facial landmarks (Left Eye, Right Eye, Nose Tip, Left Mouth Corner, Right Mouth Corner).
*   **Landmark Mapping:** MediaPipe provides 468 landmarks. We will map specific MediaPipe indices (e.g., 33/263 for eyes, 1 for nose, 61/291 for mouth) to the 5 points expected by standard face aligners.
*   **Preprocessing:** `cv2.FaceRecognizerSF` performs internal scaling and mean subtraction (using predefined values for the SFace model) automatically.
*   **Embedding Output:** A `1x128` normalized float32 array.
*   **Cosine Similarity:** The match score will be calculated via dot product (since vectors are L2-normalized) or OpenCV's built-in `match` function.
*   **Model Files:** The implementation will eventually require downloading two ONNX models provided by OpenCV (the face detector, though we use MediaPipe, and the feature extraction network `face_recognizer_fast.onnx` ~10MB). **No files are downloaded at this stage.**

## 3. Enrollment Database Design
A lightweight, offline, local folder structure inside `Section_3_Driver_Identification/database/` is proposed:
```text
database/
├── registry.json             # Master file mapping Driver ID (int) -> Name (str)
├── driver_1_alice/
│   ├── embeddings.npy        # N x 128 array of enrolled embeddings
│   ├── metadata.json         # Enrollment date, sample count, etc.
│   └── images/               # (Optional) 112x112 aligned face crops for auditing
└── driver_2_bob/
    ├── embeddings.npy
    ├── metadata.json
    └── images/
```
*   **Driver ID Format:** Integer (starting from 1). `0` is reserved for system states (Unknown/No Face).
*   **Embedding Format:** Numpy arrays (`.npy`) for fast loading and matrix operations.
*   **Adding/Removing:** Handled by deleting the specific driver folder and updating `registry.json`.

## 4. Enrollment Strategy
*   **Sample Count:** Recommend 15–20 high-quality samples per driver.
*   **Variation:** The enrollment script will prompt the user to perform slight yaw and pitch movements (±15 degrees) to capture a robust representation.
*   **Quality Gates:** Frames will be rejected during enrollment if:
    *   No face or >1 face is detected.
    *   MediaPipe face detection confidence is below 0.9.
    *   Significant blur is detected (via variance of Laplacian).
*   **No-Face / Multiple Faces:** Enrollment pauses automatically if the primary face is lost or occluded, resuming only when exactly one clear face is present.

## 5. Recognition Logic
1.  **Compare:** Calculate Cosine Similarity against all embeddings of all drivers.
2.  **Aggregate:** Use either K-Nearest Neighbors (KNN) or compare against the driver's mean embedding. (Nearest Neighbor among the 15-20 samples is often more robust for non-linear variations).
3.  **Find Highest Similarity:** Let $S_1$ be the best score (Candidate A) and $S_2$ be the second-best score (Candidate B).
4.  **Evaluate Thresholds:**
    *   If $S_1$ < `PROTOTYPE CANDIDATE THRESHOLD`: Identity = `UNKNOWN`.
    *   If $S_1 \ge$ `PROTOTYPE CANDIDATE THRESHOLD`:
        *   If $(S_1 - S_2) <$ `MARGIN_THRESHOLD`: Identity = `LOW_CONFIDENCE` (ambiguous match).
        *   Else: Identity = Candidate A.

## 6. Unknown-Driver Handling
*   **UNKNOWN:** A face is clearly detected, but its embedding does not closely match any enrolled driver (score < threshold). The system explicitly rejects forcing the face into a known identity.
*   **LOW_CONFIDENCE:** The face matches an enrolled driver above the baseline threshold, but the match is ambiguous (e.g., poor lighting, partial occlusion, or looks too similar to a second enrolled driver).
*   **NO_FACE:** MediaPipe detects zero faces in the camera frame. No embedding is calculated.

## 7. Confidence / Threshold Strategy
*   **Similarity Metric:** Cosine Similarity, bounded between `[-1.0, 1.0]`.
*   **PROTOTYPE CANDIDATE THRESHOLD:** `0.363` (this is the default OpenCV SFace recommendation for cosine distance, to be treated strictly as a starting prototype value).
*   **Calibration Plan:** During testing (Task 3G), we will collect arrays of "genuine" match scores (same driver) and "impostor" match scores (different drivers). We will plot the distribution curves to visually identify the crossover point and adjust the threshold to minimize False Accept Rate (FAR) and False Reject Rate (FRR).
*   **Candidate Margin:** An initial prototype margin of `0.05` will be used to flag ambiguous matches (LOW_CONFIDENCE).

## 8. Temporal Stabilization
To prevent rapid ID flickering, a temporal state machine will buffer the frame-by-frame candidate.
*   **Counters:** Maintain a `current_confirmed_id` and a `candidate_counter`.
*   **Persistence Requirement:** A new identity must be the dominant candidate for $N$ consecutive frames (e.g., 10 frames = ~0.5s at 20Hz) before `current_confirmed_id` transitions.
*   **Face-Loss / Micro-Occlusions:** If a `NO_FACE` state occurs for fewer than 10 frames (e.g., a quick sneeze or head turn), the system maintains the `current_confirmed_id`. If it persists >10 frames, the state degrades to `NO_FACE`.

## 9. Proposed Identification States
The system will export a standardized state integer to Simulink.
*   `0 = NO_FACE` (No face present for > N frames)
*   `1 = UNKNOWN` (Face present, identity not recognized)
*   `2 = IDENTIFIED` (Face present, recognized with high confidence)
*   `3 = LOW_CONFIDENCE` (Face present, recognized but score is marginal or ambiguous)

*Internal diagnostic states* (like transitioning, extracting, enrolling) will remain in Python and will not be broadcast via UDP.

## 10. Python vs. MATLAB/Simulink Responsibilities
*   **Python (Vision Node):** Fully owns the webcam, MediaPipe execution, face cropping/alignment, SFace embedding generation, similarity matching, thresholding, temporal stabilization, and database management. Python ultimately decides the final confirmed Identity and State.
*   **MATLAB / Simulink (Logic Node):** Receives the final states via UDP. Simulink will use these states to enable/disable certain alerts (e.g., suppressing distraction warnings if `NO_FACE`, or logging telemetry specific to `DRIVER_ID`). MATLAB will not perform any image processing.

## 11. UDP Design (Future Extension)
*   **Existing Packet:** `[FACE, EAR, MAR, YAW, PITCH, ROLL, GAZE_X, GAZE_Y]` (8 doubles, 64 bytes).
*   **Proposed Extended Packet:** `[FACE, EAR, MAR, YAW, PITCH, ROLL, GAZE_X, GAZE_Y, DRIVER_ID, ID_CONFIDENCE, ID_STATE]` (11 doubles, 88 bytes).
    *   `DRIVER_ID`: Double cast to int (`0` if unknown, `1+` for known).
    *   `ID_CONFIDENCE`: Double (`0.0` to `1.0`).
    *   `ID_STATE`: Double cast to int (`0`, `1`, `2`, `3`).
*   **Backward Compatibility:** Appending to the end of the payload is the safest approach. The MATLAB UDP receiver system will simply need to be updated to expect 11 doubles instead of 8. The ~20 Hz transmission rate will easily support 88 bytes without queue backlog.

## 12. Raspberry Pi Feasibility
*   **Expected Feasibility:** Highly feasible.
*   **Storage:** SFace model is ~10 MB. Embeddings are ~512 bytes per driver. Minimal disk footprint.
*   **RAM:** `cv2.dnn` module is extremely memory efficient compared to loading a full PyTorch/TensorFlow environment.
*   **CPU / Frequency:** The primary bottleneck will be running both MediaPipe and SFace sequentially on an ARM CPU. However, because we only run SFace on a small 112x112 crop (and we could potentially skip extracting embeddings every single frame once an ID is temporally locked), maintaining the existing ~20 Hz target is mathematically realistic for a Pi 4/5. 
*   **Validation:** Absolute performance will be measured (not assumed) during final testing.

## 13. New Files Planning
Future tasks will create the following scoped files inside `Section_3_Driver_Identification/`:
*   `Task3C_Enrollment.py` (CLI tool to capture faces and build the database)
*   `Task3D_Recognition_Core.py` (Class containing the SFace logic and matching)
*   `Task3F_Temporal_Filter.py` (Class handling the state machine and debouncing)
*   `Task3G_Diagnostic_Viewer.py` (Offline visualizer to validate bounding boxes and ID confidence before UDP integration)

## 14. Protected Components
The following files and components are **STRICTLY PROTECTED** and will not be modified during Section 3 development until explicit integration is requested:
*   `driver_monitor_sim.slx`
*   `DriverMonitorSystem.m`
*   `driver_monitor_sim_mediapipe.slx`
*   `head_pose.py`, `gaze_diagnostic.py`, `attention_diagnostic.py`
*   The validated Task 2 UDP architecture and packet size.

## 15. Testing Strategy
*   Structural testing of the enrollment script.
*   Similarity distribution analysis (Genuine vs. Impostor) using local static images before live webcam tests.
*   Live webcam validation covering variations in lighting, pose, and rapid driver swapping.
*   Validation of the temporal stabilizer (ensuring no flickering).
*   Final system integration test validating that Task 1 and Task 2 functionalities remain completely unaffected by the new Task 3 payload.
