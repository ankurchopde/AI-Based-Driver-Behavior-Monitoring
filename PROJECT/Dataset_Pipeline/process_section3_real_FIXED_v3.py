"""
process_section3_real.py
REAL CASIA-WebFace Section 3 evaluation
Uses the EXISTING project identification pipeline:
    Task3C_Enrollment.EnrollmentSystem
    Task3D_Recognition_Core.RecognitionSystem
    Task3E_Confidence_Logic.ConfidenceEvaluator

No synthetic/augmented images are created.
Enrollment and evaluation images are disjoint.
Ground truth comes only from the S3 manifest identity folder.
"""

import os
import sys
import time
import shutil
import json
from pathlib import Path

import cv2
import numpy as np
import pandas as pd
import psutil


# ---------------------------------------------------------------------
# PROJECT PATHS
# ---------------------------------------------------------------------
ROOT = Path(__file__).resolve().parent.parent.parent

S3_DIR = ROOT / "SECTIONS/S3_Driver_Identification"
S3_DATA = ROOT / "dataset" / "section3_identification"
MANIFEST = ROOT / "dataset" / "processed_real" / "manifests" / "section3_manifest.csv"

MODEL = S3_DIR / "models" / "face_recognizer_fast.onnx"
if not MODEL.exists():
    MODEL = ROOT / "PROJECT" / "Models" / "identification" / "face_recognizer_fast.onnx"

TASK = ROOT / "SECTIONS/S2_Distraction" / "face_landmarker.task"
if not TASK.exists():
    TASK = ROOT / "PROJECT" / "Models" / "external_backends" / "face_landmarker.task"

EVAL_ROOT = S3_DATA / "eval_db_real"
OUT_DIR = ROOT / "results" / "CSV"
OUT_CSV = OUT_DIR / "S3_Identification_Results_REAL.csv"

# These are the same candidate values used by the existing Task3G/live
# identification pipeline. They are reported as project candidate settings,
# not claimed as independently optimized scientific thresholds.
CANDIDATE_THRESHOLD = 0.363
CANDIDATE_MARGIN = 0.05


# ---------------------------------------------------------------------
# IMPORT EXISTING PROJECT MODULES
# ---------------------------------------------------------------------
sys.path.insert(0, str(S3_DIR))

from Task3C_Enrollment import EnrollmentSystem
from Task3D_Recognition_Core import RecognitionSystem

try:
    from Task3E_Confidence_Logic import ConfidenceEvaluator
except Exception:
    ConfidenceEvaluator = None


def resolve_path(p):
    """Resolve manifest paths without changing their identity."""
    p = Path(str(p))

    if p.is_absolute() and p.exists():
        return p

    candidates = [
        ROOT / p,
        ROOT / "dataset" / p,
        S3_DATA / p,
        S3_DATA / "extracted" / p,
    ]

    for c in candidates:
        if c.exists():
            return c

    # Manifest may contain Windows paths from another machine/root.
    # Match from the distinctive extracted/<identity>/<file> suffix.
    s = str(p).replace("\\", "/")
    marker = "section3_identification/"
    if marker in s:
        suffix = s.split(marker, 1)[1]
        c = S3_DATA / suffix
        if c.exists():
            return c

    marker = "extracted/"
    if marker in s:
        suffix = s.split(marker, 1)[1]
        c = S3_DATA / "extracted" / suffix
        if c.exists():
            return c

    return p


