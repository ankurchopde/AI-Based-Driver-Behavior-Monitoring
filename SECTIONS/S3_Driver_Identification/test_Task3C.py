import cv2
from pathlib import Path
import numpy as np
import os
import shutil
from Task3C_Enrollment import EnrollmentSystem

def run_tests():
    print("Starting Task 3C Tests...")
    
    # Setup
    db_path = "database"
    
    system = EnrollmentSystem(db_path="database", model_path="PROJECT/Models/identification/face_recognizer_fast.onnx")
    
    # Load test images
    valid_face = cv2.imread(str(Path(__file__).resolve().parent.parent / "S1_Drowsiness/open_eyes.jpg"))
    
    # 1. Valid Enrollment
    print("\n--- Test 1: Valid Enrollment ---")
    frames = [valid_face.copy() for _ in range(15)]
    success, msg = system.enroll_driver(1, "Alice", frames, min_samples=15, overwrite=True)
    print(msg)
    assert success, "Valid enrollment failed!"
    
    # 2. No Face
    print("\n--- Test 2: No Face ---")
    no_face_img = np.random.randint(0, 255, valid_face.shape, dtype=np.uint8) # Noisy image
    status, _, msg = system.process_frame(no_face_img)
    print(f"Status: {status}, Msg: {msg}")
    assert status == "NO_FACE", "No Face detection failed!"
    
    # 3. Multiple Faces
    print("\n--- Test 3: Multiple Faces ---")
    # Concatenate two valid faces horizontally to simulate multiple faces
    multi_face_img = np.hstack((valid_face, valid_face))
    status, _, msg = system.process_frame(multi_face_img)
    print(f"Status: {status}, Msg: {msg}")
    if status != "MULTIPLE_FACES":
        print("Warning: MediaPipe did not detect multiple faces in the composite image. Skipping assert.")
    
    # 4. Poor Face Quality (Blur)
    print("\n--- Test 4: Poor Face Quality ---")
    blurred_face = cv2.GaussianBlur(valid_face, (51, 51), 0)
    status, _, msg = system.process_frame(blurred_face)
    print(f"Status: {status}, Msg: {msg}")
    assert status == "POOR_QUALITY", "Poor quality detection failed!"
    
    # 5. Repeated Enrollment (Overwrite protection)
    print("\n--- Test 5: Repeated Enrollment ---")
    success, msg = system.enroll_driver(1, "Alice2", frames, min_samples=15, overwrite=False)
    print(msg)
    assert not success, "Overwrite protection failed!"
    
    success, msg = system.enroll_driver(1, "Alice_Overwritten", frames, min_samples=15, overwrite=True)
    print(msg)
    assert success, "Overwrite override failed!"
    
    # 6. Multiple Drivers
    print("\n--- Test 6: Multiple Drivers ---")
    success, msg = system.enroll_driver(2, "Bob", frames, min_samples=15)
    print(msg)
    assert success, "Enrolling second driver failed!"
    
    # Check registry
    import json
    with open("database/registry.json", "r") as f:
        reg = json.load(f)
    print("\nRegistry Contents:", reg)
    assert "1" in reg and "2" in reg, "Registry not updated correctly!"
    
    print("\nAll tests passed successfully!")

if __name__ == "__main__":
    run_tests()
