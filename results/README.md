# Results and evidence

This folder contains only a few representative figures. Raw generated CSVs, local test logs, manifests, screenshots, and intermediate outputs are excluded from Git.

## Included figures

- `figures/s1-ear-demo.png` — EAR feature trace from an earlier S1 demonstration run.
- `figures/s1-state-demo.png` — S1 state output example from an earlier demonstration run.
- `figures/s2-yaw-demo.png` — head-yaw feature trace from an earlier S2 demonstration run.
- `figures/s2-state-demo.png` — S2 state output example from an earlier demonstration run.
- `figures/integrated-udp-synthetic.png` — synthetic/programmatic 11-value packet visualization. This is not camera-run evidence.

The S1/S2 figures are examples of the kinds of traces the processing pipeline can produce. They are historical demo plots and are not performance benchmarks, current predictions, or proof of real-world accuracy. The integrated figure is explicitly synthetic.

## Current evaluation status

The latest local batch CSV snapshot inspected while curating this repository contains 5,847 S1 rows and 22,423 S2 rows. In those CSVs, `Face_Detected` is zero for every row and the S1/S2 prediction columns are unavailable. The saved run therefore does **not** support drowsiness/distraction accuracy claims. Those machine-specific CSVs and logs are intentionally not part of the public repository.

The repository's existing S3 CSV contains identity data and is kept local. Do not publish enrollment templates, names, facial images, or identifiable evaluation data.

## Reproduce and replace

Prepare the local data and manifests as described in the root [README](../README.md#offline-dataset-evaluation), run the MATLAB batch workflow, then inspect detection/prediction coverage and ground-truth labels before publishing new figures. Replace these examples only with outputs whose source data, run configuration, and limitations can be documented. Keep personal biometric data and raw dataset files out of the repository.
