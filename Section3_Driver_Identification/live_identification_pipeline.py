import argparse
import cv2
import sys
import time
from Task3D_Recognition_Core import RecognitionSystem
from Task3E_Confidence_Logic import ConfidenceEvaluator
from Task3F_Temporal_Filter import TemporalStabilizer

def main():
    parser = argparse.ArgumentParser(description="Live Full Identification Pipeline (Task 3F)")
    args = parser.parse_args()
    
    print("Initializing Identification Pipeline...")
    try:
        rec_sys = RecognitionSystem()
        # Prototype Candidates (NOT scientifically validated thresholds)
        evaluator = ConfidenceEvaluator(rec_sys, candidate_threshold=0.363, candidate_margin=0.05)
        stabilizer = TemporalStabilizer(evaluator, persistence_frames=10)
    except Exception as e:
        print(f"Error initializing system: {e}")
        sys.exit(1)
        
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        sys.exit(1)
        
    print("Webcam opened successfully. Starting full pipeline.")
    print("Press 'q' or 'ESC' to exit.")
    
    prev_time = time.time()
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame from webcam.")
            break
            
        frame = cv2.flip(frame, 1)
        
        curr_time = time.time()
        fps = 1.0 / (curr_time - prev_time) if (curr_time - prev_time) > 0 else 0.0
        prev_time = curr_time
        
        # Process through full stack (Raw embedding -> Confidence thresholding -> Temporal stabilizing)
        c_state, c_id, r_state, r_id, raw_score, raw_msg = stabilizer.process_frame(frame)
        
        display_frame = frame.copy()
        
        # Format strings
        conf_driver_name = rec_sys.registry.get(str(c_id), "N/A") if c_id is not None else "NONE"
        cand_driver_name = rec_sys.registry.get(str(r_id), "N/A") if r_id is not None else "NONE"
        
        # Status Colors
        if c_state == "IDENTIFIED":
            color = (0, 255, 0)
        elif c_state == "NO_FACE":
            color = (200, 200, 200)
        elif c_state == "UNKNOWN":
            color = (0, 0, 255)
        else: # LOW_CONFIDENCE
            color = (0, 165, 255)
            
        cv2.putText(display_frame, f"FPS: {fps:.1f}", (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
        cv2.putText(display_frame, f"CONFIRMED STATE: {c_state}", (20, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
        cv2.putText(display_frame, f"CONFIRMED DRIVER: {c_id} ({conf_driver_name})", (20, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
        
        cv2.putText(display_frame, f"CANDIDATE STATE: {r_state}", (20, 160), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(display_frame, f"CANDIDATE DRIVER: {r_id} ({cand_driver_name})", (20, 190), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        score_val = raw_score if raw_score is not None else 0.0
        cv2.putText(display_frame, f"SIMILARITY: {score_val:.4f}", (20, 220), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(display_frame, f"PERSISTENCE: {stabilizer.candidate_counter} / 10", (20, 250), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        cv2.imshow("Live Identification Pipeline", display_frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            print("Live pipeline terminated by user.")
            break
            
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
