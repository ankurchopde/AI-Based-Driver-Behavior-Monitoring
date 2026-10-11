"""
dataset_processing_final_REAL_FINAL.py
=====================================
FINAL REAL-DATA BATCH AI PROCESSOR

Runs the EXISTING project algorithms on the prepared real datasets.

S1 UTA-RLDD:
  Real video frames from section1_manifest.csv
  MediaPipe Face Landmarker + existing EAR/MAR + HeadPose + Gaze
  Blink/PERCLOS are calculated only within real video sequence order.
  Drowsiness prediction is the project's EAR-threshold detector.

S2 State Farm:
  Real labelled images from section2_manifest.csv
  MediaPipe Face/Hand Landmarkers + existing EAR/MAR + HeadPose + Gaze
  Hands-on-steering and looking-away are measured where available.
  Distraction prediction follows the existing project head-pose logic.

S3 CASIA-WebFace:
  Real extracted identity folders from section3_manifest.csv
  Existing Task3C enrollment + Task3D recognition +
  Task3E confidence logic are used.
  Enrollment and evaluation images are kept separate per identity.

IMPORTANT:
  - No fabricated samples.
  - No fabricated ground truth.
  - No fabricated accuracy.
  - Missing measurements are NaN.
  - S1 temporal features are reset at video boundaries.
  - S3 uses real images only.
"""

import os
import sys
import time
import math
import shutil
from pathlib import Path

import cv2
import numpy as np
import pandas as pd
import psutil

ROOT = Path(__file__).resolve().parent.parent.parent
os.chdir(ROOT)

# -------------------------------------------------------------------------
# Project module paths
# -------------------------------------------------------------------------
S2_DIR = ROOT / "SECTIONS/S2_Distraction"
S3_DIR = ROOT / "SECTIONS/S3_Driver_Identification"
sys.path.append(str(ROOT / "INTEGRATED_SYSTEM/Python_UDP_Bridge"))

sys.path.insert(0, str(S2_DIR))
sys.path.insert(0, str(S3_DIR))

import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from head_pose import HeadPoseEstimator
from gaze_diagnostic import (
    calculate_eye_gaze,
    RIGHT_EYE_OUTER, RIGHT_EYE_INNER, RIGHT_EYE_TOP,
    RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER,
    LEFT_EYE_INNER, LEFT_EYE_OUTER, LEFT_EYE_TOP,
    LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER,
)

# -------------------------------------------------------------------------
# Existing project constants
# -------------------------------------------------------------------------
RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
LEFT_EYE_INDICES  = [362, 385, 387, 263, 373, 380]
MOUTH_INDICES     = [13, 14, 78, 308]

EAR_THRESHOLD = 0.15
MAR_THRESHOLD = 0.50
YAW_THRESHOLD = 20.0
WHEEL_Y_MIN = 0.55

# S3 confidence settings are the candidate values used by the existing
# live identification pipeline. They are NOT presented as calibrated
# accuracy claims.
S3_CANDIDATE_THRESHOLD = 0.363
S3_CANDIDATE_MARGIN = 0.05

# -------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------
MANIFEST_DIR = ROOT / "PROJECT" / "Data" / "processed_real" / "manifests"
S1_MANIFEST = MANIFEST_DIR / "section1_manifest.csv"
S2_MANIFEST = MANIFEST_DIR / "section2_manifest.csv"
S3_MANIFEST = MANIFEST_DIR / "section3_manifest.csv"

RESULT_DIR = ROOT / "results" / "Raw_Python"
RESULT_DIR.mkdir(parents=True, exist_ok=True)

S1_OUT = ROOT / "Section1_Drowsiness_Results.csv"
S2_OUT = ROOT / "Section2_Distraction_Results.csv"
S3_OUT = ROOT / "results/identification/Section3_Identification_Results.csv"

PROCESS = psutil.Process(os.getpid())


def safe_float(x):
    try:
        x = float(x)
        return x if math.isfinite(x) else np.nan
    except Exception:
        return np.nan


def enhance_image(frame):
    if frame is None: return frame
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    if np.mean(gray) < 60:
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        cl = clahe.apply(l)
        return cv2.cvtColor(cv2.merge((cl,a,b)), cv2.COLOR_LAB2BGR)
    return frame

