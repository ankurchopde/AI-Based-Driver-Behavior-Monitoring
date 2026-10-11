import cv2
import numpy as np
import os
import json
import matplotlib.pyplot as plt
from Task3C_Enrollment import EnrollmentSystem
from Task3D_Recognition_Core import RecognitionSystem
from Task3E_Confidence_Logic import ConfidenceEvaluator
from Task3F_Temporal_Filter import TemporalStabilizer

def augment_image(img, brightness_shift=0, contrast_scale=1.0, blur=0, rotation=0):
    h, w = img.shape[:2]
    # Brightness / Contrast
    aug = cv2.convertScaleAbs(img, alpha=contrast_scale, beta=brightness_shift)
    # Rotation
    if rotation != 0:
        M = cv2.getRotationMatrix2D((w/2, h/2), rotation, 1)
        aug = cv2.warpAffine(aug, M, (w, h), borderMode=cv2.BORDER_REPLICATE)
    # Blur
    if blur > 0:
        aug = cv2.GaussianBlur(aug, (blur, blur), 0)
    return aug

def generate_samples(base_img, num_samples, variation_level="mild"):
    samples = []
    for i in range(num_samples):
        if variation_level == "mild":
            b = np.random.randint(-20, 20)
            c = np.random.uniform(0.9, 1.1)
            rot = np.random.uniform(-5, 5)
            blur = 0
        elif variation_level == "moderate":
            b = np.random.randint(-50, 50)
            c = np.random.uniform(0.7, 1.3)
            rot = np.random.uniform(-15, 15)
            blur = np.random.choice([0, 3, 5])
        
        aug = augment_image(base_img, b, c, blur, rot)
        samples.append(aug)
    return samples

def run_validation():
    print("--- TASK 3G VALIDATION ---")
    img_A = cv2.imread(str(Path(__file__).resolve().parent.parent / "S1_Drowsiness/open_eyes.jpg"))
    img_B = cv2.flip(img_A, 1)
    
    # 1. ENROLLMENT (Mild variations)
    print("\n1. Enrolling Drivers...")
    db_path = "database"
    if os.path.exists(db_path):
        import shutil
        shutil.rmtree(db_path, ignore_errors=True)
    os.makedirs(db_path, exist_ok=True)
    with open(os.path.join(db_path, "registry.json"), "w") as f: json.dump({}, f)
        
    enroll_sys = EnrollmentSystem()
    frames_A_enroll = generate_samples(img_A, 20, "mild")
    frames_B_enroll = generate_samples(img_B, 20, "mild")
    
    resA, msgA = enroll_sys.enroll_driver(1, "Alice", frames_A_enroll, min_samples=15, overwrite=True)
    resB, msgB = enroll_sys.enroll_driver(2, "Bob", frames_B_enroll, min_samples=15, overwrite=True)
    print("Enroll A:", msgA)
    print("Enroll B:", msgB)
    
    if not (resA and resB):
        print("Enrollment failed. Aborting validation.")
        return
        
    # 2. EVALUATION DATASET (Moderate variations)
    print("\n2. Generating Evaluation Dataset...")
    eval_A = generate_samples(img_A, 100, "moderate")
    eval_B = generate_samples(img_B, 100, "moderate")
    
    rec_sys = RecognitionSystem()
    evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
    
    genuine_scores = []
    impostor_scores = []
    margins = []
    
    print("\n3. Collecting Scores...")
    # Test Alice images (Genuine for A, Impostor for B)
    for img in eval_A:
        state, best_id, score, msg = evaluator.evaluate_frame(img)
        if best_id == 1:
            genuine_scores.append(score)
            # Find margin
            # To get margin accurately from ConfidenceEvaluator, we have to look inside or parse message.
            # But we can just use the score.
        elif best_id == 2:
            impostor_scores.append(score)
            
    # Test Bob images (Genuine for B, Impostor for A)
    for img in eval_B:
        state, best_id, score, msg = evaluator.evaluate_frame(img)
        if best_id == 2:
            genuine_scores.append(score)
        elif best_id == 1:
            impostor_scores.append(score)
            
    print(f"Collected {len(genuine_scores)} genuine scores and {len(impostor_scores)} impostor scores.")
    
    if genuine_scores:
        print(f"Genuine Scores -> Min: {min(genuine_scores):.4f}, Max: {max(genuine_scores):.4f}, Mean: {np.mean(genuine_scores):.4f}")
    if impostor_scores:
        print(f"Impostor Scores -> Min: {min(impostor_scores):.4f}, Max: {max(impostor_scores):.4f}, Mean: {np.mean(impostor_scores):.4f}")
        
    # Temporal Test
    print("\n4. Temporal Identity Stability Test...")
    temporal = TemporalStabilizer(evaluator, persistence_frames=10)
    
    # 20 frames A -> 15 frames B -> 20 frames A
    sequence = generate_samples(img_A, 20, "mild") + generate_samples(img_B, 15, "mild") + generate_samples(img_A, 20, "mild")
    
    transitions = []
    current = "NO_FACE"
    for i, frame in enumerate(sequence):
        c_state, c_id, r_state, r_id, score, msg = temporal.process_frame(frame)
        if c_state != current:
            transitions.append((i, c_state, c_id))
            current = c_state
            
    print("Temporal Transitions:")
    for t in transitions:
        print(f"Frame {t[0]}: Switched to {t[1]} (ID {t[2]})")
        
    print("\nValidation Complete. Please review the scores to adjust threshold if necessary.")

if __name__ == "__main__":
    run_validation()
