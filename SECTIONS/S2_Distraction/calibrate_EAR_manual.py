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
    sock.setblocking(False)

    print("Listening for UDP stream on port 5000...")
    while True:
        try:
            data, _ = sock.recvfrom(24)
            break
        except socket.error:
            time.sleep(0.1)

    print("Connection established. UI Window Opening...")

    dataset = []
    start_time = time.time()
    
    cv2.namedWindow("EAR Manual Calibration", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("EAR Manual Calibration", 700, 500)
    
    current_recording_state = None
    recording_end_time = 0.0

    while True:
        # Drain UDP queue to guarantee LIVE data
        queue_size = 0
        latest_data = None
        while True:
            try:
                data, _ = sock.recvfrom(24)
                latest_data = data
                queue_size += 1
            except socket.error:
                break
                
        key = cv2.waitKey(1) & 0xFF
        if key == ord('o') or key == ord('O'):
            current_recording_state = "OPEN"
            recording_end_time = time.time() + 3.0
            print("Recording 3 seconds of OPEN eyes...")
        elif key == ord('c') or key == ord('C'):
            current_recording_state = "CLOSED"
            recording_end_time = time.time() + 3.0
            print("Recording 3 seconds of CLOSED eyes...")
        elif key == ord('q') or key == ord('Q') or key == 27:
            break
            
        if current_recording_state and time.time() >= recording_end_time:
            print(f"Finished recording {current_recording_state} block.")
            current_recording_state = None

        if latest_data is not None:
            est_latency_ms = 0.0 if queue_size <= 1 else 33.3
            status = "LIVE"
            
            face, eye, ear = struct.unpack('<3d', latest_data)
            t_stamp = time.time() - start_time
            
            if current_recording_state:
                dataset.append((t_stamp, ear, current_recording_state, est_latency_ms))
            
            # Draw UI
            img = np.zeros((500, 700, 3), dtype=np.uint8)
            
            cv2.putText(img, "Press 'O' to record OPEN (3s)", (30, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            cv2.putText(img, "Press 'C' to record CLOSED (3s)", (30, 90), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            cv2.putText(img, "Press 'Q' to finish and analyze", (30, 130), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            
            cv2.putText(img, f"LIVE EAR: {ear:.3f}", (30, 220), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)
            
            if current_recording_state:
                cv2.putText(img, f"RECORDING: {current_recording_state}", (30, 300), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 255), 4)
                time_left = recording_end_time - time.time()
                cv2.putText(img, f"Time left: {time_left:.1f}s", (30, 350), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 255), 2)
            else:
                cv2.putText(img, "IDLE (Not Recording)", (30, 300), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (100, 100, 100), 3)
            
            cv2.putText(img, f"Total Samples: {len(dataset)}", (30, 420), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
            cv2.putText(img, f"Network: {status} (Age ~{est_latency_ms:.1f}ms)", (30, 460), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
            cv2.imshow("EAR Manual Calibration", img)
        else:
            time.sleep(0.01)

    cv2.destroyAllWindows()
    sock.close()

    if len(dataset) < 10:
        print("Not enough data collected for analysis.")
        return

    # Save CSV
    with open('EAR_manual_calibration.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Timestamp', 'EAR', 'State', 'PacketAge'])
        writer.writerows(dataset)

    # Analysis
    timestamps = np.array([x[0] for x in dataset])
    ears = np.array([x[1] for x in dataset])
    states = np.array([x[2] for x in dataset])

    open_ears = ears[states == "OPEN"]
    closed_ears = ears[states == "CLOSED"]

    def calc_stats(arr):
        if len(arr) == 0:
            return {'n':0, 'min':0, 'max':0, 'mean':0, 'median':0, 'std':0, 'p5':0, 'p95':0}
        return {
            'n': len(arr), 'min': np.min(arr), 'max': np.max(arr),
            'mean': np.mean(arr), 'median': np.median(arr), 'std': np.std(arr),
            'p5': np.percentile(arr, 5), 'p95': np.percentile(arr, 95)
        }

    open_stats = calc_stats(open_ears)
    closed_stats = calc_stats(closed_ears)

    diff_mean = open_stats['mean'] - closed_stats['mean']
    diff_median = open_stats['median'] - closed_stats['median']
    overlap = max(0, closed_stats['max'] - open_stats['min'])

    thresholds = np.linspace(min(closed_stats['min'], open_stats['min']), max(closed_stats['max'], open_stats['max']), 200)
    best_thresh = 0
    best_acc = 0
    best_metrics = {}

    for t in thresholds:
        tp = np.sum(closed_ears < t)
        fn = np.sum(closed_ears >= t)
        tn = np.sum(open_ears >= t)
        fp = np.sum(open_ears < t)
        
        acc = (tp + tn) / len(ears)
        sens = tp / (tp + fn) if (tp + fn) > 0 else 0
        spec = tn / (tn + fp) if (tn + fp) > 0 else 0
        
        if acc > best_acc:
            best_acc = acc
            best_thresh = t
            best_metrics = {
                'acc': acc, 'sens': sens, 'spec': spec,
                'fp_rate': fp / (fp + tn) if (fp + tn) > 0 else 0,
                'fn_rate': fn / (fn + tp) if (fn + tp) > 0 else 0
            }

    # Strict Validation Rule
    if open_stats['mean'] > closed_stats['mean'] and best_acc > 0.85:
        validation_status = "EAR FOUNDATION = VALIDATED"
    else:
        validation_status = "EAR FOUNDATION = NOT VALIDATED"

    report = f"""MANUAL EAR CALIBRATION REPORT

-- STATISTICS --
Open-eye (N={open_stats['n']}): 
  Min={open_stats['min']:.4f} | Max={open_stats['max']:.4f} | Mean={open_stats['mean']:.4f} 
  Median={open_stats['median']:.4f} | Std={open_stats['std']:.4f} 
  5th%={open_stats['p5']:.4f} | 95th%={open_stats['p95']:.4f}

Closed-eye (N={closed_stats['n']}): 
  Min={closed_stats['min']:.4f} | Max={closed_stats['max']:.4f} | Mean={closed_stats['mean']:.4f} 
  Median={closed_stats['median']:.4f} | Std={closed_stats['std']:.4f} 
  5th%={closed_stats['p5']:.4f} | 95th%={closed_stats['p95']:.4f}

Mean Separation: {diff_mean:.4f}
Median Separation: {diff_median:.4f}
Distribution Overlap: {overlap:.4f}

-- OPTIMAL SEPARATION METRICS --
Best Candidate Threshold: {best_thresh:.4f}
Accuracy: {best_metrics.get('acc', 0)*100:.2f}%
Sensitivity (True Closed Rate): {best_metrics.get('sens', 0)*100:.2f}%
Specificity (True Open Rate): {best_metrics.get('spec', 0)*100:.2f}%
False-open rate: {best_metrics.get('fn_rate', 0)*100:.2f}%
False-closed rate: {best_metrics.get('fp_rate', 0)*100:.2f}%

FINAL VERDICT:
{validation_status}
"""
    with open('EAR_manual_report.txt', 'w') as f:
        f.write(report)

    # Plot 1: Timeline
    plt.figure(figsize=(10, 5))
    plt.plot(timestamps, ears, label='EAR Signal', color='black', linewidth=1.5)
    
    # Shade only the regions that were recorded
    for i in range(len(timestamps)-1):
        if timestamps[i+1] - timestamps[i] < 0.2: # If points are consecutive
            color = 'lightgreen' if states[i] == 'OPEN' else 'lightcoral'
            plt.axvspan(timestamps[i], timestamps[i+1], color=color, alpha=0.5)
            
    plt.axhline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('Time (s)')
    plt.ylabel('EAR')
    plt.title('EAR Temporal Signal (Manual Ground Truth)')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_manual_calibration_plot.png')
    plt.close()

    # Plot 2: Distribution
    plt.figure(figsize=(8, 5))
    plt.hist(open_ears, bins=30, alpha=0.6, color='green', label='Open Eyes')
    plt.hist(closed_ears, bins=30, alpha=0.6, color='red', label='Closed Eyes')
    plt.axvline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('EAR')
    plt.ylabel('Frequency')
    plt.title('EAR Distribution (Manual Ground Truth)')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_manual_distribution.png')
    plt.close()

    print("\nManual Calibration Complete!")
    print(validation_status)
    print("Report saved to EAR_manual_report.txt")

if __name__ == '__main__':
    main()
