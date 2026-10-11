import argparse
import cv2
import sys
import time
from Task3D_Recognition_Core import RecognitionSystem

def main():
    parser = argparse.ArgumentParser(description="Live Webcam Driver Recognition (Raw Nearest-Neighbor)")
    args = parser.parse_args()
    
    print("Initializing Recognition System...")
    try:
        rec_sys = RecognitionSystem()
    except Exception as e:
        print(f"Error initializing Recognition System: {e}")
        sys.exit(1)
        
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        sys.exit(1)
        
    print("Webcam opened successfully. Starting live recognition.")
    print("Press 'q' or 'ESC' to exit.")
    
    prev_time = time.time()
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame from webcam.")
            break
            
        frame = cv2.flip(frame, 1)
        
        # Calculate FPS
        curr_time = time.time()
        fps = 1.0 / (curr_time - prev_time) if (curr_time - prev_time) > 0 else 0.0
        prev_time = curr_time
        
        # Pass to Recognition System (Raw match without thresholding)
        best_id, best_score, msg = rec_sys.recognize_frame(frame)
        
        display_frame = frame.copy()
        
        # Determine Color based on status
        if msg in ["NO_FACE", "POOR_QUALITY", "NO_DRIVERS_ENROLLED"]:
            color = (0, 0, 255)
            driver_text = "NONE"
            score_text = "0.000"
            status_text = msg
        else:
            color = (0, 255, 0)
            driver_name = rec_sys.registry.get(str(best_id), "Unknown")
            driver_text = f"ID: {best_id} ({driver_name})"
            score_text = f"{best_score:.4f}"
            status_text = "MATCHED"
            
        # Draw on frame
        cv2.putText(display_frame, f"FPS: {fps:.1f}", (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
        cv2.putText(display_frame, f"Driver: {driver_text}", (20, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        cv2.putText(display_frame, f"Score: {score_text}", (20, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        cv2.putText(display_frame, f"Status: {status_text}", (20, 150), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        
        cv2.imshow("Live Raw Recognition (No Thresholding)", display_frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            print("Live recognition terminated by user.")
            break
            
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
