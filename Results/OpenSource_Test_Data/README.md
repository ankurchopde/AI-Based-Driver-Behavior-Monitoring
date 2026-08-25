# Open Source Test Data

Due to licensing and redistribution constraints from dataset providers (NTHU-DDD, YawDD, Drive&Act), the raw `.mp4` video files are **NOT** committed to this GitHub repository.

To run the offline video evaluation tests locally:
1. Download the datasets from their respective official sources (see `Documentation/OPEN_SOURCE_DATASETS.md`).
2. Place the video clips in the appropriate subdirectories (`Drowsiness/`, `Distraction/`, `Identification/`).
3. Run the evaluation scripts located in `tests/video_evaluation/`.

The generated plots, CSV logs, and annotated output summaries are provided in the `Results` folder as evidence of the algorithmic evaluation on these datasets.