def resolve_path(value):
    p = Path(str(value))
    if p.is_absolute():
        return p
    return ROOT / p


def distance(p1, p2):
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])


def calculate_ear(landmarks, indices, width, height):
    pts = [
        (int(landmarks[i].x * width), int(landmarks[i].y * height))
        for i in indices
    ]
    p1, p2, p3, p4, p5, p6 = pts
    horizontal = distance(p1, p4)
    if horizontal == 0:
        return np.nan
    return (distance(p2, p6) + distance(p3, p5)) / (2.0 * horizontal)


def calculate_mar(landmarks, width, height):
    pts = [
        (int(landmarks[i].x * width), int(landmarks[i].y * height))
        for i in MOUTH_INDICES
    ]
    vertical = distance(pts[0], pts[1])
    horizontal = distance(pts[2], pts[3])
    if horizontal == 0:
        return np.nan
    return vertical / horizontal


def create_detectors():
    face_model = S2_DIR / "face_landmarker.task"
    hand_model = S2_DIR / "hand_landmarker.task"

    if not face_model.exists():
        raise FileNotFoundError(f"Missing MediaPipe face model: {face_model}")
    if not hand_model.exists():
        raise FileNotFoundError(f"Missing MediaPipe hand model: {hand_model}")

    face_options = vision.FaceLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(face_model)),
        output_face_blendshapes=False,
        output_facial_transformation_matrixes=False,
        num_faces=1,
        min_face_detection_confidence=0.5,
        min_face_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    hand_options = vision.HandLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(hand_model)),
        num_hands=2,
        min_hand_detection_confidence=0.5,
        min_hand_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    return (
        vision.FaceLandmarker.create_from_options(face_options),
        vision.HandLandmarker.create_from_options(hand_options),
    )


