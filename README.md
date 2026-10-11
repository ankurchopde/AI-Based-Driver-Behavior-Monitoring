# AI-Based Driver Behavior Monitoring

A MATLAB/Simulink and Python prototype for camera-based driver monitoring. It reports driver state and produces visual alerts; it does not control vehicle steering, braking, or acceleration.

## Architecture

The live system has two processes. `INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py` reads a webcam or video, extracts face landmarks, EAR/MAR, head pose and gaze, performs SFace driver recognition, and sends 11 double-precision telemetry values over UDP port 5000. The Simulink model `SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx` receives the stream and applies temporal drowsiness/distraction logic and visual status output. The model uses `SECTIONS/S2_Distraction/DistractionLogicSystem.m` for its distraction subsystem.

The three functions implemented in the live bridge are:

- **S1 — Drowsiness:** EAR, MAR/yawn cues, face presence and temporal blink/eye state cues. The MATLAB model performs its supervisory logic.
- **S2 — Attention/distraction:** head pose, gaze and the model's distraction logic. A separate S2 camera sender and Simulink model add hand-on-wheel/wrist cues through a 14-value UDP packet. Phone detection is not implemented.
- **S3 — Driver identification:** enrollment and SFace embeddings, confidence evaluation and temporal stabilization. Driver names and embeddings are created locally and are not included in this repository.

`INTEGRATED_SYSTEM/MASTER_DRIVER_MONITORING_REAL.m` is a separate batch evaluation wrapper. It invokes `PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py`, which processes three prepared dataset manifests and writes CSVs and summaries. It is not the live camera launcher.

## Repository contents

```text
INTEGRATED_SYSTEM/
  MASTER_DRIVER_MONITORING_REAL.m
  Python_UDP_Bridge/          live camera/UDP code and enrollment utility
PROJECT/
  Dataset_Pipeline/           real-data batch evaluation processor
  Models/                     MediaPipe and OpenCV SFace runtime weights
SECTIONS/
  S2_Distraction/             standalone hand-aware sender, model, and logic
  S3_Driver_Identification/    recognition modules and integrated Simulink model
requirements.txt
```

## Prerequisites

- Python 3.10 or newer with a webcam for live use. Install packages with `python -m pip install -r requirements.txt`.
- MATLAB/Simulink with the UDP Receive block support required by the included model. The exact MATLAB release and toolbox compatibility have not been verified in this environment.
- A webcam (or a video file) for live monitoring. The application binds UDP to `127.0.0.1:5000`.

## Live execution

From the repository root, start the Python camera process:

```powershell
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0 --fps 20
```

Use `--video path/to/video.mp4` instead of `--camera 0` for video input, or add `--headless` to disable the Python preview. Press `q` or Escape to stop the preview. In MATLAB, set the current folder to the repository root and run:

```matlab
open_system('SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx');
```

Start the Simulink model after starting Python so it can receive telemetry on port 5000. Stop the Python process and Simulink model when finished.

### Standalone hand-aware S2 mode

The S2 variant is a separate 14-value telemetry path, and must not run at the same time as the 11-value integrated bridge because both use UDP port 5000. Start its sender from the repository root:

```powershell
python SECTIONS/S2_Distraction/mediapipe_udp_sender.py
```

In MATLAB, open `SECTIONS/S2_Distraction/driver_monitor_sim_distraction.slx` and start the model. This variant uses the central face landmarker and the local `hand_landmarker.task`; it is not the 11-value integrated model's input format.

### Driver enrollment

Enroll a driver locally before running recognition:

```powershell
python INTEGRATED_SYSTEM/Python_UDP_Bridge/live_enrollment.py --id 1 --name "Driver Name" --samples 20
```

The enrollment utility stores `registry.json` and `embeddings.npy` under `SECTIONS/S3_Driver_Identification/database/`. This directory is ignored by Git because it contains biometric data. Keep it local and back it up securely if needed; without enrolled drivers, S3 reports unknown/no identity.

## Optional batch evaluation

The MATLAB wrapper runs the Python processor and collects its outputs:

```matlab
cd('<repository-root>/INTEGRATED_SYSTEM');
MASTER_DRIVER_MONITORING_REAL
```

The processor requires these locally prepared input files, which are not distributed here:

- `PROJECT/Data/processed_real/manifests/section1_manifest.csv`
- `PROJECT/Data/processed_real/manifests/section2_manifest.csv`
- `PROJECT/Data/processed_real/manifests/section3_manifest.csv`

The manifest rows must point to the corresponding local video/image data expected by the processor. Obtain datasets through their original sources, follow their terms, prepare the manifests for this project's processor, and keep the data under the ignored `PROJECT/Data/` tree. The evaluation writes CSVs and graphs locally under `results/` and at the repository root; generated outputs are ignored.

## Models and configuration

The required runtime weights are `PROJECT/Models/external_backends/face_landmarker.task` and `PROJECT/Models/identification/face_recognizer_fast.onnx`. The optional hand-aware S2 mode and batch evaluation also use `SECTIONS/S2_Distraction/hand_landmarker.task`. Camera index, video source, frame rate, headless mode, and frame skipping are command-line options on the integrated Python bridge. The UDP address and port are currently constants in the sender source.

## Limitations and deployment

This is a research prototype, not a validated safety system. Gaze/head-pose thresholds and recognition confidence settings are candidates, not calibrated driver-specific thresholds. Runtime behavior with a camera, Simulink model, and enrolled drivers was not verified here. Alerts are prototype visual/supervisory outputs; there is no vehicle-control interface. Raspberry Pi deployment will require checking supported MATLAB/Simulink availability or replacing that supervisory runtime, validating ARM-compatible Python wheels and model latency, and measuring thermal and power behavior on target hardware.

## License

See [LICENSE](LICENSE).
