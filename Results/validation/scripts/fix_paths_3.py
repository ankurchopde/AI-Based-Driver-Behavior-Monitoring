import os, glob

ROOT = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"

replacements = {
    # Fix dataset path in dataset_processing_final_REAL_FINAL.py
    'ROOT / "dataset/processed_real/manifests/section1_manifest.csv"': 'ROOT / "PROJECT/Data/processed_real/manifests/section1_manifest.csv"',
    'ROOT / "dataset/processed_real/manifests/section2_manifest.csv"': 'ROOT / "PROJECT/Data/processed_real/manifests/section2_manifest.csv"',
    'ROOT / "dataset/processed_real/manifests/section3_manifest.csv"': 'ROOT / "PROJECT/Data/processed_real/manifests/section3_manifest.csv"',
    
    # Fix Task3C and Task3D to use absolute paths or correct relative paths when cwd is ROOT
    '"../../PROJECT/Models/identification/face_recognizer_fast.onnx"': 'str(Path(__file__).resolve().parent.parent.parent / "PROJECT/Models/identification/face_recognizer_fast.onnx")',
    '"../../PROJECT/Models/external_backends/face_landmarker.task"': 'str(Path(__file__).resolve().parent.parent.parent / "PROJECT/Models/external_backends/face_landmarker.task")',
    '"../S1_Drowsiness/open_eyes.jpg"': 'str(Path(__file__).resolve().parent.parent / "S1_Drowsiness/open_eyes.jpg")',
    
    # The models are initialized as defaults. Let's just fix the string constants.
    # Actually it's easier to just do:
    'task_path="../../PROJECT/Models/external_backends/face_landmarker.task"': 'task_path="PROJECT/Models/external_backends/face_landmarker.task"',
    'model_path="../../PROJECT/Models/identification/face_recognizer_fast.onnx"': 'model_path="PROJECT/Models/identification/face_recognizer_fast.onnx"',
    'cv2.imread("../S1_Drowsiness/open_eyes.jpg")': 'cv2.imread("SECTIONS/S1_Drowsiness/open_eyes.jpg")',
}

for pat in ("**/*.m", "**/*.py"):
    for f in glob.glob(os.path.join(ROOT, pat), recursive=True):
        if any(s in f for s in ("slprj", "__pycache__", "PROJECT\\Tools", "results\\validation")):
            continue
            
        with open(f, 'r', encoding='utf-8', errors='ignore') as file:
            content = file.read()
            
        new_content = content
        for k, v in replacements.items():
            new_content = new_content.replace(k, v)
            
        if new_content != content:
            print(f"Fixed {os.path.relpath(f, ROOT)}")
            with open(f, 'w', encoding='utf-8') as file:
                file.write(new_content)
