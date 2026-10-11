import socket
import struct
import time
import csv
import numpy as np
import matplotlib.pyplot as plt
import cv2

UDP_IP = "127.0.0.1"
UDP_PORT = 5000

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    sock.settimeout(0.5)

    print("Listening for UDP stream on port 5000...")
    print("Ensure mediapipe_udp_sender.py is running!")

    # Wait for first packet
    while True:
        try:
            data, _ = sock.recvfrom(24)
            break
        except socket.timeout:
            print("Waiting for mediapipe_udp_sender.py...")
            time.sleep(0.5)

    print("Connection established. Starting calibration sequence in 3 seconds...")
    time.sleep(3)

    # Sequence: 
    # 0-5s: OPEN, 5-8s: CLOSED, 8-13s: OPEN, 13-16s: CLOSED, 16-21s: OPEN
    sequence = [
        (5.0, "OPEN"),
        (3.0, "CLOSED"),
        (5.0, "OPEN"),
        (3.0, "CLOSED"),
        (5.0, "OPEN")
    ]

    dataset = []
    start_time = time.time()
    
    # UI Window
    cv2.namedWindow("EAR Calibration Tracker", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("EAR Calibration Tracker", 600, 400)
    
    current_time = 0.0
    
    for duration, state in sequence:
        phase_start = time.time()
        
        while (time.time() - phase_start) < duration:
            # DRAIN QUEUE TO GET NEWEST PACKET
            latest_data = None
            sock.setblocking(False)
            while True:
                try:
                    data, _ = sock.recvfrom(24)
                    latest_data = data
                except socket.error:
                    break
            
            if latest_data is not None:
                face, eye, ear = struct.unpack('<3d', latest_data)
                
                t_stamp = time.time() - start_time
                dataset.append((t_stamp, ear, face, eye, state))
                
                # UI
                img = np.zeros((400, 600, 3), dtype=np.uint8)
                
                # Draw instructions
                color = (0, 255, 0) if state == "OPEN" else (0, 0, 255)
                cv2.putText(img, f"ACTION: {state}", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 2, color, 4)
                cv2.putText(img, f"EAR: {ear:.3f}", (50, 200), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)
                cv2.putText(img, f"Samples: {len(dataset)}", (50, 300), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
                
                time_left = duration - (time.time() - phase_start)
                cv2.putText(img, f"Time left: {time_left:.1f}s", (50, 350), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
                
                cv2.imshow("EAR Calibration Tracker", img)
                cv2.waitKey(1)
            else:
                time.sleep(0.01)

    cv2.destroyAllWindows()
    sock.close()
    print(f"Collection complete. {len(dataset)} samples collected.")

    # Save CSV
    with open('EAR_calibration_data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Timestamp', 'EAR', 'FaceDetected', 'EyeDetected', 'State'])
        writer.writerows(dataset)

    # Analysis
    timestamps = np.array([x[0] for x in dataset])
    ears = np.array([x[1] for x in dataset])
    states = np.array([x[4] for x in dataset])

    open_ears = ears[states == "OPEN"]
    closed_ears = ears[states == "CLOSED"]

    def calc_stats(arr):
        if len(arr) == 0: return {}
        return {
            'n': len(arr),
            'min': np.min(arr),
            'max': np.max(arr),
            'mean': np.mean(arr),
            'median': np.median(arr),
            'std': np.std(arr),
            'p5': np.percentile(arr, 5),
            'p95': np.percentile(arr, 95)
        }

    open_stats = calc_stats(open_ears)
    closed_stats = calc_stats(closed_ears)

    diff_mean = open_stats['mean'] - closed_stats['mean']
    diff_median = open_stats['median'] - closed_stats['median']
    overlap = max(0, closed_stats['max'] - open_stats['min'])

    # Threshold Optimization
    thresholds = np.linspace(closed_stats['min'], open_stats['max'], 200)
    best_thresh = 0
    best_acc = 0
    best_metrics = {}

    for t in thresholds:
        # Predict CLOSED if EAR < t
        tp = np.sum(closed_ears < t) # True Closed
        fn = np.sum(closed_ears >= t) # False Open (Missed closure)
        tn = np.sum(open_ears >= t) # True Open
        fp = np.sum(open_ears < t) # False Closed (False alarm)
        
        acc = (tp + tn) / len(ears)
        sens = tp / (tp + fn) if (tp + fn) > 0 else 0 # Sensitivity (True closed rate)
        spec = tn / (tn + fp) if (tn + fp) > 0 else 0 # Specificity (True open rate)
        
        if acc > best_acc:
            best_acc = acc
            best_thresh = t
            best_metrics = {
                'acc': acc,
                'sens': sens,
                'spec': spec,
                'fp_rate': fp / (fp + tn) if (fp + tn) > 0 else 0,
                'fn_rate': fn / (fn + tp) if (fn + tp) > 0 else 0
            }

    separation_qual = "POOR"
    if best_acc > 0.95 and overlap < 0.05:
        separation_qual = "GOOD"
    elif best_acc > 0.85:
        separation_qual = "MODERATE"

    # Generate Report
    report = f"""EAR CALIBRATION REPORT

Open-eye statistics:
N = {open_stats['n']}
Min = {open_stats['min']:.4f}
Max = {open_stats['max']:.4f}
Mean = {open_stats['mean']:.4f}
Median = {open_stats['median']:.4f}
Std = {open_stats['std']:.4f}
5th Percentile = {open_stats['p5']:.4f}
95th Percentile = {open_stats['p95']:.4f}

Closed-eye statistics:
N = {closed_stats['n']}
Min = {closed_stats['min']:.4f}
Max = {closed_stats['max']:.4f}
Mean = {closed_stats['mean']:.4f}
Median = {closed_stats['median']:.4f}
Std = {closed_stats['std']:.4f}
5th Percentile = {closed_stats['p5']:.4f}
95th Percentile = {closed_stats['p95']:.4f}

Difference between Means: {diff_mean:.4f}
Difference between Medians: {diff_median:.4f}
Distribution Overlap (Closed Max - Open Min): {overlap:.4f}

Best candidate threshold: {best_thresh:.4f}

Accuracy: {best_metrics['acc']*100:.2f}%
Sensitivity (True Closed Rate): {best_metrics['sens']*100:.2f}%
Specificity (True Open Rate): {best_metrics['spec']*100:.2f}%
False-open rate: {best_metrics['fn_rate']*100:.2f}%
False-closed rate: {best_metrics['fp_rate']*100:.2f}%

SEPARATION QUALITY: {separation_qual}

CONCLUSION:
"""
    if separation_qual == "POOR":
        report += "EAR separation is insufficient; additional calibration or landmark/measurement improvements are required.\n"
    else:
        report += "EAR separation is sufficient for proceeding to temporal eye-closure/drowsiness logic.\n"

    with open('EAR_calibration_report.txt', 'w') as f:
        f.write(report)

    # Plot 1: Timeline
    plt.figure(figsize=(10, 5))
    plt.plot(timestamps, ears, label='EAR Signal', color='black')
    
    # Shade regions
    for i in range(len(timestamps)-1):
        color = 'lightgreen' if states[i] == 'OPEN' else 'lightcoral'
        plt.axvspan(timestamps[i], timestamps[i+1], color=color, alpha=0.3)
        
    plt.axhline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('Time (s)')
    plt.ylabel('EAR')
    plt.title('EAR Temporal Signal vs Ground Truth State')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_calibration_plot.png')
    plt.close()

    # Plot 2: Distribution
    plt.figure(figsize=(8, 5))
    plt.hist(open_ears, bins=30, alpha=0.6, color='green', label='Open Eyes')
    plt.hist(closed_ears, bins=30, alpha=0.6, color='red', label='Closed Eyes')
    plt.axvline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('EAR')
    plt.ylabel('Frequency')
    plt.title('EAR Distribution')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_distribution_plot.png')
    plt.close()

    print("\nCalibration Analysis Complete.")
    print("Files generated:")
    print(" - EAR_calibration_data.csv")
    print(" - EAR_calibration_report.txt")
    print(" - EAR_calibration_plot.png")
    print(" - EAR_distribution_plot.png")

if __name__ == '__main__':
    main()
