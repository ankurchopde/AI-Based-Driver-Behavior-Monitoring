import cv2
from pathlib import Path
import numpy as np
import os
import shutil
import json
from Task3C_Enrollment import EnrollmentSystem
from Task3D_Recognition_Core import RecognitionSystem

def setup_mock_database():
    print("Setting up mock database with Driver A and Driver B...")
    db_path = str(Path(__file__).resolve().parent / "mock_test_database")
    os.makedirs(db_path, exist_ok=True)
    with open(os.path.join(db_path, "registry.json"), "w") as f:
        json.dump({}, f)
        
    enroll_sys = EnrollmentSystem(db_path=db_path)
    
    # Base image for Driver A
    img_A = cv2.imread(str(Path(__file__).resolve().parent.parent / "S1_Drowsiness/open_eyes.jpg"))
    frames_A = [img_A.copy() for _ in range(15)]
    resA, msgA = enroll_sys.enroll_driver(1, "Alice", frames_A, min_samples=15, overwrite=True)
    print("Enroll A:", msgA)
    
    # Flipped image for Driver B (simulate another person)
    img_B = cv2.flip(img_A, 1)
    frames_B = [img_B.copy() for _ in range(15)]
    resB, msgB = enroll_sys.enroll_driver(2, "Bob", frames_B, min_samples=15, overwrite=True)
    print("Enroll B:", msgB)
    
    return img_A, img_B

def run_tests():
    print("\n--- Starting Task 3D Recognition Tests ---")
    img_A, img_B = setup_mock_database()
    
    rec_sys = RecognitionSystem(db_path=str(Path(__file__).resolve().parent / "mock_test_database"))
    
    # 1. Driver A
    print("\nTest 1: Known Driver A (Alice)")
    best_id, score, msg = rec_sys.recognize_frame(img_A)
    print(msg)
    assert best_id == 1, f"Expected Driver 1, got {best_id}"
    assert score > 0.9, f"Expected score > 0.9, got {score}"
    
    # 2. Driver B
    print("\nTest 2: Known Driver B (Bob)")
    best_id, score, msg = rec_sys.recognize_frame(img_B)
    print(msg)
    assert best_id == 2, f"Expected Driver 2, got {best_id}"
    assert score > 0.9, f"Expected score > 0.9, got {score}"
    
    # 3. Unknown Driver (Modified image)
    print("\nTest 3: Unknown Driver")
    # Simulate unknown by warping the image colors heavily or applying strong transformations
    img_unknown = img_A.copy()
    img_unknown = cv2.convertScaleAbs(img_unknown, alpha=0.5, beta=50) # change contrast/brightness
    # We also resize it slightly and pad to warp facial structure
    h, w = img_unknown.shape[:2]
    img_unknown = cv2.resize(img_unknown, (w, h//2))
    img_unknown = cv2.copyMakeBorder(img_unknown, h//4, h - h//2 - h//4, 0, 0, cv2.BORDER_CONSTANT, value=[0,0,0])
    
    best_id, score, msg = rec_sys.recognize_frame(img_unknown)
    print(msg)
    # The score should be notably lower than 0.9, though the exact drop depends on SFace.
    # We are not testing the threshold yet, just that it returns a score and best match.
    print(f"Unknown driver simulated match: Driver {best_id} with score {score}")
    assert best_id is not None, "Should still return a best match (unknown logic not active)"
    
    # 4. No Face
    print("\nTest 4: No Face")
    no_face_img = np.random.randint(0, 255, img_A.shape, dtype=np.uint8)
    best_id, score, msg = rec_sys.recognize_frame(no_face_img)
    print(msg)
    assert best_id is None and msg == "NO_FACE", "Should return NO_FACE"
    
    # 5. Poor Quality Face
    print("\nTest 5: Poor Quality Face")
    poor_face = cv2.GaussianBlur(img_A, (51, 51), 0)
    best_id, score, msg = rec_sys.recognize_frame(poor_face)
    print(msg)
    assert best_id is None and msg == "POOR_QUALITY", "Should return POOR_QUALITY"

    print("\nAll Task 3D tests passed successfully!")

if __name__ == "__main__":
    run_tests()
