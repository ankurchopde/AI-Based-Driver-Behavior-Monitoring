import os, glob

ROOT = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"

replacements = {
    # Fix the corrupted CSV names
    "'SECTIONS/S1_Drowsiness_Results.csv'": "'S1_Drowsiness_Results.csv'",
    "'SECTIONS/S2_Distraction_Results.csv'": "'S2_Distraction_Results.csv'",
    "SECTIONS/S1_Drowsiness_Results.csv": "S1_Drowsiness_Results.csv",
    "SECTIONS/S2_Distraction_Results.csv": "S2_Distraction_Results.csv",
    
    # Fix MASTER_DRIVER_MONITORING_REAL.m looking for the wrong python script
    "'dataset_processing_final.py'": "'PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py'",
    
    # Fix dataset paths in FINAL_RESULTS_GENERATOR.m
    "fullfile(PROJECT,'dataset','processed_real','manifests')": "fullfile(PROJECT,'PROJECT','Data','processed_real','manifests')",
    "fullfile(PROJECT,'dataset','matlab_dataset_results')": "fullfile(PROJECT,'PROJECT','Data','matlab_dataset_results')",
    
    # Fix S3 test paths
    "../SECTIONS/S1_Drowsiness/face_landmarker.task": "../SECTIONS/S1_Drowsiness/face_landmarker.task", # This is actually correct relative to S3? No, S3 is in SECTIONS/S3_Driver_Identification, so ../S1_Drowsiness is correct.
    "../SECTIONS/SECTIONS/S1_Drowsiness": "../S1_Drowsiness",
    "PROJECT/Models/face_recognizer_fast.onnx": "PROJECT/Models/identification/face_recognizer_fast.onnx",
    "PROJECT/Models/face_landmarker.task": "PROJECT/Models/external_backends/face_landmarker.task",
    "PROJECT/Models/external_backends/face_recognizer_fast.onnx": "PROJECT/Models/identification/face_recognizer_fast.onnx",

    # UDP Bridge paths (runs from INTEGRATED_SYSTEM/Python_UDP_Bridge)
    "'../Models/face_landmarker.task'": "'../../PROJECT/Models/external_backends/face_landmarker.task'",
    "'../Models/face_recognizer_fast.onnx'": "'../../PROJECT/Models/identification/face_recognizer_fast.onnx'",
    "'../Database'": "'../../PROJECT/Data/section3_identification/database'", # wait, where is the database?
}

# The database is actually at SECTIONS/S3_Driver_Identification/database
replacements["'../../PROJECT/Data/section3_identification/database'"] = "'../../SECTIONS/S3_Driver_Identification/database'"
replacements["'../Database'"] = "'../../SECTIONS/S3_Driver_Identification/database'"

# S3 test paths
replacements['"PROJECT/Models/face_recognizer_fast.onnx"'] = '"../../PROJECT/Models/identification/face_recognizer_fast.onnx"'
replacements['"../SECTIONS/S1_Drowsiness/face_landmarker.task"'] = '"../../PROJECT/Models/external_backends/face_landmarker.task"'
replacements['"../SECTIONS/S1_Drowsiness/open_eyes.jpg"'] = '"../S1_Drowsiness/open_eyes.jpg"'


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
