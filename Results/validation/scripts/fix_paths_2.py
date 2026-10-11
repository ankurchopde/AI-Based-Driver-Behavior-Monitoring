import os, glob

ROOT = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"

replacements = {
    "'S1_Drowsiness_Results.csv'": "'Section1_Drowsiness_Results.csv'",
    "'S2_Distraction_Results.csv'": "'Section2_Distraction_Results.csv'",
    "S1_Drowsiness_Results.csv": "Section1_Drowsiness_Results.csv",
    "S2_Distraction_Results.csv": "Section2_Distraction_Results.csv",
    
    # Fix the missing dataset_processing_final python script
    "dataset_processing_final.py": "PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py",
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