def extract_driver_features(frame, face_detector, hand_detector, pose_estimator=None):
    """
    Uses the same MediaPipe/HeadPose/Gaze implementation used by the
    project's diagnostics/bridge.

    Returns:
      feature dictionary, pose estimator
    """
    h, w = frame.shape[:2]
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=rgb
    )

    face_result = face_detector.detect(mp_image)
    hand_result = hand_detector.detect(mp_image)

    out = {
        "Face_Detected": 0,
        "EAR": np.nan,
        "MAR": np.nan,
        "Eye_State": np.nan,
        "Yawning": np.nan,
        "Head_Pose_Yaw": np.nan,
        "Head_Pose_Pitch": np.nan,
        "Head_Pose_Roll": np.nan,
        "Gaze_Direction_X": np.nan,
        "Gaze_Direction_Y": np.nan,
        "Gaze_State": "",
        "Left_Hand_On_Steering": np.nan,
        "Right_Hand_On_Steering": np.nan,
        "Hands_On_Steering": np.nan,
        "Looking_Away": np.nan,
    }

    if face_result.face_landmarks:
        out["Face_Detected"] = 1
        lm = face_result.face_landmarks[0]

        right_ear = calculate_ear(lm, RIGHT_EYE_INDICES, w, h)
        left_ear = calculate_ear(lm, LEFT_EYE_INDICES, w, h)

        if math.isfinite(right_ear) and math.isfinite(left_ear):
            out["EAR"] = (right_ear + left_ear) / 2.0

        out["MAR"] = calculate_mar(lm, w, h)

        if math.isfinite(out["EAR"]):
            out["Eye_State"] = 1 if out["EAR"] > EAR_THRESHOLD else 0

        if math.isfinite(out["MAR"]):
            out["Yawning"] = 1 if out["MAR"] > MAR_THRESHOLD else 0

        if pose_estimator is None:
            pose_estimator = HeadPoseEstimator((h, w))

        try:
            yaw, pitch, roll = pose_estimator.get_pose(lm)
            if yaw is not None:
                out["Head_Pose_Yaw"] = safe_float(yaw)
                out["Head_Pose_Pitch"] = safe_float(pitch)
                out["Head_Pose_Roll"] = safe_float(roll)
        except Exception:
            pass

        try:
            rx, ry = calculate_eye_gaze(
                lm,
                RIGHT_EYE_OUTER, RIGHT_EYE_INNER,
                RIGHT_EYE_TOP, RIGHT_EYE_BOTTOM, RIGHT_IRIS_CENTER
            )
            lx, ly = calculate_eye_gaze(
                lm,
                LEFT_EYE_OUTER, LEFT_EYE_INNER,
                LEFT_EYE_TOP, LEFT_EYE_BOTTOM, LEFT_IRIS_CENTER
            )

            gx = -((rx + lx) / 2.0)
            gy = (ry + ly) / 2.0

            out["Gaze_Direction_X"] = safe_float(gx)
            out["Gaze_Direction_Y"] = safe_float(gy)

            # Same candidate gaze thresholds used by the existing
            # gaze diagnostic.
            if gx < -0.20:
                out["Gaze_State"] = "LEFT"
            elif gx > 0.20:
                out["Gaze_State"] = "RIGHT"
            elif gy < -0.30:
                out["Gaze_State"] = "UP"
            elif gy > 0.40:
                out["Gaze_State"] = "DOWN"
            else:
                out["Gaze_State"] = "CENTER"
        except Exception:
            pass

    # Hand processing
    left = np.nan
    right = np.nan

    if hand_result.hand_landmarks:
        for i, hand_lms in enumerate(hand_result.hand_landmarks):
            try:
                handedness = hand_result.handedness[i][0].category_name
                wrist = hand_lms[0]
                on_wheel = 1.0 if wrist.y > WHEEL_Y_MIN else 0.0

                if handedness == "Left":
                    left = on_wheel
                else:
                    right = on_wheel
            except Exception:
                pass

    out["Left_Hand_On_Steering"] = left
    out["Right_Hand_On_Steering"] = right

    if math.isfinite(left) or math.isfinite(right):
        valid = [x for x in (left, right) if math.isfinite(x)]
        out["Hands_On_Steering"] = 1.0 if any(x == 1.0 for x in valid) else 0.0

    if math.isfinite(out["Head_Pose_Yaw"]):
        out["Looking_Away"] = float(
            abs(out["Head_Pose_Yaw"]) > YAW_THRESHOLD
        )

    return out, pose_estimator


