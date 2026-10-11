# Contributing Guidelines

Thank you for your interest in the **AI-Based Driver Behavior Monitoring System**. This project is an academic research repository.

## Contribution Guidelines

1. **Safety Constraints:** All additions must preserve the driver-monitoring-only scope. Do **not** submit features for autonomous vehicle actuation, steering control, or active braking.
2. **Deterministic Telemetry:** Any modifications to the Python UDP bridge must preserve the 88-byte binary double struct (`<11d`) or provide backwards-compatible protocol negotiations.
3. **Privacy & Biometrics:** Never commit facial images, identity embeddings (`embeddings.npy`), or personal identifying data to the repository.
4. **Zero Deletion Policy:** Preserve existing validation datasets, models, and execution logs.
5. **Code Style & Testing:** Run unit tests in `SECTIONS/S3_Driver_Identification/` prior to submitting pull requests:
   ```powershell
   python SECTIONS/S3_Driver_Identification/test_Task3C.py
   python SECTIONS/S3_Driver_Identification/test_Task3D.py
   python SECTIONS/S3_Driver_Identification/test_Task3E.py
   python SECTIONS/S3_Driver_Identification/test_Task3F.py
   python SECTIONS/S3_Driver_Identification/test_Task3H.py
   ```
