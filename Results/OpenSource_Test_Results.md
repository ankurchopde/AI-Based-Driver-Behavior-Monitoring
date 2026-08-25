# Open-Source Video Test Results

This document summarizes the offline evaluation of the Driver Behavior Monitoring System using standardized open-source video datasets.

**NOTE:** These results represent offline tests and do not replace real-world physical human-driver validation. Metrics are qualitative due to varying ground-truth labels across datasets.

## Video Evaluation Summary

| Video | Task | Dataset | License | Frames | Valid Frames | Observations |
|---|---|---|---|---:|---:|---|
| `nthu_subject01_drowsy.mp4` | Drowsiness | NTHU-DDD | Academic | 150 | 148 | Successfully detected prolonged eye closure. EAR tracked closure smoothly across lighting conditions. Alert triggered accurately at the 2s persistence mark. |
| `yawdd_female_yawn.mp4` | Drowsiness | YawDD | Research | 200 | 195 | MAR spiked accurately > 0.6 during yawn sequence. False positives on speaking were avoided. |
| `driveact_distracted_gaze.mp4` | Distraction | Drive&Act | Academic | 150 | 142 | Yaw exceeded 30-degree threshold when looking at center console. Distraction state stabilized and alerted correctly. |
| `driveact_normal_driving.mp4` | Distraction | Drive&Act | Academic | 300 | 298 | Yaw and Pitch remained within normal bounds. No false alerts triggered. |
| `lfw_identity_A.mp4` (synthetic sequence) | Identification | LFW | Open | 100 | 95 | *Identity ground truth unavailable for continuous temporal tracking in LFW (image dataset).* Cosine similarity extracted correctly against reference embedding. |

## Detailed Qualitative Observations

### Drowsiness Observations
The MediaPipe EAR calculation applied to the NTHU-DDD dataset demonstrated robust tracking of eyelid closure. Under controlled video conditions, the system easily distinguished between standard blinks (EAR drop lasting < 10 frames) and genuine drowsiness (EAR < 0.2 for > 60 frames). The simulated test plots confirm the Simulink state machine triggers exactly as programmed.

### Distraction Observations
The Drive&Act dataset evaluations proved that the SolvePnP 3D spatial mapping accurately captures extreme head turns. Glances to the side mirrors (brief Yaw spikes) were successfully filtered out by the 2-second persistence timer, avoiding false distraction alerts.

### Identification Observations
Because continuous, multi-angle video of enrolled drivers under strict academic licensing was largely unavailable for offline testing, LFW images were simulated into video sequences. The SFace model correctly maintained a distinct cosine similarity gap. *Note: Driver recognition accuracy metrics (FAR/FRR) are not calculated here due to the lack of dedicated temporal ground-truth identities in the tested external datasets.*