# =========================================================================
# S1 - DROWSINESS
# =========================================================================
def process_s1(face_detector, hand_detector):
    if not S1_MANIFEST.exists():
        print(f"[S1] Manifest not found: {S1_MANIFEST}")
        return pd.DataFrame()

    manifest = pd.read_csv(S1_MANIFEST)
    print(f"\n[S1] REAL UTA-RLDD frames: {len(manifest)}")

    if "source_video" not in manifest.columns:
        raise RuntimeError("S1 manifest is missing source_video.")
    if "image_path" not in manifest.columns:
        raise RuntimeError("S1 manifest is missing image_path.")

    # Preserve video order. This is essential for temporal PERCLOS/blink.
    manifest = manifest.sort_values(
        ["source_video", "frame_number"],
        kind="stable"
    ).reset_index(drop=True)

    rows = []
    current_video = None
    pose = None
    previous_eye = np.nan
    eye_history = []

    for idx, row in manifest.iterrows():
        source_video = str(row.get("source_video", "unknown"))

        # Temporal state MUST reset at a real video boundary.
        if source_video != current_video:
            current_video = source_video
            pose = None
            previous_eye = np.nan
            eye_history = []

        path = resolve_path(row["image_path"])
        frame = cv2.imread(str(path))
        frame = enhance_image(frame)

        start = time.perf_counter()

        if frame is None:
            feat = {
                "Face_Detected": 0, "EAR": np.nan, "MAR": np.nan,
                "Eye_State": np.nan, "Yawning": np.nan,
                "Head_Pose_Yaw": np.nan, "Head_Pose_Pitch": np.nan,
                "Head_Pose_Roll": np.nan,
                "Gaze_Direction_X": np.nan,
                "Gaze_Direction_Y": np.nan,
                "Gaze_State": "",
                "Left_Hand_On_Steering": np.nan,
                "Right_Hand_On_Steering": np.nan,
                "Hands_On_Steering": np.nan,
                "Looking_Away": np.nan,
            }
        else:
            feat, pose = extract_driver_features(
                frame, face_detector, hand_detector, pose
            )

        elapsed_ms = (time.perf_counter() - start) * 1000.0
        fps = 1000.0 / elapsed_ms if elapsed_ms > 0 else np.nan

        eye = feat["Eye_State"]

        blink = np.nan
        if math.isfinite(eye):
            blink = float(
                math.isfinite(previous_eye)
                and previous_eye == 1
                and eye == 0
            )
            previous_eye = eye
            eye_history.append(eye)

        valid_history = [x for x in eye_history[-30:] if math.isfinite(x)]

        perclos = np.nan
        if valid_history:
            perclos = float(
                sum(x == 0 for x in valid_history) / len(valid_history)
            )

        # Existing project rule: EAR < threshold => drowsy.
        drowsy_prediction = np.nan
        if math.isfinite(feat["EAR"]):
            drowsy_prediction = float(feat["EAR"] <= EAR_THRESHOLD)

        alert = np.nan
        if math.isfinite(perclos):
            alert = float(perclos > 0.20)

        gt = str(row.get("ground_truth", "unknown"))
        if gt.lower() == "nan":
            gt = "unknown"

        rows.append({
            "Section": "S1_Drowsiness",
            "SampleID": str(row.get("sample_id", "")),
            "Dataset_ID": "UTA_RLDD",
            "Source_Video": source_video,
            "File_Name": path.name,
            "Image_Path": str(path),
            "Frame_Number": row.get("frame_number", np.nan),
            "Timestamp_s": (
                float(row["frame_number"]) / float(row["source_fps"])
                if safe_float(row.get("source_fps", np.nan)) > 0
                else np.nan
            ),
            "Source_FPS": safe_float(row.get("source_fps", np.nan)),
            "GroundTruth": gt,
            "Drowsiness_GroundTruth": (
                np.nan if gt.lower() == "unknown" else gt
            ),
            "Face_Detected": feat["Face_Detected"],
            "EAR": feat["EAR"],
            "MAR": feat["MAR"],
            "Eye_State": feat["Eye_State"],
            "Blink": blink,
            "PERCLOS": perclos,
            "Yawning": feat["Yawning"],
            "Head_Pose_Yaw": feat["Head_Pose_Yaw"],
            "Head_Pose_Pitch": feat["Head_Pose_Pitch"],
            "Head_Pose_Roll": feat["Head_Pose_Roll"],
            "Gaze_Direction_X": feat["Gaze_Direction_X"],
            "Gaze_Direction_Y": feat["Gaze_Direction_Y"],
            "Gaze_State": feat["Gaze_State"],
            "Drowsiness_Prediction": drowsy_prediction,
            "Drowsiness_Alert": alert,
            "Processing_Time_ms": elapsed_ms,
            "FPS": fps,
            "CPU_Usage_Percent": psutil.cpu_percent(),
            "RAM_Usage_MB": PROCESS.memory_info().rss / (1024 * 1024),
        })

        if (idx + 1) % 250 == 0:
            print(f"  [S1] {idx+1}/{len(manifest)}")

    df = pd.DataFrame(rows)
    df.to_csv(S1_OUT, index=False, na_rep="NaN")
    print(f"[S1] DONE: {len(df)} rows -> {S1_OUT}")
    return df


