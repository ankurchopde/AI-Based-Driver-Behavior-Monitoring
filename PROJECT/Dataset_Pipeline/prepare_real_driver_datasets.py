#!/usr/bin/env python3
"""
AI-Based Driver Behavior Monitoring
REAL DATASET PREPARATION PIPELINE

Dataset -> check -> extract/organize genuine samples -> manifests

This script DOES NOT fabricate or duplicate samples.

Expected project layout:
D:\Academics\TY_SEM1\AE\AI based Driver Detector\
└── dataset\
    ├── section1_drowsiness\
    │   └── Fold3_part2\
    │       └── Fold3_part2\...
    ├── section2_distraction\
    │   └── archive\
    │       └── imgs\
    │           ├── train\
    │           └── test\
    └── section3_identification\
        └── faces_webface\
            └── faces_webface_112x112\
                ├── train.rec
                ├── train.idx
                └── train.lst

Outputs:
dataset\processed_real\
├── section1_frames\
├── section2_images\
├── section3_faces\
├── manifests\
│   ├── section1_manifest.csv
│   ├── section2_manifest.csv
│   ├── section3_manifest.csv
│   └── master_manifest.csv
└── dataset_summary.txt
"""

import csv
import math
import os
import re
import shutil
import struct
import sys
from pathlib import Path

try:
    import cv2
except ImportError:
    print("ERROR: OpenCV is required. Install with: pip install opencv-python")
    sys.exit(1)

# ---------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------

PROJECT = Path(__file__).resolve().parent.parent.parent
DATASET = PROJECT / "dataset"

S1_ROOT = DATASET / "section1_drowsiness"
S2_ROOT = DATASET / "section2_distraction"
S3_ROOT = DATASET / "section3_identification"

OUT = DATASET / "processed_real"
S1_OUT = OUT / "section1_frames"
S2_OUT = OUT / "section2_images"
S3_OUT = OUT / "section3_faces"
MANIFESTS = OUT / "manifests"

# S1: genuine frames sampled from real videos.
# 5 means approximately one frame every 5 source frames.
S1_FRAME_STRIDE = 5

# Safety cap per video. Set to None for every sampled frame.
# 300 is enough to quickly create >1000 genuine frames on most videos.
S1_MAX_FRAMES_PER_VIDEO = 300

# S2: keep all available labelled train images.
S2_COPY_ALL = True

# S3: extract this many genuine face images from train.rec.
# Set to None to extract all records (can be very large).
S3_MAX_IMAGES = 2000

# ---------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------

IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
VIDEO_EXT = {".mp4", ".avi", ".mov", ".mkv", ".wmv", ".m4v"}

def ensure_dirs():
    for p in (S1_OUT, S2_OUT, S3_OUT, MANIFESTS):
        p.mkdir(parents=True, exist_ok=True)

def write_csv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

def safe_name(s):
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", str(s))

def classify_s1(text):
    """Best-effort label extraction only when the source name contains it."""
    t = text.lower()
    if any(x in t for x in ["drowsy", "drowsiness", "sleepy"]):
        return "drowsy"
    if any(x in t for x in ["low", "vigilant_low", "low_vigilant"]):
        return "low_vigilant"
    if any(x in t for x in ["alert", "awake", "normal"]):
        return "alert"
    return "unknown"

def classify_s2(filename):
    m = re.search(r"(?:^|[_-])(c[0-9])(?:[_-]|\.|$)", filename.lower())
    if not m:
        m = re.search(r"(c[0-9])", filename.lower())
    return m.group(1) if m else "unknown"

# ---------------------------------------------------------------------
# S1: UTA-RLDD VIDEO -> REAL FRAMES
# ---------------------------------------------------------------------

