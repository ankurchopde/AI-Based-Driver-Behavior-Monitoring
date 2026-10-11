# Integrated live system and offline evaluation

The integrated system is the primary live workflow. One Python process extracts S1 drowsiness cues, S2 attention cues, and S3 identity features, then sends 11 doubles to the integrated Simulink model. Read the repository [README](../README.md) for full prerequisites, setup, privacy guidance, packet fields, and limitations; see [ARCHITECTURE.md](../ARCHITECTURE.md) for the data-flow diagram.

## Live camera workflow

From the repository root, install dependencies into an isolated Python environment as described in the main README. Enroll local drivers before recognition:

```powershell
python INTEGRATED_SYSTEM/Python_UDP_Bridge/live_enrollment.py --id 1 --name "Driver Name" --samples 20
```

Start the camera bridge:

```powershell
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0 --fps 20
```

Use `--video <path>` to read a video file instead of a webcam, or `--headless` to omit the Python display. Run `--help` for other options.

In MATLAB, set the current folder to the repository root and run:

```matlab
addpath(genpath(pwd));
open_system('SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx');
set_param('driver_monitor_sim_identification', 'SimulationCommand', 'start');
```

The sender transmits an 11-double packet to UDP `127.0.0.1:5000`. Start Python before the model. The model uses `SECTIONS/S2_Distraction/DistractionLogicSystem.m` for part of its attention logic. Stop the model and sender when finished. Do not launch standalone S1 or S2 senders while this sender is active.

## Offline dataset evaluation

`MASTER_DRIVER_MONITORING_REAL.m` is a separate batch wrapper. It does not open a camera or run the integrated Simulink model. From the repository root, run it in MATLAB:

```matlab
run('INTEGRATED_SYSTEM/MASTER_DRIVER_MONITORING_REAL.m');
```

It calls `PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py` and expects local S1/S2/S3 manifests under `PROJECT/Data/processed_real/manifests/`, with local source media referenced in each manifest. Required column names and dataset citations are in the main [README](../README.md#offline-dataset-evaluation) and [CREDITS.md](../CREDITS.md). Dataset files and machine-specific manifests are excluded from Git.

The wrapper writes evaluation tables, summaries, graphs, and logs locally under `results/`. Only selected graph images are included in the repository; generated CSVs and machine-specific outputs remain local.

## Related section guides

- [S1 — Drowsiness](../SECTIONS/S1_Drowsiness/README.md)
- [S2 — Distraction and attention](../SECTIONS/S2_Distraction/README.md)
- [S3 — Driver identification](../SECTIONS/S3_Driver_Identification/README.md)