# =========================================================================
# S2 - DISTRACTION
# =========================================================================
def process_s2(face_detector, hand_detector):
    if not S2_MANIFEST.exists():
        print(f"[S2] Manifest not found: {S2_MANIFEST}")
        return pd.DataFrame()

    manifest = pd.read_csv(S2_MANIFEST)
    print(f"\n[S2] REAL State Farm images: {len(manifest)}")

    rows = []
    pose = None

    for idx, row in manifest.iterrows():
        path = resolve_path(row["image_path"])
        frame = cv2.imread(str(path))
        frame = enhance_image(frame)

        start = time.perf_counter()

        if frame is None:
            feat = {
                "Face_Detected": 0, "EAR": np.nan, "MAR": np.nan,
                "Eye_State": np.nan, "Yawning": np.nan,
                "Head_Pose_Yaw": np.nan, "Head_Pose_Pitch": np.nan,
                "Head_Pose_Roll": np.nan,
                "Gaze_Direction_X": np.nan,
                "Gaze_Direction_Y": np.nan,
                "Gaze_State": "",
                "Left_Hand_On_Steering": np.nan,
                "Right_Hand_On_Steering": np.nan,
                "Hands_On_Steering": np.nan,
                "Looking_Away": np.nan,
            }
        else:
            feat, pose = extract_driver_features(
                frame, face_detector, hand_detector, pose
            )

        elapsed_ms = (time.perf_counter() - start) * 1000.0
        fps = 1000.0 / elapsed_ms if elapsed_ms > 0 else np.nan

        gt = str(row.get("distraction_ground_truth", "unknown"))
        cls = str(row.get("class", "unknown"))
        if gt.lower() == "nan":
            gt = "unknown"

        # Existing project distraction logic is head-pose based.
        prediction = np.nan
        alert = np.nan
        if math.isfinite(feat["Looking_Away"]):
            prediction = float(feat["Looking_Away"])
            alert = prediction

        rows.append({
            "Section": "S2_Distraction",
            "SampleID": str(row.get("sample_id", "")),
            "Dataset_ID": "State_Farm_Distracted_Driver",
            "File_Name": path.name,
            "Image_Path": str(path),
            "Class": cls,
            "Split": str(row.get("split", "")),
            "GroundTruth": gt,
            "Distraction_Class_GroundTruth": gt,
            "Distraction_GroundTruth": (
                np.nan if gt.lower() == "unknown" else gt
            ),
            "Face_Detected": feat["Face_Detected"],
            "EAR": feat["EAR"],
            "MAR": feat["MAR"],
            "Eye_State": feat["Eye_State"],
            "Yawning": feat["Yawning"],
            "Head_Pose_Yaw": feat["Head_Pose_Yaw"],
            "Head_Pose_Pitch": feat["Head_Pose_Pitch"],
            "Head_Pose_Roll": feat["Head_Pose_Roll"],
            "Gaze_Direction_X": feat["Gaze_Direction_X"],
            "Gaze_Direction_Y": feat["Gaze_Direction_Y"],
            "Gaze_State": feat["Gaze_State"],
            "Left_Hand_On_Steering": feat["Left_Hand_On_Steering"],
            "Right_Hand_On_Steering": feat["Right_Hand_On_Steering"],
            "Hands_On_Steering": feat["Hands_On_Steering"],
            "Looking_Away": feat["Looking_Away"],
            "Phone_Use": np.nan,
            "Eating_Drinking": np.nan,
            "Distraction_Prediction": prediction,
            "Distraction_Alert": alert,
            "Processing_Time_ms": elapsed_ms,
            "FPS": fps,
            "CPU_Usage_Percent": psutil.cpu_percent(),
            "RAM_Usage_MB": PROCESS.memory_info().rss / (1024 * 1024),
        })

        if (idx + 1) % 500 == 0:
            print(f"  [S2] {idx+1}/{len(manifest)}")

    df = pd.DataFrame(rows)
    df.to_csv(S2_OUT, index=False, na_rep="NaN")
    print(f"[S2] DONE: {len(df)} rows -> {S2_OUT}")
    return df


