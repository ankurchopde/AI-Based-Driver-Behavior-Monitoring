# AI-BASED DRIVER BEHAVIOR MONITORING
# COMPLETE EXECUTION GUIDE

This document serves as the permanent practical execution manual for the AI-Based Driver Behavior Monitoring system. It covers both the dataset/offline pipeline (Mode A) and the live camera edge-deployment pipeline (Mode B).

---

## REPOSITORY STRUCTURE OVERVIEW

*   **`PROJECT/`**: Shared assets (`Data/`, `Models/`, `Dataset_Pipeline/`, `Results_Generation/`, `Tools/`)
*   **`SECTIONS/`**: Independent Simulink modules for Drowsiness (`S1`), Distraction (`S2`), and Identification (`S3`)
*   **`INTEGRATED_SYSTEM/`**: Combined final logic, offline evaluation (`MASTER_DRIVER_MONITORING_REAL.m`), and the camera UDP bridge (`Python_UDP_Bridge/`)

---

# MODE A — DATASET / OFFLINE PIPELINE

This mode executes the system on pre-recorded dataset CSVs to extract features, train models, and generate offline performance metrics.

### Step A1: Model Training (MATLAB)
Trains the ultra-lightweight decision trees for S1 (Drowsiness) and S2 (Distraction) using the master dataset.

*   **File:** `INTEGRATED_SYSTEM/train_models.m`
*   **Action:** Run directly in MATLAB from the project root.
*   **Input:** `PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv`
*   **Output:** 
    *   `PROJECT/Models/drowsiness/drowsiness_model.mat`
    *   `PROJECT/Models/distraction/distraction_model.mat`

### Step A2: Offline Inference Evaluation (MATLAB)
Evaluates the offline dataset using the final inference scripts to calculate accuracies and metrics.

*   **File:** `INTEGRATED_SYSTEM/MASTER_DRIVER_MONITORING_REAL.m`
*   **Action:** Run directly in MATLAB from the project root.
*   **Execution:** This will internally invoke the Python script `PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py` to extract features, then perform inference in MATLAB, and finally run `FINAL_RESULTS_GENERATOR.m` to build the CSVs and graphs.
*   **Outputs:** 
    *   `results/CSV/Master_Driver_Monitoring_Results.csv`
    *   `results/Graphs/*.png` (Performance metrics, confusions matrices, processing times)

---

# MODE B — LIVE MODE (REAL-TIME SYSTEM)

This mode runs the system continuously in real-time, pulling frames from a webcam or recorded video, processing AI features, and sending them via UDP to the display/Simulink logic.

### COMPLETE SYSTEM STARTUP

**Step 1: Start the Python Edge AI Processor**
This process handles camera capture, MediaPipe Face Landmarks, and ONNX Face Recognition, and broadcasts a lightweight 11-value array over UDP.

Open a terminal at the project root and run:
```powershell
# For normal webcam operation with UI dashboard:
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0

# For headless operation (e.g., Raspberry Pi without display):
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0 --headless

# To run using a pre-recorded test video:
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --video "PROJECT/Data/section1_drowsiness/Fold3_part2/Fold3_part2/31/10.mp4"
```

Available Configuration Arguments:
*   `--camera [INT]`: Select webcam index (default: 0).
*   `--video [PATH]`: Path to recorded video file for testing.
*   `--headless`: Disable the cv2 GUI window.
*   `--fps [FLOAT]`: Target processing and UDP transmission rate (default: 20.0).
*   `--skip-frames [INT]`: Number of frames to drop between processing steps to maintain real-time latency on slow hardware.

**Step 2: Start the MATLAB/Simulink Receivers**
The Python script broadcasts to `127.0.0.1:5000`. You can now open the Simulink files and start the simulation to receive the live data:

*   **S1 Drowsiness:** Open `SECTIONS/S1_Drowsiness/driver_monitor_sim_mediapipe.slx` -> Run
*   **S2 Distraction:** Open `SECTIONS/S2_Distraction/driver_monitor_sim_distraction.slx` -> Run
*   **S3 Identification:** Open `SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx` -> Run

*Note: MATLAB also has programmatic UDP receivers if you wish to pipe it directly into workspace variables.*

### SAFE SHUTDOWN

1. Press `q` or `ESC` in the Python video window (or `Ctrl+C` in the terminal if running headless). The Python script will cleanly close the camera, close the UDP socket, and join all threads.
2. Click `Stop` in your active Simulink model.

---

# MODE C — VERIFICATION & REPRODUCIBILITY

### Step C1: Execute Section 3 Unit Tests
Run the deterministic automated unit test suite from the repository root:
```powershell
python SECTIONS/S3_Driver_Identification/test_Task3C.py
python SECTIONS/S3_Driver_Identification/test_Task3D.py
python SECTIONS/S3_Driver_Identification/test_Task3E.py
python SECTIONS/S3_Driver_Identification/test_Task3F.py
python SECTIONS/S3_Driver_Identification/test_Task3H.py
```
*Expected Outcomes:*
* `test_Task3C.py`: Validates driver enrollment, blur rejection (`POOR_QUALITY`), and registry updates.
* `test_Task3D.py`: Validates cosine similarity feature extraction and unknown identification.
* `test_Task3E.py`: Validates margin thresholds (`0.363` cutoff and `0.05` low-confidence margin).
* `test_Task3F.py`: Validates 10-frame temporal stabilization, state transitions, and flicker prevention.
* `test_Task3H.py`: Validates 88-byte binary UDP datagram struct formatting and 20 Hz transmission rate.

### Step C2: Regenerate Presentation Graphs
To regenerate the presentation figures in `results/visuals/` and synchronize to `Graph/`:
```powershell
python PROJECT/Tools/Robustness/compare_robustness_results.py
```
*Outputs:* `Graph/1_Lighting_Coverage_Before_After.png` through `Graph/7_COMBINED_RESULTS_DASHBOARD.png`.

### PERFORMANCE CHECK

The Python GUI overlay will display live FPS and processing latency (e.g., `FPS: 18.5 | Latency: 45.2ms`). 
If latency > 100ms on edge hardware, use `--skip-frames 1` or `--skip-frames 2` to drop intermediate frames and maintain low temporal delay.

### TROUBLESHOOTING

*   **"Error: Could not open camera/video."**: Verify the camera index (try `--camera 1` or `--camera 2`). If using a laptop, ensure the webcam isn't locked by another application.
*   **"Address already in use"**: The UDP port 5000 is occupied. Ensure no orphaned Python processes are running.
*   **Simulink shows no data**: Verify that Python is broadcasting to `127.0.0.1:5000` and the Simulink UDP Receive block is configured for `Local port: 5000`.

### RASPBERRY PI PREPARATION

To run the Python AI pipeline on a Raspberry Pi:
1. Copy the repository.
2. Ensure OpenCV, MediaPipe, and ONNX Runtime are installed.
3. Execute the script using `--headless` to prevent X11 server errors:
```bash
python3 INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0 --headless
```
4. The Raspberry Pi will process frames and emit the 88-byte UDP packet to a remote host (you must edit `UDP_IP` in the script to point to the host PC running Simulink).
