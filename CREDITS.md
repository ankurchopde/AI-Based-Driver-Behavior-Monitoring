# Dataset and model credits

This repository contains code that can process data from external sources. It does not redistribute dataset media, face images, enrollment captures, or local manifests. Obtain data directly from the source, read the terms currently provided there, and cite the source in resulting publications.

## Datasets referenced by the local evaluation pipeline

| Dataset | Project use | Source and attribution | Access/reuse note |
|---|---|---|---|
| UTA Real-Life Drowsiness Dataset (UTA-RLDD) | S1 drowsiness evaluation | [Official dataset page](https://sites.google.com/view/utarldd/home). Cite Ghoddoosian, Galib, and Athitsos, “A Realistic Dataset and Baseline Temporal Model for Early Drowsiness Detection,” CVPR Workshops, 2019; [paper](https://arxiv.org/abs/1904.07312). | Obtain via the dataset authors' access instructions. Follow their terms and prescribed fold protocol; do not redistribute videos. |
| State Farm Distracted Driver Detection | S2 distraction evaluation | [Kaggle competition and data page](https://www.kaggle.com/competitions/state-farm-distracted-driver-detection/data). | Access is subject to Kaggle competition rules. Use a Kaggle account and accept the rules if required. The Kaggle CLI download command is below. Keep API tokens outside the repository; never commit `kaggle.json`. |
| CASIA-WebFace | S3 identity-pipeline evaluation | Yi, Lei, Liao, and Li, “Learning Face Representation from Scratch,” 2014; [paper](https://arxiv.org/abs/1411.7923). | Dataset access and reuse rights are governed by the dataset source. The subset used in local evaluation is not included. Do not redistribute face images or identity-linked data. |

The dataset names above document what the local pipeline is configured to process; they are not a claim that the current saved run produced valid benchmark metrics. The latest saved S1/S2 CSVs have no detected faces and no available predictions. See [results status](results/README.md).

## Getting the data

- **UTA-RLDD:** Use the access/download instructions on the [dataset authors' page](https://sites.google.com/view/utarldd/home). Cite the authors' 2019 paper when publishing results.
- **State Farm:** Accept the competition rules on Kaggle, install the CLI with `python -m pip install kaggle`, configure the Kaggle API credential outside this repository, and download to a local data directory (for example, outside the Git checkout):

  ```powershell
  kaggle competitions download -c state-farm-distracted-driver-detection -p D:\datasets\state-farm
  ```

- **CASIA-WebFace:** Follow the dataset source linked by the original paper and the source provider's access requirements. Confirm permission for your intended use before processing or redistributing any subset.

The batch processor expects manifests under `PROJECT/Data/processed_real/manifests/`. Create them locally with the columns documented in the root README and point image/video paths to your downloaded data. Use paths relative to the repository root where possible; never publish machine-specific paths, credentials, dataset media, or face samples.

## Runtime model sources

- **MediaPipe Face Landmarker and Hand Landmarker:** Google AI Edge [Face Landmarker documentation](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker) and [Hand Landmarker documentation](https://ai.google.dev/edge/mediapipe/solutions/vision/hand_landmarker). The corresponding `.task` assets are bundled for convenience. Check upstream model and software terms before redistribution or deployment.
- **OpenCV SFace face recognizer:** model family and upstream assets are in the [OpenCV Zoo SFace directory](https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface). Review the included upstream license and model notes before reuse. The bundled ONNX file is a third-party model, separate from this repository's MIT license.
- **Python libraries:** installed from `requirements.txt`; each library retains its own license and notices.

## Privacy and credentials

Driver enrollment data is biometric information. The repository ignores `SECTIONS/S3_Driver_Identification/database/`; keep that directory private and get consent before enrollment. Dataset manifests can reveal local paths and should remain local. Store dataset-provider credentials, Kaggle API tokens, and other secrets outside the repository. This project never needs you to commit credentials.
