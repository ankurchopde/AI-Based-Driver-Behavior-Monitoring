# Open-Source Video Datasets

The following open-source datasets were referenced for offline video evaluation of the Driver Behavior Monitoring System.

## TASK 1: Drowsiness Detection

**1. NTHU-DDD (National Tsing Hua University Driver Drowsiness Detection Dataset)**
- **Original URL:** [http://cv.cs.nthu.edu.tw/php/callforpaper/datasets/DDD/](http://cv.cs.nthu.edu.tw/php/callforpaper/datasets/DDD/)
- **License:** Academic/Research Use Only. Redistribution is strictly prohibited.
- **Source Organization:** National Tsing Hua University, Taiwan
- **Purpose:** Used to evaluate EAR responsiveness during blinking, prolonged eye closure, and simulated drowsy driving.
- **Local Test Files:** `nthu_subject01_drowsy.mp4`, `nthu_subject02_normal.mp4` (Stored locally only)

**2. YawDD (Yawning Detection Dataset)**
- **Original URL:** [http://www.site.uottawa.ca/~shervin/yawning/](http://www.site.uottawa.ca/~shervin/yawning/)
- **License:** Research Use Only.
- **Source Organization:** University of Ottawa
- **Purpose:** Used to evaluate MAR responsiveness during yawning and normal speaking conditions.
- **Local Test Files:** `yawdd_female_yawn.mp4`, `yawdd_male_talk.mp4` (Stored locally only)

## TASK 2: Distraction Detection

**1. Drive&Act Dataset**
- **Original URL:** [https://www.driveandact.com/](https://www.driveandact.com/)
- **License:** Academic Use Only.
- **Source Organization:** Karlsruhe Institute of Technology (KIT)
- **Purpose:** Used to evaluate head pose (yaw/pitch) and gaze diversion during secondary tasks (looking at phone, interacting with radio).
- **Local Test Files:** `driveact_distracted_gaze.mp4`, `driveact_normal_driving.mp4` (Stored locally only)

## TASK 3: Driver Identification

**1. LFW (Labeled Faces in the Wild)**
- **Original URL:** [http://vis-www.cs.umass.edu/lfw/](http://vis-www.cs.umass.edu/lfw/)
- **License:** Open for non-commercial use.
- **Source Organization:** UMass Amherst
- **Purpose:** Used to test the structural face embedding and cosine similarity thresholding across different identities in varying lighting.
- **Local Test Files:** `lfw_identity_A.jpg`, `lfw_identity_B.jpg` (Stored locally only)

---
*Note: Due to the licensing restrictions of these datasets, the raw video files are NOT included in this repository. Evaluation scripts are provided in the `tests/` directory for researchers to reproduce the offline tests locally using their own dataset copies.*
