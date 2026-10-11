# S3 — Driver identification

The integrated bridge uses the face recognition modules in this section and sends identity state and confidence as part of its 11-value stream to `driver_monitor_sim_identification.slx`. See the [architecture](../../ARCHITECTURE.md) and [main guide](../../README.md) for complete setup.

## Enroll a driver

From the repository root, install dependencies and run the enrollment utility:

```powershell
python -m pip install -r requirements.txt
python INTEGRATED_SYSTEM/Python_UDP_Bridge/live_enrollment.py --id 1 --name "Driver Name" --samples 20
```

Choose a unique numeric ID and follow the on-screen capture steps. Enrollment writes `registry.json` and `embeddings.npy` into this section's `database/` directory. The directory is ignored by Git because it contains sensitive biometric data. Without a locally enrolled driver, the integrated system cannot identify that person.

## Implementation files

- `Task3C_Enrollment.py` — enrollment and template creation.
- `Task3D_Recognition_Core.py` — embedding comparison against enrolled templates.
- `Task3E_Confidence_Logic.py` — match confidence decisions.
- `Task3F_Temporal_Filter.py` — temporal stabilization.
- `driver_monitor_sim_identification.slx` — integrated model receiving the live telemetry stream.

Recognition thresholds and behavior need validation with representative users and conditions. The prototype is not an access-control or safety-certified identification system.
