# S3 — Driver identification

S3 enrolls driver templates locally and estimates identity/confidence in the integrated live Python bridge. The resulting ID, confidence, and state occupy the final three values in the 11-value packet sent to the integrated Simulink model.

See the root [README](../../README.md) for end-to-end setup and [ARCHITECTURE.md](../../ARCHITECTURE.md) for the integrated flow.

## Enroll a driver

From the repository root, install the dependencies and run:

```powershell
python INTEGRATED_SYSTEM/Python_UDP_Bridge/live_enrollment.py --id 1 --name "Driver Name" --samples 20
```

Use a unique numeric ID. The program captures face samples and stores registry data and embeddings in `SECTIONS/S3_Driver_Identification/database/`. This directory is ignored by Git. Obtain consent and keep this biometric data private. The integrated model reports unknown identity if no usable local enrollment exists.

## Code and model files

- `Task3C_Enrollment.py` — enrollment and template generation.
- `Task3D_Recognition_Core.py` — face embedding extraction and comparison.
- `Task3E_Confidence_Logic.py` — candidate match/confidence handling.
- `Task3F_Temporal_Filter.py` — temporal stabilization.
- `driver_monitor_sim_identification.slx` — integrated telemetry receiver and status logic.
- `PROJECT/Models/identification/face_recognizer_fast.onnx` — SFace model used by the integrated bridge.

Candidate thresholds are implementation settings, not calibrated identity guarantees. This prototype is not an access-control system or a safety-certified biometric system. See [CREDITS.md](../../CREDITS.md) for model attribution.