def load_manifest():
    """
    Build the REAL S3 manifest directly from:
        dataset/section3_identification/extracted/0
        ...
        dataset/section3_identification/extracted/14

    The old empty manifest is deliberately ignored.
    """
    image_exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    extracted = S3_DATA / "extracted"

    if not extracted.exists():
        raise FileNotFoundError(
            f"REAL S3 extracted dataset not found:\n{extracted}"
        )

    records = []

    identity_dirs = sorted(
        [d for d in extracted.iterdir() if d.is_dir()],
        key=lambda d: int(d.name) if d.name.isdigit() else 999999
    )

    print(f"[S3] Direct dataset scan: {extracted}")
    print(f"[S3] Identity folders found: {len(identity_dirs)}")

    for identity_dir in identity_dirs:
        identity = identity_dir.name

        if not identity.isdigit():
            print(f"[S3] SKIP non-identity folder: {identity}")
            continue

        files = sorted(
            f for f in identity_dir.rglob("*")
            if f.is_file() and f.suffix.lower() in image_exts
        )

        readable = 0

        for f in files:
            img = cv2.imread(str(f))
            if img is None:
                continue

            readable += 1

            records.append({
                "sample_id": f"{identity}_{readable:05d}",
                "image_path": str(f.resolve()),
                "identity_ground_truth": identity
            })

        print(
            f"[S3] Identity {identity:>2}: "
            f"{readable} readable images"
        )

    manifest = pd.DataFrame(records)

    if manifest.empty:
        raise RuntimeError(
            f"No readable images found under:\n{extracted}"
        )

    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    manifest.to_csv(MANIFEST, index=False)

    # Normalized internal ground-truth column used by the evaluation code.
    manifest["_gt"] = manifest["identity_ground_truth"].astype(str)

    return manifest, "identity_ground_truth"


