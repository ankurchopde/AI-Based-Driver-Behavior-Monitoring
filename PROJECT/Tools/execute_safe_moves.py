import os
import shutil
import csv
import datetime
import hashlib

def get_file_hash(filepath):
    hasher = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            while chunk := f.read(8192):
                hasher.update(chunk)
        return hasher.hexdigest()
    except Exception:
        return "ERROR"

def safe_move(src_dir, dump_dir):
    manifest_path = os.path.join(dump_dir, "MOVE_MANIFEST.csv")
    os.makedirs(dump_dir, exist_ok=True)
    
    # Initialize manifest
    file_exists = os.path.exists(manifest_path)
    with open(manifest_path, 'a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(['OriginalPath', 'NewPath', 'FileName', 'Category', 'ReasonMoved', 'Hash', 'Size', 'ReferencedBy', 'DateMoved', 'Status'])
        
        for dirpath, dirnames, filenames in os.walk(src_dir, topdown=False):
            rel_dir = os.path.relpath(dirpath, src_dir)
            
            # Determine if this folder is a cache folder
            is_cache = '__pycache__' in rel_dir or 'slprj' in rel_dir
            if not is_cache:
                continue
                
            for filename in filenames:
                orig_path = os.path.join(dirpath, filename)
                new_dir = os.path.join(dump_dir, 'temporary_files', rel_dir)
                new_path = os.path.join(new_dir, filename)
                
                os.makedirs(new_dir, exist_ok=True)
                
                # Get metadata
                try:
                    size = os.path.getsize(orig_path)
                    f_hash = get_file_hash(orig_path)
                except:
                    continue
                
                # Move file
                try:
                    shutil.move(orig_path, new_path)
                    writer.writerow([orig_path, new_path, filename, 'temporary_files', 'Cache/generated file', f_hash, size, 'None', datetime.datetime.now().isoformat(), 'ARCHIVED'])
                except Exception as e:
                    print(f"Failed to move {orig_path}: {e}")
                    
            # Try to remove empty dir
            try:
                os.rmdir(dirpath)
            except:
                pass

if __name__ == "__main__":
    src = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"
    dump = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector_DUMP"
    safe_move(src, dump)
    print("Safe moves completed.")
