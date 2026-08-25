# Results Summary

This document summarizes the validation tests and outcomes for the AI-Based Driver Behavior Monitoring System prototype.

## TASK 1: Drowsiness Detection

| Test | Expected | Observed | Status |
|---|---|---|---|
| EAR Calculation Speed | < 10 ms / frame | ~3-5 ms / frame (x86 CPU) | PASS |
| Blink Detection | EAR drops momentarily | Validated via programmatic trigger | PASS |
| Prolonged Closure (Drowsiness) | Alert triggers after 2 seconds | Triggers accurately at 2.0s mark | PASS |
| UDP Transmission | Low latency | < 15ms overhead | PASS |

## TASK 2: Distraction Detection

| Test | Expected | Observed | Status |
|---|---|---|---|
| Head Pose (Yaw) | Detects > 30 degrees | Triggers on lateral movement | PASS |
| Head Pose (Pitch) | Detects > 20 degrees | Triggers on looking down | PASS |
| Persistence Timer | Ignore glances < 2s | State stabilizes correctly | PASS |

## TASK 3: Driver Identification

| Test | Expected | Observed | Status |
|---|---|---|---|
| Feature Extraction | Fast embedding generation | SFace runs in < 20ms | PASS |
| Matching Metric | Cosine similarity evaluation | Validated against threshold (0.363)* | PASS |
| Temporal Filter | 10 consecutive frames | Eliminates single-frame false matches | PASS |

*\* Note: Threshold = 0.363, Margin = 0.05, and Persistence = 10 frames are PROTOTYPE CANDIDATE VALUES. They are not universally calibrated for all edge conditions.*

## INTEGRATION: UDP & Simulink

| Component | Verification | Status |
|---|---|---|
| Python Data Packager | 11-double struct payload | PASS |
| Localhost Network | Zero packet drop on loopback | PASS |
| Simulink State Machine | Accurate state transitions | PASS |

*Note: All tests were performed as Software-In-the-Loop (SIL) on an x86 architecture. Performance and actual human-driver metrics (real-world accuracy, precision, F1 score) on Raspberry Pi are Not Measured and Not Available in the current prototype.*
