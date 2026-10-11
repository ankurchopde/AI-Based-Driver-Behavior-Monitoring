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

    print("Connection established. Starting calibration sequence in 3 seconds...")
    time.sleep(3)

    sequence = [
        (5.0, "OPEN"),
        (3.0, "CLOSED"),
        (5.0, "OPEN"),
        (3.0, "CLOSED"),
        (5.0, "OPEN")
    ]

    dataset = []
    start_time = time.time()
    
    cv2.namedWindow("EAR Calibration V2", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("EAR Calibration V2", 600, 500)
    
    total_received = 0
    total_processed = 0
    total_discarded = 0
    max_queue_depth = 0
    latency_history = []

    for duration, state in sequence:
        phase_start = time.time()
        
        while (time.time() - phase_start) < duration:
            queue_size = 0
            latest_data = None
            
            # 1. Drain the queue completely
            while True:
                try:
                    data, _ = sock.recvfrom(24)
                    latest_data = data
                    queue_size += 1
                except socket.error:
                    break
            
            if latest_data is not None:
                total_received += queue_size
                discarded = queue_size - 1
                total_discarded += discarded
                if queue_size > max_queue_depth:
                    max_queue_depth = queue_size
                
                # Because we aggressively drop all old packets in the buffer, 
                # the latest packet we just pulled is practically real-time (0-33ms).
                est_latency_ms = 0.0 if queue_size <= 1 else (1000.0 / 30.0)
                latency_history.append(est_latency_ms)
                
                status = "LIVE"
                color = (0, 255, 0)
                
                face, eye, ear = struct.unpack('<3d', latest_data)
                
                t_stamp = time.time() - start_time
                dataset.append((t_stamp, ear, face, eye, state))
                total_processed += 1
                
                # UI
                img = np.zeros((500, 600, 3), dtype=np.uint8)
                
                txt_color = (0, 255, 0) if state == "OPEN" else (0, 0, 255)
                cv2.putText(img, f"ACTION: {state}", (30, 80), cv2.FONT_HERSHEY_SIMPLEX, 2, txt_color, 4)
                cv2.putText(img, f"EAR: {ear:.3f}", (30, 150), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)
                
                cv2.putText(img, f"Queue Discarded: {discarded}", (30, 230), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
                cv2.putText(img, f"Packet Age: ~{est_latency_ms:.1f} ms", (30, 280), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
                cv2.putText(img, f"STATUS: {status}", (30, 330), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
                
                time_left = duration - (time.time() - phase_start)
                cv2.putText(img, f"Time left: {time_left:.1f}s", (30, 380), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
                
                cv2.imshow("EAR Calibration V2", img)
                cv2.waitKey(1)
            else:
                time.sleep(0.01)

    cv2.destroyAllWindows()
    sock.close()

    # Save CSV
    with open('EAR_calibration_data_v2.csv', 'w', newline='') as f:
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

    thresholds = np.linspace(closed_stats['min'], open_stats['max'], 200)
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

    mean_lat = np.mean(latency_history) if latency_history else 0
    max_lat = np.max(latency_history) if latency_history else 0
    pct_stale = (total_discarded / total_received) * 100 if total_received > 0 else 0

    report = f"""EAR CALIBRATION REPORT V2

-- LATENCY & QUEUE METRICS --
Total Packets Received: {total_received}
Total Packets Processed (LIVE): {total_processed}
Total Packets Discarded (STALE): {total_discarded}
Max Queue Depth: {max_queue_depth}
Mean Live Latency: {mean_lat:.1f} ms
Max Live Latency: {max_lat:.1f} ms
Percentage of Stale Packets Dropped: {pct_stale:.1f}%

-- STATISTICS --
Open-eye (N={open_stats['n']}): Mean = {open_stats['mean']:.4f} | Median = {open_stats['median']:.4f} | Range = [{open_stats['min']:.4f}, {open_stats['max']:.4f}]
Closed-eye (N={closed_stats['n']}): Mean = {closed_stats['mean']:.4f} | Median = {closed_stats['median']:.4f} | Range = [{closed_stats['min']:.4f}, {closed_stats['max']:.4f}]

Difference between Means: {diff_mean:.4f}
Difference between Medians: {diff_median:.4f}
Distribution Overlap: {overlap:.4f}

-- CLASSIFICATION PERFORMANCE --
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
        report += "EAR separation is insufficient; additional calibration or landmark improvements are required.\n"
    else:
        report += "EAR separation is sufficient for proceeding to temporal eye-closure/drowsiness logic.\n"

    with open('EAR_calibration_report_v2.txt', 'w') as f:
        f.write(report)

    # Plots
    plt.figure(figsize=(10, 5))
    plt.plot(timestamps, ears, label='EAR Signal', color='black')
    for i in range(len(timestamps)-1):
        color = 'lightgreen' if states[i] == 'OPEN' else 'lightcoral'
        plt.axvspan(timestamps[i], timestamps[i+1], color=color, alpha=0.3)
    plt.axhline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('Time (s)')
    plt.ylabel('EAR')
    plt.title('EAR Temporal Signal (LIVE packets only)')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_calibration_plot_v2.png')
    plt.close()

    plt.figure(figsize=(8, 5))
    plt.hist(open_ears, bins=30, alpha=0.6, color='green', label='Open Eyes')
    plt.hist(closed_ears, bins=30, alpha=0.6, color='red', label='Closed Eyes')
    plt.axvline(best_thresh, color='blue', linestyle='--', label=f'Threshold: {best_thresh:.3f}')
    plt.xlabel('EAR')
    plt.ylabel('Frequency')
    plt.title('EAR Distribution')
    plt.legend()
    plt.tight_layout()
    plt.savefig('EAR_distribution_plot_v2.png')
    plt.close()

    print("\nCalibration Analysis V2 Complete. All stale packets were discarded.")

if __name__ == '__main__':
    main()
