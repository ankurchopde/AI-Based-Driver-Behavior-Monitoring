# S2 — Distraction and attention

The integrated live path estimates head pose and gaze in the Python bridge and applies distraction logic in the integrated Simulink model. See the [architecture](../../ARCHITECTURE.md) and [main setup guide](../../README.md).

## Standalone hand-aware demo

This separate path adds hand/wrist cues. From the repository root, install dependencies and start its sender:

```powershell
python -m pip install -r requirements.txt
python SECTIONS/S2_Distraction/mediapipe_udp_sender.py
```

In MATLAB, add the repository folders and start the matching model:

```matlab
addpath(genpath(pwd));
open_system('SECTIONS/S2_Distraction/driver_monitor_sim_distraction.slx');
set_param('driver_monitor_sim_distraction', 'SimulationCommand', 'start');
```

The sender sends a 14-double packet over UDP `127.0.0.1:5000` and needs `SECTIONS/S2_Distraction/hand_landmarker.task` plus the shared face model under `PROJECT/Models/external_backends/`. Do not run this at the same time as the integrated or S1 sender: all use port 5000 and expect different packet formats. Phone detection is not implemented. This is a research demo, not a validated distraction or safety detector.
