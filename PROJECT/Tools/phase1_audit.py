import os
import re
import collections
import hashlib
from datetime import datetime

ROOT_DIR = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"

def get_hash(filepath):
    h = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            while chunk := f.read(8192):
                h.update(chunk)
        return h.hexdigest()
    except:
        return "ERROR"

def build_audit():
    # 1. Gather all files
    all_files = []
    top_level_stats = collections.defaultdict(lambda: {'count': 0, 'size': 0})
    
    datasets = []
    models = []
    scripts = []
    
    file_hashes = collections.defaultdict(list)
    
    print("Scanning directory...")
    for dirpath, dirnames, filenames in os.walk(ROOT_DIR):
        rel_dir = os.path.relpath(dirpath, ROOT_DIR)
        top_folder = rel_dir.split(os.sep)[0] if rel_dir != '.' else 'ROOT'
        
        for f in filenames:
            ext = os.path.splitext(f)[1].lower()
            full_path = os.path.join(dirpath, f)
            rel_path = os.path.relpath(full_path, ROOT_DIR)
            
            try:
                size = os.path.getsize(full_path)
            except:
                size = 0
                
            top_level_stats[top_folder]['count'] += 1
            top_level_stats[top_folder]['size'] += size
            
            file_info = {
                'name': f,
                'rel_path': rel_path,
                'full_path': full_path,
                'ext': ext,
                'size': size,
                'top_folder': top_folder
            }
            all_files.append(file_info)
            
            if ext in ['.csv', '.mat', '.xlsx', '.json', '.h5', '.npy', '.npz']:
                datasets.append(file_info)
            if ext in ['.onnx', '.h5', '.keras', '.pt', '.pth'] or (ext == '.mat' and 'model' in f.lower()):
                models.append(file_info)
            if ext in ['.m', '.py', '.slx']:
                scripts.append(file_info)
                
    print("Computing hashes for duplicates...")
    for f in all_files:
        # Skip hashing huge cache folders to save time in Phase 1
        if 'slprj' in f['rel_path'] or '__pycache__' in f['rel_path']:
            continue
        h = get_hash(f['full_path'])
        file_hashes[h].append(f)
        
    duplicates = {h: flist for h, flist in file_hashes.items() if len(flist) > 1}
    
    # Analyze code for hardcoded paths and dependencies
    print("Analyzing code dependencies...")
    hardcoded_paths = []
    protected_files = set()
    
    # Core important files
    important_core = [
        "export_matlab_dataset.m", "FINAL_GENERATE_SECTION_GRAPHS.m", 
        "FINAL_GRAPH_GENERATOR.m", "FINAL_INTEGRATE_EXISTING_RESULTS.m", 
        "FINAL_RESULTS_GENERATOR.m", "MASTER_DRIVER_DATASET_PIPELINE.m", 
        "MASTER_DRIVER_MONITORING_REAL.m", "S3_IDENTIFICATION_TEMP_PROCESSOR.m",
        "PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv"
    ]
    
    for s in scripts:
        if s['ext'] in ['.m', '.py']:
            try:
                with open(s['full_path'], 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # Detect hardcoded paths
                    matches = re.finditer(r'([A-Za-z]:[\\/][^\s\'"]+)', content)
                    for m in matches:
                        path_str = m.group(1)
                        hardcoded_paths.append({
                            'script': s['rel_path'],
                            'path': path_str
                        })
                        
                    if s['name'] in important_core:
                        protected_files.add(s['rel_path'])
                        
            except:
                pass
                
        # Protect models
        if 'models' in s['rel_path'].lower() or 'model' in s['name'].lower():
            protected_files.add(s['rel_path'])

    # Add core important files to protected if they exist
    for f in all_files:
        if f['name'] in important_core:
            protected_files.add(f['rel_path'])
        # Also protect everything in models/ directory from previous cleanup
        if f['rel_path'].startswith('models\\'):
            protected_files.add(f['rel_path'])
            
    # Write 1: PROJECT_STRUCTURE_BEFORE.txt
    print("Writing PROJECT_STRUCTURE_BEFORE.txt...")
    with open('PROJECT_STRUCTURE_BEFORE.txt', 'w', encoding='utf-8') as f:
        f.write("PROJECT STRUCTURE BEFORE ORGANIZATION\n")
        f.write("=======================================\n\n")
        for folder, stats in top_level_stats.items():
            f.write(f"Folder: {folder}\n")
            f.write(f"Files: {stats['count']}\n")
            f.write(f"Size: {stats['size'] / (1024*1024):.2f} MB\n\n")
            
        f.write("Major File Tree:\n")
        for folder in top_level_stats.keys():
            if folder == 'ROOT': continue
            f.write(f"├── {folder}/\n")
        f.write("└── (Root Files)\n")

    # Write 2: PROJECT_MAP.md
    print("Writing PROJECT_MAP.md...")
    with open('PROJECT_MAP.md', 'w', encoding='utf-8') as f:
        f.write("# PROJECT MAP\n\n")
        f.write("## S1 Drowsiness\n")
        f.write("Located primarily in `Section1_Drowsiness`.\n")
        f.write("Features: EAR, MAR, Blink, Yawning.\n")
        f.write("Active models: `models/drowsiness/drowsiness_model.mat`\n\n")
        f.write("## S2 Distraction\n")
        f.write("Located primarily in `Section2_Distraction`.\n")
        f.write("Features: Head Pose Yaw/Pitch/Roll.\n")
        f.write("Active models: `models/distraction/distraction_model.mat`\n\n")
        f.write("## S3 Identification\n")
        f.write("Located primarily in `Section_3_Driver_Identification`.\n")
        f.write("Features: SFace embeddings (128-D), ONNX integration.\n")
        f.write("Active models: `models/identification/face_recognizer_fast.onnx`\n\n")
        f.write("## Final Integrated System\n")
        f.write("Located in ROOT and `FINAL_AI_Driver_Monitoring`.\n")
        f.write("Scripts: `MASTER_DRIVER_MONITORING_REAL.m`, `FINAL_RESULTS_GENERATOR.m`.\n")

    # Write 3: ORGANIZATION_AUDIT_REPORT.md
    print("Writing ORGANIZATION_AUDIT_REPORT.md...")
    with open('ORGANIZATION_AUDIT_REPORT.md', 'w', encoding='utf-8') as f:
        f.write("# ORGANIZATION AUDIT REPORT\n\n")
        f.write("## 1. WHAT CURRENTLY EXISTS\n")
        f.write(f"Total Files: {len(all_files)}\n")
        
        f.write("\n## 2. DUPLICATE DATASETS & MODELS\n")
        for h, flist in duplicates.items():
            ext = flist[0]['ext']
            if ext in ['.csv', '.mat', '.onnx', '.h5', '.xlsx']:
                f.write(f"Duplicate {ext} Set (Hash: {h[:8]}):\n")
                for dup in flist:
                    f.write(f"  - {dup['rel_path']}\n")
                f.write("  Action: KEEP ALL (Zero Deletion Rule)\n\n")
                
        f.write("\n## 3. PROPOSED ORGANIZATION (TO BE EXECUTED IN PHASE 2)\n")
        f.write("```text\n")
        f.write("AI based Driver Detector/\n")
        f.write("├── 01_Source/\n")
        f.write("│   ├── S1_Drowsiness/\n")
        f.write("│   ├── S2_Distraction/\n")
        f.write("│   └── S3_Identification/\n")
        f.write("├── 02_Data/\n")
        f.write("├── 03_Models/\n")
        f.write("├── 04_Results/\n")
        f.write("├── 05_Simulink/\n")
        f.write("└── ...\n")
        f.write("```\n")
        f.write("*Note: Existing functional hierarchies like `Section1_Drowsiness` will be preserved if moving them breaks Simulink, or gently restructured with path updates.*")

    # Write 4: PATH_DEPENDENCY_REPORT.md
    print("Writing PATH_DEPENDENCY_REPORT.md...")
    with open('PATH_DEPENDENCY_REPORT.md', 'w', encoding='utf-8') as f:
        f.write("# PATH DEPENDENCY REPORT\n\n")
        if not hardcoded_paths:
            f.write("No severe absolute hardcoded paths found in analyzed scripts.\n")
        else:
            for hp in hardcoded_paths[:100]: # Limit to 100 to avoid giant file
                f.write(f"- File: {hp['script']}\n")
                f.write(f"  Old Path: {hp['path']}\n")
                f.write(f"  Required Update: Will convert to project-relative if file is moved.\n\n")
                
    # Write 5: PROTECTED_ACTIVE_FILES.txt
    print("Writing PROTECTED_ACTIVE_FILES.txt...")
    with open('PROTECTED_ACTIVE_FILES.txt', 'w', encoding='utf-8') as f:
        for p in sorted(list(protected_files)):
            f.write(f"{p}\n")
            
if __name__ == "__main__":
    build_audit()
    print("Phase 1 Audit Complete.")
