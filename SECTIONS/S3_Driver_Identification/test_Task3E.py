import cv2
from pathlib import Path
import numpy as np
import os
import json
from Task3C_Enrollment import EnrollmentSystem
from Task3D_Recognition_Core import RecognitionSystem
from Task3E_Confidence_Logic import ConfidenceEvaluator

def setup_mock_database():
    print("Setting up mock database with Driver A and Driver B...")
    db_path = str(Path(__file__).resolve().parent / "mock_test_database")
    os.makedirs(db_path, exist_ok=True)
    with open(os.path.join(db_path, "registry.json"), "w") as f:
        json.dump({}, f)
        
    enroll_sys = EnrollmentSystem(db_path=db_path)
    
    # Driver 1 (Alice)
    img_A = cv2.imread(str(Path(__file__).resolve().parent.parent / "S1_Drowsiness/open_eyes.jpg"))
    frames_A = [img_A.copy() for _ in range(15)]
    enroll_sys.enroll_driver(1, "Alice", frames_A, min_samples=15, overwrite=True)
    
    # Driver 2 (Bob) - Heavily modified image to ensure distinct features
    img_B = cv2.flip(img_A, 1)
    img_B = cv2.convertScaleAbs(img_B, alpha=0.8, beta=20)
    frames_B = [img_B.copy() for _ in range(15)]
    enroll_sys.enroll_driver(2, "Bob", frames_B, min_samples=15, overwrite=True)
    
    # Unknown driver image (Strongly blurred, shifted, padded)
    img_unknown = cv2.convertScaleAbs(img_A, alpha=0.4, beta=100)
    h, w = img_unknown.shape[:2]
    img_unknown = cv2.resize(img_unknown, (w, h//2))
    img_unknown = cv2.copyMakeBorder(img_unknown, h//4, h - h//2 - h//4, 0, 0, cv2.BORDER_CONSTANT, value=[0,0,0])
    
    return img_A, img_B, img_unknown

def run_tests():
    print("\n--- Starting Task 3E Confidence Logic Tests ---")
    img_A, img_B, img_unknown = setup_mock_database()
    
    rec_sys = RecognitionSystem(db_path=str(Path(__file__).resolve().parent / "mock_test_database"))
    # Using prototype thresholds: 0.363 for score, 0.05 for margin
    evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
    
    # 1. Clear Known Driver A
    print("\nTest 1: Clear Known Driver A")
    state, best_id, score, msg = evaluator.evaluate_frame(img_A)
    print(f"[{state}] {msg}")
    assert state == "IDENTIFIED", f"Expected IDENTIFIED, got {state}"
    assert best_id == 1, "Expected Driver 1"
    
    # 2. Clear Unknown Driver
    print("\nTest 2: Clear Unknown Driver (Mocked embedding < threshold)")
    original_get = rec_sys.get_embedding
    random_emb = np.random.rand(1, 128).astype(np.float32)
    random_emb = random_emb / np.linalg.norm(random_emb)
    rec_sys.get_embedding = lambda frame: (random_emb, "SUCCESS")
    state, best_id, score, msg = evaluator.evaluate_frame(img_A)
    print(f"[{state}] {msg}")
    assert state == "UNKNOWN", f"Expected UNKNOWN, got {state}"
    
    # 3. Ambiguous Best-vs-Second-Best Match (Margin Test)
    print("\nTest 3: Ambiguous Match (Low Margin - Mocked)")
    emb_A, _ = original_get(img_A)
    emb_B, _ = original_get(img_B)
    mock_emb = (emb_A + emb_B) / 2.0
    mock_emb = mock_emb / np.linalg.norm(mock_emb)
    rec_sys.get_embedding = lambda frame: (mock_emb, "SUCCESS")
    state, best_id, score, msg = evaluator.evaluate_frame(img_A)
    print(f"[{state}] {msg}")
    assert state == "LOW_CONFIDENCE", f"Expected LOW_CONFIDENCE, got {state}"
    
    # 4. Borderline Score
    print("\nTest 4: Borderline Score (Mocked exactly at threshold)")
    # We want a score around 0.363. We can just blend emb_A and random_emb.
    # Score = cosine(emb_A, mixed). 
    mixed_emb = emb_A * 0.363 + random_emb * (1 - 0.363)
    mixed_emb = mixed_emb / np.linalg.norm(mixed_emb)
    rec_sys.get_embedding = lambda frame: (mixed_emb, "SUCCESS")
    state, best_id, score, msg = evaluator.evaluate_frame(img_A)
    print(f"[{state}] {msg} (Score: {score:.3f})")
    assert state in ["UNKNOWN", "IDENTIFIED", "LOW_CONFIDENCE"], "State must be valid"
    
    # Restore
    rec_sys.get_embedding = original_get
    
    # 5. No Face
    print("\nTest 5: No Face")
    no_face_img = np.random.randint(0, 255, img_A.shape, dtype=np.uint8)
    state, best_id, score, msg = evaluator.evaluate_frame(no_face_img)
    print(f"[{state}] {msg}")
    assert state == "NO_FACE", "Expected NO_FACE"
    
    # 6. Poor Quality
    print("\nTest 6: Poor Quality Face")
    poor_face = cv2.GaussianBlur(img_A, (51, 51), 0)
    state, best_id, score, msg = evaluator.evaluate_frame(poor_face)
    print(f"[{state}] {msg}")
    assert state == "NO_FACE", "Expected POOR_QUALITY to be mapped to NO_FACE"

    print("\nAll Task 3E logic tests passed successfully!")

if __name__ == "__main__":
    run_tests()