def make_disjoint_splits(manifest):
    """
    Per identity:
      - use 20 images when possible
      - otherwise use max(5, floor(N/4))
      - remaining genuine images are evaluation

    No image can occur in both sets.
    """
    groups = []

    for identity, g in manifest.groupby("_gt", sort=True):
        g = g.reset_index(drop=True)

        if len(g) < 6:
            print(f"[S3] SKIP {identity}: only {len(g)} images")
            continue

        # Reserve a genuine test set while keeping at least 5 enrollment
        # images for the existing EnrollmentSystem.
        enroll_n = min(20, max(5, len(g) // 4))

        if len(g) <= enroll_n:
            continue

        groups.append((identity, g, enroll_n))

    return groups


def initialize_systems():
    if not MODEL.exists():
        raise FileNotFoundError(f"Recognition model missing:\n{MODEL}")

    if not TASK.exists():
        raise FileNotFoundError(f"Face landmarker model missing:\n{TASK}")

    if EVAL_ROOT.exists():
        shutil.rmtree(EVAL_ROOT)

    db_path = EVAL_ROOT / "database"
    model_dir = EVAL_ROOT / "models"

    db_path.mkdir(parents=True, exist_ok=True)
    model_dir.mkdir(parents=True, exist_ok=True)

    eval_model = model_dir / MODEL.name
    shutil.copy2(MODEL, eval_model)

    # IMPORTANT:
    # The project's own Task3G validation explicitly creates registry.json
    # before constructing EnrollmentSystem. Do the same here so enrollment
    # and recognition use the exact same persistent database.
    registry_path = db_path / "registry.json"
    with open(registry_path, "w", encoding="utf-8") as f:
        json.dump({}, f, indent=2)

    print(f"[S3] Evaluation database: {db_path}")
    print(f"[S3] Registry initialized: {registry_path}")

    try:
        enrollment = EnrollmentSystem(
            db_path=str(db_path),
            model_path=str(eval_model),
            task_path=str(TASK),
        )
    except TypeError:
        enrollment = EnrollmentSystem(
            str(db_path), str(eval_model), str(TASK)
        )

    return enrollment, str(db_path), str(eval_model)


def main():
    print("=" * 72)
    print("SECTION 3 — REAL CASIA-WEBFACE DRIVER IDENTIFICATION")
    print("=" * 72)

    manifest, gt_col = load_manifest()

    print(f"[S3] Manifest rows: {len(manifest)}")
    print(f"[S3] Identity GT column: {gt_col}")
    print(f"[S3] Unique identities: {manifest['_gt'].nunique()}")

    groups = make_disjoint_splits(manifest)

    if not groups:
        raise RuntimeError("No identity has enough images for a disjoint evaluation split.")

    print(f"[S3] Identities eligible for evaluation: {len(groups)}")

    enrollment, db_path, eval_model = initialize_systems()
    recognizer = None
    evaluator = None

    # ---------------------------------------------------------------
    # ENROLLMENT
    # ---------------------------------------------------------------
    enrolled = {}

    for driver_id, (identity, g, enroll_n) in enumerate(groups, start=1):
        frames = []

        for _, row in g.iloc[:enroll_n].iterrows():
            path = resolve_path(row["image_path"])
            image = cv2.imread(str(path))

            if image is not None:
                frames.append(image)

        if len(frames) < 5:
            print(
                f"[S3] Enrollment skipped: {identity} "
                f"(only {len(frames)} readable enrollment images)"
            )
            continue

        try:
            ok, msg = enrollment.enroll_driver(
                driver_id,
                identity,
                frames,
                min_samples=min(5, len(frames)),
                overwrite=True,
            )
        except Exception as e:
            ok, msg = False, str(e)

        print(
            f"[S3] ENROLL | ID={driver_id:02d} | "
            f"identity={identity} | samples={len(frames)} | {msg}"
        )

        if ok:
            enrolled[identity] = driver_id

    print(f"[S3] Successfully enrolled: {len(enrolled)} identities")

    if not enrolled:
        raise RuntimeError("No real identities were successfully enrolled.")

    # ---------------------------------------------------------------
    # VERIFY PERSISTENT DATABASE BEFORE RECOGNITION
    # ---------------------------------------------------------------
    registry_path = Path(db_path) / "registry.json"

    if not registry_path.exists():
        raise RuntimeError(
            f"Enrollment reported success but registry.json is missing:\n"
            f"{registry_path}"
        )

    try:
        with open(registry_path, "r", encoding="utf-8") as f:
            saved_registry = json.load(f)
    except Exception as e:
        raise RuntimeError(
            f"Could not read enrollment registry:\n{registry_path}\n{e}"
        )

    print(
        f"[S3] Persistent registry entries: {len(saved_registry)}"
    )

    if len(saved_registry) == 0:
        raise RuntimeError(
            "Enrollment returned success, but registry.json is empty. "
            "Stopping BEFORE recognition so no false 0% result is produced."
        )

    # Now construct RecognitionSystem against the SAME database.
    try:
        recognizer = RecognitionSystem(
            db_path=str(db_path),
            model_path=str(eval_model),
            task_path=str(TASK),
        )
    except TypeError:
        recognizer = RecognitionSystem(
            str(db_path), str(eval_model), str(TASK)
        )

    # Verify that the recognizer itself loaded the enrolled registry.
    loaded_registry = getattr(recognizer, "registry", None)

    if isinstance(loaded_registry, dict):
        print(
            f"[S3] Recognition registry entries loaded: "
            f"{len(loaded_registry)}"
        )
        if len(loaded_registry) == 0:
            raise RuntimeError(
                "RecognitionSystem loaded an empty registry. "
                "Database path mismatch detected."
            )

    # ---------------------------------------------------------------
    # RECOGNITION
    # ---------------------------------------------------------------
    rows = []
    process = psutil.Process(os.getpid())

    total = 0
    correct_raw = 0
    correct_conf = 0
    conf_evaluable = 0

    for identity, g, enroll_n in groups:
        if identity not in enrolled:
            continue

        expected_id = enrolled[identity]
        test = g.iloc[enroll_n:]

        for _, row in test.iterrows():
            path = resolve_path(row["image_path"])
            image = cv2.imread(str(path))

            if image is None:
                continue

            start = time.perf_counter()

            raw_id = None
            raw_score = np.nan
            raw_msg = "FAILED"

            try:
                raw_id, raw_score, raw_msg = recognizer.recognize_frame(image)
            except Exception as e:
                raw_msg = f"ERROR: {e}"

            conf_state = ""
            conf_id = None
            conf_score = np.nan
            conf_msg = ""

            if evaluator is not None:
                try:
                    (
                        conf_state,
                        conf_id,
                        conf_score,
                        conf_msg,
                    ) = evaluator.evaluate_frame(image)

                    if conf_score is not None:
                        conf_score = float(conf_score)
                except Exception as e:
                    conf_msg = f"CONFIDENCE_ERROR: {e}"

            elapsed_ms = (time.perf_counter() - start) * 1000.0
            fps = 1000.0 / elapsed_ms if elapsed_ms > 0 else np.nan

            # Raw recognizer prediction is kept separate from confidence
            # filtered prediction.
            raw_correct = (
                raw_id is not None
                and str(raw_id) == str(expected_id)
            )

            if raw_id is not None:
                if raw_correct:
                    correct_raw += 1

            if conf_id is not None:
                conf_evaluable += 1
                if str(conf_id) == str(expected_id):
                    correct_conf += 1

            predicted_id = conf_id if conf_id is not None else raw_id

            if predicted_id is None:
                prediction_status = "UNKNOWN"
            elif str(predicted_id) == str(expected_id):
                prediction_status = "CORRECT"
            else:
                prediction_status = "INCORRECT"

            rows.append({
                "Section": "S3_Identification",
                "SampleID": str(row.get("sample_id", "")),
                "Dataset_ID": "CASIA_WebFace",
                "ImagePath": str(path),

                # Ground truth is independent of prediction.
                "Identity_GroundTruth": identity,
                "Driver_ID_GroundTruth": expected_id,

                # Raw recognition output.
                "Raw_Predicted_ID": raw_id,
                "Raw_Score": raw_score,
                "Raw_Message": raw_msg,

                # Confidence/decision layer output.
                "Confidence_State": conf_state,
                "Confidence_Predicted_ID": conf_id,
                "Confidence_Score": conf_score,
                "Confidence_Message": conf_msg,

                "Prediction": predicted_id,
                "Prediction_Status": prediction_status,

                "ProcessingTime_ms": elapsed_ms,
                "FPS": fps,
                "CPU_Usage_Percent": psutil.cpu_percent(interval=None),
                "RAM_Usage_MB": process.memory_info().rss / (1024 * 1024),
            })

            total += 1

            if total % 100 == 0:
                print(f"[S3] TEST {total} samples processed")

    df = pd.DataFrame(rows)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUT_CSV, index=False, na_rep="NaN")

    # ---------------------------------------------------------------
    # ACTUAL PERFORMANCE SUMMARY
    # ---------------------------------------------------------------
    raw_accuracy = (
        100.0 * correct_raw / total if total else np.nan
    )
    conf_accuracy = (
        100.0 * correct_conf / conf_evaluable
        if conf_evaluable else np.nan
    )

    print("\n" + "=" * 72)
    print("SECTION 3 RESULTS")
    print("=" * 72)
    print(f"Evaluation samples       : {total}")
    print(f"Enrolled identities      : {len(enrolled)}")
    print(f"Raw correct              : {correct_raw}")
    print(f"Raw accuracy             : {raw_accuracy:.2f}%")
    print(f"Confidence-evaluable     : {conf_evaluable}")
    print(f"Confidence correct       : {correct_conf}")
    print(
        f"Confidence accuracy      : "
        f"{conf_accuracy:.2f}%"
        if conf_evaluable else
        "Confidence accuracy      : N/A"
    )

    if total:
        mean_ms = df["ProcessingTime_ms"].mean()
        median_ms = df["ProcessingTime_ms"].median()
        mean_fps = df["FPS"].mean()

        print(f"Mean processing time     : {mean_ms:.2f} ms")
        print(f"Median processing time   : {median_ms:.2f} ms")
        print(f"Mean measured FPS        : {mean_fps:.2f}")

    print(f"\nCSV written to:\n{OUT_CSV}")
    print("=" * 72)


if __name__ == "__main__":
    main()
