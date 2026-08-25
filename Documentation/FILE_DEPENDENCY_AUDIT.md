# File Dependency Audit

This document traces the dependency chains to justify the inclusion of files within the final GitHub repository structure, guaranteeing that only essential runtime, configuration, modeling, and validation components are retained.

## Section 1: Drowsiness
| File | Required? | Used By | Action |
|---|---|---|---|
| `mediapipe_udp_sender.py` | **Yes** | Standalone Python Sender | Maintained as core edge processor |
| `MediapipeBridge.py` | **Yes** | `mediapipe_udp_sender.py` | Maintained (Python logic encapsulation) |
| `DriverMonitorSystem.m` | **Yes** | Simulink Model (`driver_monitor_sim_mediapipe.slx`) | Maintained (System Object) |
| `UDPReceiverSystem.m` | **Yes** | Simulink Model (`driver_monitor_sim_mediapipe.slx`) | Maintained (System Object) |
| `driver_monitor_sim_mediapipe.slx` | **Yes** | MATLAB Execution | Maintained (Master Control Logic) |
| `fan2_68_landmark.onnx` / `.task` | **Yes** | `mediapipe_udp_sender.py` | Maintained (Model weights) |
| `build_*.m`, `test_*.m`, `diag_*.m` | No | N/A | **DELETED** (Obsolete/Dev scripts) |

## Section 2: Distraction
| File | Required? | Used By | Action |
|---|---|---|---|
| `head_pose.py` | **Yes** | `master_driver_monitor_udp.py` & Section 2 Runner | Maintained (SolvePnP Logic) |
| `gaze_diagnostic.py` (rename pending) | **Yes** | `master_driver_monitor_udp.py` | Maintained (Iris Tracking Logic) |
| `DistractionLogicSystem.m` | **Yes** | Simulink Model (`driver_monitor_sim_distraction.slx`) | Maintained (System Object) |
| `SteeringWheelDashboard.m` | **Yes** | Simulink Model | Maintained (System Object) |
| `UDPReceiverSystemDistraction.m`| **Yes** | Simulink Model | Maintained (System Object) |
| `driver_monitor_sim_distraction.slx`| **Yes** | MATLAB Execution | Maintained (Master Control Logic) |
| `reference/` (Cloned repo) | No | N/A | **DELETED** (Unused duplicate repository) |
| `check_iris.py`, `udp_8value_diagnostic.py` | No | N/A | **DELETED** (Diagnostic scripts) |

## Section 3: Driver Identification
| File | Required? | Used By | Action |
|---|---|---|---|
| `Task3C_Enrollment.py` | **Yes** | `live_enrollment.py`, `master_driver_monitor_udp.py` | Maintained (Core Pipeline) |
| `Task3D_Recognition_Core.py` | **Yes** | `live_recognition.py`, `master_driver_monitor_udp.py` | Maintained (Feature Extractor) |
| `Task3E_Confidence_Logic.py` | **Yes** | `master_driver_monitor_udp.py` | Maintained (Score Evaluation) |
| `Task3F_Temporal_Filter.py` | **Yes** | `master_driver_monitor_udp.py` | Maintained (Stabilization Filter) |
| `live_identification_pipeline.py` | **Yes** | Standalone Test | Maintained (Task 3 Runner) |
| `UDPReceiverSystemIdentification.m`| **Yes** | Simulink Model | Maintained (System Object) |
| `driver_monitor_sim_identification.slx`| **Yes** | MATLAB Execution | Maintained (Master Control Logic) |
| `face_recognizer_fast.onnx` | **Yes** | `Task3D_Recognition_Core.py` | Maintained (SFace Model) |
| `database/*/embeddings.npy` | No | N/A | **DELETED** (Biometric privacy protection) |
| `run_Task3G_validation.py` | No | N/A | **DELETED** (Intermediate validation script) |

## Final Integration (`FINAL_AI_Driver_Monitoring`)
| File | Required? | Used By | Action |
|---|---|---|---|
| `master_driver_monitor_udp.py` | **Yes** | Standalone Python Sender | Maintained (Master Edge Processor) |
| *Duplicate Python Modules* | No | N/A | **DELETED** (Updated `sys.path` in master script to import directly from Section folders, ensuring a single source of truth) |
| *Duplicate ONNX/Task Models* | No | N/A | **DELETED** (Updated paths in master script to load strictly from Section 1 and Section 3 folders) |

## Validation & Documentation
| File | Required? | Used By | Action |
|---|---|---|---|
| `Results/`, `Documentation/` | **Yes** | External Readers / Reviewers | Maintained |
| `tests/video_evaluation/` | **Yes** | Reproducibility | Maintained (Offline evaluation scripts) |
