import argparse
import cv2
import sys
from Task3C_Enrollment import EnrollmentSystem

def main():
    parser = argparse.ArgumentParser(description="Live Webcam Driver Enrollment")
    parser.add_argument("--id", type=int, required=True, help="Numeric Driver ID")
    parser.add_argument("--name", type=str, required=True, help="Driver Name")
    parser.add_argument("--samples", type=int, default=20, help="Number of valid samples to collect (default: 20)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing driver ID")
    
    args = parser.parse_args()
    
    print(f"Initializing Enrollment System for Driver {args.id}: {args.name}")
    try:
        enroll_sys = EnrollmentSystem()
    except Exception as e:
        print(f"Error initializing Enrollment System: {e}")
        sys.exit(1)
    
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        sys.exit(1)
        
    collected_frames = []
    
    print(f"Webcam opened successfully. Collecting {args.samples} valid samples.")
    print("Press 'q' or 'ESC' to abort.")
    
    while len(collected_frames) < args.samples:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame from webcam.")
            break
            
        frame = cv2.flip(frame, 1)
        
        # Check frame validity
        status, embedding, msg = enroll_sys.process_frame(frame)
        
        display_frame = frame.copy()
        
        if status == "SUCCESS":
            collected_frames.append(frame.copy())
            color = (0, 255, 0)
        else:
            color = (0, 0, 255)
            
        cv2.putText(display_frame, f"Driver: {args.name} (ID: {args.id})", (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        cv2.putText(display_frame, f"Samples: {len(collected_frames)} / {args.samples}", (20, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
        cv2.putText(display_frame, f"Status: {msg}", (20, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        
        cv2.imshow("Live Enrollment", display_frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            print("Enrollment aborted by user.")
            cap.release()
            cv2.destroyAllWindows()
            sys.exit(0)
            
    cap.release()
    cv2.destroyAllWindows()
    
    if len(collected_frames) == args.samples:
        print(f"\nSuccessfully collected {args.samples} samples. Saving to database...")
        success, final_msg = enroll_sys.enroll_driver(args.id, args.name, collected_frames, min_samples=args.samples, overwrite=args.overwrite)
        
        if success:
            print(f"Enrollment Complete: {final_msg}")
        else:
            print(f"Enrollment Failed: {final_msg}")
            sys.exit(1)

if __name__ == "__main__":
    main()
