"""T01 - Repository integrity: resolve the paths each active script actually uses
(relative to the working directory / anchor that script uses) and check they exist."""
import os, sys, re, glob
ROOT = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"
J = os.path.join
S1 = J(ROOT, "SECTIONS", "S1_Drowsiness"); S2 = J(ROOT, "SECTIONS", "S2_Distraction"); S3 = J(ROOT, "SECTIONS", "S3_Driver_Identification")
UDP = J(ROOT, "INTEGRATED_SYSTEM", "Python_UDP_Bridge")

def src_has(path, needle):
    with open(path, encoding="utf-8", errors="ignore") as f:
        return needle in f.read()

checks = [
 # (consumer, how it resolves, resolved path)
 ("loadDriverModels.m (cwd=root)", J(ROOT, "PROJECT/Models/drowsiness/drowsiness_model.mat")),
 ("loadDriverModels.m (cwd=root)", J(ROOT, "PROJECT/Models/distraction/distraction_model.mat")),
 ("train_models.m (cwd=root)", J(ROOT, "PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv")),
 ("S3 Task3D default model_path (cwd=S3)", J(S3, "models/face_recognizer_fast.onnx") if not src_has(J(S3,"Task3D_Recognition_Core.py"),'"PROJECT/Models/face_recognizer_fast.onnx"') else J(S3, "PROJECT/Models/face_recognizer_fast.onnx")),
 ("S3 Task3D default task_path (cwd=S3)", os.path.normpath(J(S3, "../S1_Drowsiness/face_landmarker.task")) if not src_has(J(S3,"Task3D_Recognition_Core.py"),"../SECTIONS/S1_Drowsiness") else os.path.normpath(J(S3, "../SECTIONS/S1_Drowsiness/face_landmarker.task"))),
 ("S3 database registry (cwd=S3)", J(S3, "database/registry.json")),
 ("S3 tests image open_eyes.jpg (cwd=S3)", os.path.normpath(J(S3, "../S1_Drowsiness/open_eyes.jpg")) if not src_has(J(S3,"test_Task3D.py"),"../SECTIONS/") else os.path.normpath(J(S3, "../SECTIONS/S1_Drowsiness/open_eyes.jpg"))),
 ("UDP bridge face_landmarker (anchor=__file__)", os.path.normpath(J(UDP, "../Models/face_landmarker.task")) if src_has(J(UDP,"master_driver_monitor_udp.py"),"'../Models/face_landmarker.task'") else os.path.normpath(J(UDP, "../../PROJECT/Models/external_backends/face_landmarker.task"))),
 ("UDP bridge SFace onnx (anchor=__file__)", os.path.normpath(J(UDP, "../Models/face_recognizer_fast.onnx")) if src_has(J(UDP,"master_driver_monitor_udp.py"),"'../Models/face_recognizer_fast.onnx'") else os.path.normpath(J(UDP, "../../PROJECT/Models/external_backends/face_recognizer_fast.onnx"))),
 ("UDP bridge Database (anchor=__file__)", os.path.normpath(J(UDP, "../Database")) if src_has(J(UDP,"master_driver_monitor_udp.py"),"'../Database'") else os.path.normpath(J(UDP, "../../PROJECT/Data/Database"))),
 ("MASTER_DRIVER_MONITORING_REAL.m needs dataset_processing_final.py at root", J(ROOT, "dataset_processing_final.py")),
 ("FINAL_RESULTS_GENERATOR.m MANIFESTS (hardcoded root + 'dataset')", J(ROOT, "dataset/processed_real/manifests/section1_manifest.csv")),
 ("FINAL_RESULTS_GENERATOR.m S3_TEMP (hardcoded root + 'dataset')", J(ROOT, "dataset/matlab_dataset_results/S3_Identification_Temp_Results.csv")),
 ("FINAL_INTEGRATE_EXISTING_RESULTS.m", J(ROOT, "results/CSV/S1_Drowsiness_Results.csv")),
 ("FINAL_INTEGRATE_EXISTING_RESULTS.m", J(ROOT, "results/CSV/S3_Identification_Results_REAL.csv")),
 ("FINAL_GENERATE_SECTION_GRAPHS.m (cwd=root)", J(ROOT, "results/CSV/S2_Distraction_Results.csv")),
 ("FINAL_GRAPH_GENERATOR.m S1_FILE", J(ROOT, "results/CSV", "SECTIONS/S1_Drowsiness_Results.csv") if src_has(J(ROOT,"PROJECT/Results_Generation/FINAL_GRAPH_GENERATOR.m"),"SECTIONS/S1_Drowsiness_Results") else J(ROOT,"results/CSV/Section1_Drowsiness_Results.csv")),
 ("S1 Simulink model", J(S1, "driver_monitor_sim_mediapipe.slx")),
 ("S2 Simulink model", J(S2, "driver_monitor_sim_distraction.slx")),
 ("S3 Simulink model", J(S3, "driver_monitor_sim_identification.slx")),
]
fails = 0
for who, p in checks:
    ok = os.path.exists(p)
    fails += (not ok)
    print(f"{'PASS' if ok else 'FAIL'} | {who} | {os.path.relpath(p, ROOT)}")

# Corrupted literals left by the earlier blanket replace
bad = re.compile(r"SECTIONS/S[12]_(Drowsiness|Distraction)_Results\.csv|PROJECT/Models/face_recognizer_fast\.onnx|\.\./SECTIONS/|'SECTIONS/S[12]_(Drowsiness|Distraction)'\s*,\s*index|sheet_name='SECTIONS")
hits = []
for pat in ("**/*.m", "**/*.py"):
    for f in glob.glob(J(ROOT, pat), recursive=True):
        if any(s in f for s in ("slprj", "__pycache__", "PROJECT\\Tools", "results\\validation")):
            continue
        for i, line in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
            if bad.search(line):
                hits.append(f"{os.path.relpath(f, ROOT)}:{i}: {line.strip()}")
print(f"\nCorrupted path literals found: {len(hits)}")
for h in hits: print("  " + h)
print(f"\nSUMMARY: {len(checks)-fails}/{len(checks)} path checks pass, {len(hits)} corrupted literals")
