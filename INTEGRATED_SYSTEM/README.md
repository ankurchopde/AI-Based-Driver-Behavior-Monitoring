# Integrated system

See the repository [architecture](../ARCHITECTURE.md) and [main setup guide](../README.md) for end-to-end data flow and prerequisites.

## Live camera monitoring

From the repository root, install Python dependencies and start the 11-value telemetry sender:

```powershell
python -m pip install -r requirements.txt
python INTEGRATED_SYSTEM/Python_UDP_Bridge/master_driver_monitor_udp.py --camera 0 --fps 20
```

In MATLAB, add the project folders, open the integrated model, and start it:

```matlab
addpath(genpath(pwd));
open_system('SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx');
set_param('driver_monitor_sim_identification', 'SimulationCommand', 'start');
```

The Python sender transmits 11 doubles over UDP `127.0.0.1:5000`. Start the sender before Simulink. For supported video options, run the Python command with `--help`. Enroll drivers using the `live_enrollment.py` instructions in the main README; biometric data stays local.

## Offline dataset evaluation

`MASTER_DRIVER_MONITORING_REAL.m` is a batch evaluation wrapper, not the live runtime. From MATLAB:

```matlab
cd('INTEGRATED_SYSTEM');
MASTER_DRIVER_MONITORING_REAL
```

It invokes `PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py`. Prepare local manifests at `PROJECT/Data/processed_real/manifests/section1_manifest.csv`, `section2_manifest.csv`, and `section3_manifest.csv`, with each row referencing accessible source data. Dataset files and generated outputs are not included in Git.

## Section guides

- [S1 — Drowsiness](../SECTIONS/S1_Drowsiness/README.md)
- [S2 — Distraction and attention](../SECTIONS/S2_Distraction/README.md)
- [S3 — Driver identification](../SECTIONS/S3_Driver_Identification/README.md)