def process_s1():
    print("\n[S1] Searching for real videos...")
    videos = [p for p in S1_ROOT.rglob("*") if p.is_file() and p.suffix.lower() in VIDEO_EXT]

    print(f"[S1] Videos found: {len(videos)}")
    if not videos:
        print("[S1] ERROR: No video files found.")
        return []

    rows = []
    total_frames = 0

    for vi, video in enumerate(videos, 1):
        rel = video.relative_to(S1_ROOT)
        video_id = safe_name(video.stem)

        cap = cv2.VideoCapture(str(video))
        if not cap.isOpened():
            print(f"[S1] Could not open: {video}")
            continue

        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
        fps = float(cap.get(cv2.CAP_PROP_FPS) or 0.0)
        extracted = 0
        frame_no = 0

        # Label is ONLY taken when present in the source path/name.
        # Otherwise ground truth remains unknown instead of being invented.
        gt = classify_s1(str(rel))

        print(f"[S1 {vi}/{len(videos)}] {rel} | frames={frame_count} fps={fps:.2f} label={gt}")

        while True:
            ok, frame = cap.read()
            if not ok:
                break

            if frame_no % S1_FRAME_STRIDE == 0:
                if S1_MAX_FRAMES_PER_VIDEO is not None and extracted >= S1_MAX_FRAMES_PER_VIDEO:
                    break

                out_name = f"{video_id}_f{frame_no:07d}.jpg"
                out_path = S1_OUT / out_name

                if cv2.imwrite(str(out_path), frame, [cv2.IMWRITE_JPEG_QUALITY, 95]):
                    rows.append({
                        "sample_id": f"S1_{len(rows)+1:06d}",
                        "source_video": str(rel),
                        "frame_number": frame_no,
                        "source_fps": fps,
                        "ground_truth": gt,
                        "image_path": str(out_path),
                    })
                    extracted += 1
                    total_frames += 1

            frame_no += 1

        cap.release()

        if extracted == 0:
            print("   WARNING: 0 frames extracted.")

    write_csv(
        MANIFESTS / "section1_manifest.csv",
        rows,
        ["sample_id", "source_video", "frame_number", "source_fps",
         "ground_truth", "image_path"]
    )

    print(f"[S1] Genuine frames extracted: {total_frames}")
    return rows

# ---------------------------------------------------------------------
# S2: STATE FARM -> REAL LABELLED IMAGES
# ---------------------------------------------------------------------

def process_s2():
    print("\n[S2] Searching for State Farm images...")
    train_dir = S2_ROOT / "archive" / "imgs" / "train"
    test_dir = S2_ROOT / "archive" / "imgs" / "test"

    # Fall back to recursive search if the exact layout changes.
    if not train_dir.exists():
        candidates = [p for p in S2_ROOT.rglob("train") if p.is_dir()]
        if candidates:
            train_dir = candidates[0]

    if not train_dir.exists():
        print("[S2] ERROR: train directory not found.")
        return []

    images = [p for p in train_dir.rglob("*") if p.is_file() and p.suffix.lower() in IMG_EXT]
    print(f"[S2] Train images found: {len(images)}")

    rows = []

    for i, src in enumerate(images, 1):
        cls = classify_s2(src.name)
        if S2_COPY_ALL:
            dst = S2_OUT / src.name
            if dst.exists():
                dst = S2_OUT / f"{i:06d}_{src.name}"
            shutil.copy2(src, dst)
        else:
            dst = src

        # c0 is safe driving; c1-c9 are distracted-driving classes.
        distraction_gt = "not_distracted" if cls == "c0" else (
            "distracted" if cls in {f"c{x}" for x in range(1, 10)} else "unknown"
        )

        rows.append({
            "sample_id": f"S2_{i:06d}",
            "source_file": str(src.relative_to(S2_ROOT)),
            "class": cls,
            "distraction_ground_truth": distraction_gt,
            "image_path": str(dst),
            "split": "train",
        })

        if i % 1000 == 0:
            print(f"[S2] Processed {i}/{len(images)}")

    # Test images are retained in a separate manifest if labels are absent.
    if test_dir.exists():
        test_images = [p for p in test_dir.rglob("*")
                       if p.is_file() and p.suffix.lower() in IMG_EXT]
        print(f"[S2] Test images found: {len(test_images)} (ground truth kept unknown)")
        for i, src in enumerate(test_images, 1):
            rows.append({
                "sample_id": f"S2_TEST_{i:06d}",
                "source_file": str(src.relative_to(S2_ROOT)),
                "class": "unknown",
                "distraction_ground_truth": "unknown",
                "image_path": str(src),
                "split": "test",
            })

    write_csv(
        MANIFESTS / "section2_manifest.csv",
        rows,
        ["sample_id", "source_file", "class",
         "distraction_ground_truth", "image_path", "split"]
    )

    print(f"[S2] Manifest samples: {len(rows)}")
    return rows

