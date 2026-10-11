import os
import hashlib
import csv
import datetime

def get_file_hash(filepath):
    hasher = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            while chunk := f.read(8192):
                hasher.update(chunk)
        return hasher.hexdigest()
    except Exception as e:
        return f"ERROR: {e}"

def audit_directory(root_dir, output_csv):
    with open(output_csv, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['FullPath', 'RelativePath', 'FileName', 'Extension', 'SizeBytes', 'ModifiedDate', 'SHA256'])
        
        for dirpath, dirnames, filenames in os.walk(root_dir):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                relpath = os.path.relpath(filepath, root_dir)
                ext = os.path.splitext(filename)[1].lower()
                
                try:
                    size = os.path.getsize(filepath)
                    mtime = os.path.getmtime(filepath)
                    mod_date = datetime.datetime.fromtimestamp(mtime).isoformat()
                except Exception as e:
                    size = -1
                    mod_date = f"ERROR: {e}"
                
                file_hash = get_file_hash(filepath)
                
                writer.writerow([filepath, relpath, filename, ext, size, mod_date, file_hash])

if __name__ == "__main__":
    target_dir = r"d:\Academics\TY_SEM1\AE\AI based Driver Detector"
    output_file = "repository_inventory.csv"
    audit_directory(target_dir, output_file)
    print(f"Inventory saved to {output_file}")
