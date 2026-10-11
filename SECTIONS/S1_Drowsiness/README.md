# S1 — Drowsiness

For the integrated system, start the [main Python bridge](../../INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py) and integrated Simulink model described in the [main guide](../../README.md). The integrated bridge supplies S1 face presence, EAR, and MAR features alongside S2 and S3 telemetry.

## Standalone S1 demo

The standalone sender reads webcam 0, calculates face presence, eye aspect ratio (EAR), and mouth aspect ratio (MAR), then sends three doubles to UDP `127.0.0.1:5000` at 20 Hz. It uses the shared model at `PROJECT/Models/external_backends/face_landmarker.task`.

From the repository root:

```powershell
python -m pip install -r requirements.txt
python SECTIONS/S1_Drowsiness/mediapipe_udp_sender.py
```

In MATLAB, add the repository folders and start the matching three-input model:

```matlab
addpath(genpath(pwd));
open_system('SECTIONS/S1_Drowsiness/driver_monitor_sim_mediapipe.slx');
set_param('driver_monitor_sim_mediapipe', 'SimulationCommand', 'start');
```

Press `q` or Escape to stop the Python preview. Run only one UDP sender at a time: this standalone sender shares port 5000 with the integrated bridge and standalone S2 sender. The sender displays an instantaneous eye-open/closed candidate threshold; use the Simulink model for its temporal logic. This is a research demo, not a validated drowsiness or safety detector.