# ---------------------------------------------------------------------
# S3: CASIA-WEBFACE MXNET RECORDIO
# ---------------------------------------------------------------------

def read_recordio_header(f):
    """
    MXNet RecordIO header is 16 bytes:
      uint64 flag
      uint64 label
    The first 8 bytes encode length/flag information.
    This reader handles the common RecordIO layout used by train.rec.
    """
    b = f.read(16)
    if len(b) < 16:
        return None

    # RecordIO uses little-endian fields.
    flag, label = struct.unpack("<QQ", b)
    length = flag & 0xFFFFFFFF
    is_full = bool((flag >> 32) & 1)

    return length, label, is_full

def decode_record_payload(payload):
    """
    CASIA-WebFace MXNet records commonly contain:
      8-byte float label + encoded JPEG/PNG bytes
    Some records may use a richer image header.
    We try several offsets and let OpenCV validate the encoded image.
    """
    candidates = []

    if len(payload) >= 8:
        candidates.append(payload[8:])

    if len(payload) >= 4:
        candidates.append(payload[4:])

    candidates.append(payload)

    for data in candidates:
        arr = bytearray(data)
        img = cv2.imdecode(
            __import__("numpy").frombuffer(arr, dtype=__import__("numpy").uint8),
            cv2.IMREAD_COLOR
        )
        if img is not None:
            return img

    return None

def load_s3_labels(lst_path):
    """
    train.lst is typically tab-separated:
      index    label    relative_path
    Labels can be scalar or multiple values.
    """
    labels = {}
    if not lst_path.exists():
        return labels

    with lst_path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 3:
                try:
                    idx = int(parts[0])
                except ValueError:
                    continue
                labels[idx] = parts[1]
    return labels

def process_s3():
    print("\n[S3] Searching for CASIA-WebFace RecordIO...")
    candidates = list(S3_ROOT.rglob("train.rec"))
    if not candidates:
        print("[S3] ERROR: train.rec not found.")
        return []

    rec_path = candidates[0]
    lst_path = rec_path.with_suffix(".lst")
    labels = load_s3_labels(lst_path)

    print(f"[S3] Record file: {rec_path}")
    print(f"[S3] Label entries loaded: {len(labels)}")

    # numpy is only needed for RecordIO image decoding.
    try:
        import numpy as np
    except ImportError:
        print("ERROR: NumPy is required. Install with: pip install numpy")
        return []

    rows = []
    record_index = 0
    extracted = 0

    with rec_path.open("rb") as f:
        while True:
            pos = f.tell()
            h = read_recordio_header(f)
            if h is None:
                break

            length, label, is_full = h

            # Guard against corrupt/impossible records.
            if length <= 0 or length > 100_000_000:
                print(f"[S3] Invalid record length at byte {pos}: {length}")
                break

            payload = f.read(length)
            if len(payload) != length:
                break

            img = None
            # Decode manually here so the script does not require MXNet.
            for offset in (8, 4, 0):
                if len(payload) <= offset:
                    continue
                data = np.frombuffer(payload[offset:], dtype=np.uint8)
                img = cv2.imdecode(data, cv2.IMREAD_COLOR)
                if img is not None:
                    break

            if img is not None:
                out_name = f"face_{record_index:07d}.jpg"
                out_path = S3_OUT / out_name
                cv2.imwrite(str(out_path), img, [cv2.IMWRITE_JPEG_QUALITY, 95])

                # CASIA identity ground truth is represented by the
                # RecordIO/list label when available.
                gt = labels.get(record_index, str(label))

                rows.append({
                    "sample_id": f"S3_{extracted+1:06d}",
                    "record_index": record_index,
                    "identity_ground_truth": gt,
                    "image_path": str(out_path),
                })

                extracted += 1

                if extracted % 250 == 0:
                    print(f"[S3] Extracted {extracted}")

                if S3_MAX_IMAGES is not None and extracted >= S3_MAX_IMAGES:
                    break

            record_index += 1

    write_csv(
        MANIFESTS / "section3_manifest.csv",
        rows,
        ["sample_id", "record_index", "identity_ground_truth", "image_path"]
    )

    print(f"[S3] Genuine face images extracted: {extracted}")
    return rows