# =========================================================================
# S3 - DRIVER IDENTIFICATION
# =========================================================================
def process_s3():
    if not S3_MANIFEST.exists():
        print(f"[S3] Manifest not found: {S3_MANIFEST}")
        return pd.DataFrame()

    manifest = pd.read_csv(S3_MANIFEST)

    # Support either identity_ground_truth or ground_truth.
    gt_col = (
        "identity_ground_truth"
        if "identity_ground_truth" in manifest.columns
        else "ground_truth"
    )

    if gt_col not in manifest.columns:
        raise RuntimeError("S3 manifest has no identity ground-truth column.")

    print(f"\n[S3] REAL CASIA-WebFace images: {len(manifest)}")

    try:
        from Task3C_Enrollment import EnrollmentSystem
        from Task3D_Recognition_Core import RecognitionSystem
        from Task3E_Confidence_Logic import ConfidenceEvaluator
    except Exception as e:
        print("[S3] Could not import existing identification pipeline:")
        print(e)
        return pd.DataFrame()

    model_src = S3_DIR / "models" / "face_recognizer_fast.onnx"
    task_path = S2_DIR / "face_landmarker.task"

    if not model_src.exists():
        print(f"[S3] Missing recognition model: {model_src}")
        return pd.DataFrame()
    if not task_path.exists():
        print(f"[S3] Missing face landmarker: {task_path}")
        return pd.DataFrame()

    # Separate temporary evaluation database.
    eval_root = ROOT / "dataset" / "section3_identification" / "eval_db_real_final"

    if eval_root.exists():
        shutil.rmtree(eval_root)

    db_path = eval_root / "database"
    models_path = eval_root / "models"
    models_path.mkdir(parents=True, exist_ok=True)
    shutil.copy2(model_src, models_path / model_src.name)

    model_path = models_path / model_src.name

    # ---------------------------------------------------------------------
    # Enrollment split: first 20 genuine images per identity, or 5 if
    # an identity has fewer than 20. Remaining images are evaluation.
    # No image is used in both sets.
    # ---------------------------------------------------------------------
    groups = []
    for identity, g in manifest.groupby(manifest[gt_col].astype(str), sort=True):
        g = g.reset_index(drop=True)

        if len(g) < 6:
            print(f"[S3] Skipping identity {identity}: only {len(g)} images.")
            continue

        enroll_n = min(20, max(5, len(g) // 4))
        if len(g) - enroll_n < 1:
            continue

        groups.append((identity, g, enroll_n))

    if not groups:
        print("[S3] No identity has enough real images for a train/test split.")
        return pd.DataFrame()

    print(f"[S3] Identities available for evaluation: {len(groups)}")

    # Existing EnrollmentSystem API used by the project's Task3G script.
    try:
        enrollment = EnrollmentSystem(
            db_path=str(db_path),
            model_path=str(model_path),
            task_path=str(task_path),
        )
    except TypeError:
        enrollment = EnrollmentSystem(
            str(db_path),
            str(model_path),
            str(task_path),
        )

    enrolled = {}

    for driver_id, (identity, g, enroll_n) in enumerate(groups, start=1):
        frames = []

        for _, r in g.iloc[:enroll_n].iterrows():
            image = cv2.imread(str(resolve_path(r["image_path"])))
            if image is not None:
                frames.append(image)

        if len(frames) < 5:
            print(f"[S3] Enrollment skipped for {identity}: insufficient valid images.")
            continue

        try:
            success, msg = enrollment.enroll_driver(
                driver_id,
                identity,
                frames,
                min_samples=min(5, len(frames)),
                overwrite=True,
            )
        except Exception as e:
            success, msg = False, str(e)

        print(f"  [S3] Enroll ID {driver_id} / {identity}: {msg}")

        if success:
            enrolled[identity] = driver_id

    if not enrolled:
        print("[S3] No drivers were successfully enrolled.")
        return pd.DataFrame()

    # Existing recognition system.
    try:
        recognizer = RecognitionSystem(
            db_path=str(db_path),
            model_path=str(model_path),
            task_path=str(task_path),
        )
    except TypeError:
        recognizer = RecognitionSystem(
            str(db_path),
            str(model_path),
            str(task_path),
        )

    # Existing confidence layer from live identification pipeline.
    try:
        evaluator = ConfidenceEvaluator(
            recognizer,
            candidate_threshold=S3_CANDIDATE_THRESHOLD,
            candidate_margin=S3_CANDIDATE_MARGIN,
        )
    except Exception as e:
        print(f"[S3] Confidence evaluator unavailable; using raw recognizer: {e}")
        evaluator = None

    rows = []
    total_test = 0

    for identity, g, enroll_n in groups:
        if identity not in enrolled:
            continue

        driver_id = enrolled[identity]
        test = g.iloc[enroll_n:]

        for _, r in test.iterrows():
            path = resolve_path(r["image_path"])
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

            confidence_state = ""
            confidence_id = None

            if evaluator is not None:
                try:
                    confidence_state, confidence_id, confidence_score, confidence_msg = (
                        evaluator.evaluate_frame(image)
                    )
                    # Keep the actual evaluator score when it exists.
                    if confidence_score is not None:
                        raw_score = confidence_score
                    if confidence_msg:
                        raw_msg = confidence_msg
                except Exception:
                    pass

            elapsed_ms = (time.perf_counter() - start) * 1000.0
            fps = 1000.0 / elapsed_ms if elapsed_ms > 0 else np.nan

            predicted_id = (
                confidence_id
                if confidence_id is not None
                else raw_id
            )

            rows.append({
                "Section": "S3_Identification",
                "SampleID": str(r.get("sample_id", "")),
                "Dataset_ID": "CASIA_WebFace",
                "File_Name": path.name,
                "Image_Path": str(path),
                "Driver_ID_GroundTruth": driver_id,
                "Driver_Name_GroundTruth": identity,
                "Driver_ID_Prediction": (
                    predicted_id if predicted_id is not None else np.nan
                ),
                "Identification_Confidence": (
                    safe_float(raw_score)
                ),
                "Recognition_State": confidence_state,
                "Recognition_Status": str(raw_msg),
                "Enrollment_Samples": enroll_n,
                "Evaluation_Sample": True,
                "Face_Detected": int(predicted_id is not None),
                "Processing_Time_ms": elapsed_ms,
                "FPS": fps,
                "CPU_Usage_Percent": psutil.cpu_percent(),
                "RAM_Usage_MB": PROCESS.memory_info().rss / (1024 * 1024),
            })

            total_test += 1

            if total_test % 200 == 0:
                print(f"  [S3] {total_test} evaluation images processed")

    df = pd.DataFrame(rows)
    df.to_csv(S3_OUT, index=False, na_rep="NaN")

    if len(df):
        valid = (
            pd.to_numeric(df["Driver_ID_Prediction"], errors="coerce").notna()
        )
        if valid.any():
            accuracy = (
                df.loc[valid, "Driver_ID_Prediction"].astype(float)
                == df.loc[valid, "Driver_ID_GroundTruth"].astype(float)
            ).mean() * 100.0
            print(f"[S3] Raw measured recognition accuracy on valid predictions: {accuracy:.2f}%")

    print(f"[S3] DONE: {len(df)} evaluation rows -> {S3_OUT}")
    return df


# =========================================================================
# MASTER
# =========================================================================
def main():
    print("\n" + "=" * 68)
    print(" AI-BASED DRIVER BEHAVIOR MONITORING")
    print(" FINAL REAL-DATA AI PROCESSOR")
    print("=" * 68)

    print("\nREAL DATA INPUTS")
    print("S1:", S1_MANIFEST)
    print("S2:", S2_MANIFEST)
    print("S3:", S3_MANIFEST)

    missing = [p for p in [S1_MANIFEST, S2_MANIFEST, S3_MANIFEST] if not p.exists()]
    if missing:
        print("\nERROR: Missing real-data manifest(s):")
        for p in missing:
            print(" ", p)
        sys.exit(1)

    print("\nInitializing MediaPipe face + hand models...")
    face_detector, hand_detector = create_detectors()

    try:
        s1 = process_s1(face_detector, hand_detector)
        s2 = process_s2(face_detector, hand_detector)
    finally:
        try:
            face_detector.close()
            hand_detector.close()
        except Exception:
            pass

    s3 = process_s3()

    print("\n" + "=" * 68)
    print(" FINAL PYTHON PROCESSING COMPLETE")
    print("=" * 68)
    print(f"S1 rows: {len(s1)}")
    print(f"S2 rows: {len(s2)}")
    print(f"S3 rows: {len(s3)}")
    print(f"Total AI-processed rows: {len(s1) + len(s2) + len(s3)}")
    print("\nGenerated:")
    print(" ", S1_OUT)
    print(" ", S2_OUT)
    print(" ", S3_OUT)
    print("=" * 68)


if __name__ == "__main__":
    main()

