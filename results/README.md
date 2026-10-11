# Results and graphs

This folder contains a small, curated set of visual outputs from the driver monitoring project. It keeps the repository focused on the figures while generated CSV files, manifests, and run logs remain local to each evaluation environment.

## Included figures

- `figures/s1-ear-demo.png` — S1 eye aspect ratio (EAR) feature trace.
- `figures/s1-state-demo.png` — S1 drowsiness state output.
- `figures/s2-yaw-demo.png` — S2 head-yaw feature trace.
- `figures/s2-state-demo.png` — S2 distraction state output.
- `figures/integrated-udp-synthetic.png` — visualization of the integrated 11-value telemetry packet.

The S1 and S2 figures show example feature and state outputs from the section demonstrations. The integrated packet figure visualizes the telemetry fields used by the combined system.

## Generate local evaluation outputs

Prepare the local data and manifests described in the root [README](../README.md#offline-dataset-evaluation), then run the MATLAB batch workflow. It generates evaluation tables, summaries, graphs, and logs locally. The repository includes only selected graph images; generated CSVs and machine-specific outputs are not tracked.

Dataset access and attribution details are in [CREDITS.md](../CREDITS.md). Keep driver enrollment records, face images, and other personal data local.