# ---------------------------------------------------------------------
# MASTER MANIFEST + SUMMARY
# ---------------------------------------------------------------------

def create_master(s1, s2, s3):
    rows = []

    for r in s1:
        rows.append({
            "section": "S1_Drowsiness",
            "sample_id": r["sample_id"],
            "ground_truth": r["ground_truth"],
            "source": r["source_video"],
            "image_path": r["image_path"],
        })

    for r in s2:
        rows.append({
            "section": "S2_Distraction",
            "sample_id": r["sample_id"],
            "ground_truth": r["distraction_ground_truth"],
            "source": r["source_file"],
            "image_path": r["image_path"],
        })

    for r in s3:
        rows.append({
            "section": "S3_Identification",
            "sample_id": r["sample_id"],
            "ground_truth": r["identity_ground_truth"],
            "source": "CASIA-WebFace train.rec",
            "image_path": r["image_path"],
        })

    write_csv(
        MANIFESTS / "master_manifest.csv",
        rows,
        ["section", "sample_id", "ground_truth", "source", "image_path"]
    )

    summary = OUT / "dataset_summary.txt"
    with summary.open("w", encoding="utf-8") as f:
        f.write("AI-BASED DRIVER BEHAVIOR MONITORING - REAL DATASET SUMMARY\n")
        f.write("=" * 65 + "\n\n")
        f.write(f"S1 genuine video frames: {len(s1)}\n")
        f.write(f"S2 labelled/available images: {len(s2)}\n")
        f.write(f"S3 extracted face images: {len(s3)}\n")
        f.write(f"TOTAL samples in manifests: {len(rows)}\n\n")
        f.write("IMPORTANT:\n")
        f.write("- No samples are fabricated or duplicated by this script.\n")
        f.write("- S1 frames originate from the real UTA-RLDD videos.\n")
        f.write("- S2 images originate from the State Farm dataset.\n")
        f.write("- S3 images originate from CASIA-WebFace train.rec.\n")
        f.write("- Ground truth is never replaced by a model prediction.\n")
        f.write("- Unknown labels are explicitly marked unknown.\n")
        f.write("- PC processing speed must not be reported as Raspberry Pi speed.\n")

def main():
    print("=" * 65)
    print(" REAL DRIVER DATASET PREPARATION")
    print(" DATASET -> CHECK -> EXTRACT -> MANIFEST")
    print("=" * 65)

    print("\nDataset roots:")
    print("S1:", S1_ROOT)
    print("S2:", S2_ROOT)
    print("S3:", S3_ROOT)

    if not DATASET.exists():
        print("\nERROR: Dataset root does not exist.")
        print(DATASET)
        sys.exit(1)

    ensure_dirs()

    s1 = process_s1()
    s2 = process_s2()
    s3 = process_s3()

    create_master(s1, s2, s3)

    print("\n" + "=" * 65)
    print("DONE")
    print("=" * 65)
    print(f"S1 frames : {len(s1)}")
    print(f"S2 samples: {len(s2)}")
    print(f"S3 faces  : {len(s3)}")
    print(f"\nOutput: {OUT}")
    print("\nNext stage:")
    print("Run the existing AI algorithms using the generated manifests.")
    print("Then export predictions separately from ground truth.")

if __name__ == "__main__":
    main()
