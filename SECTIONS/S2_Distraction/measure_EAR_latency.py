import socket
import struct
import time
import cv2
import numpy as np

UDP_IP = "127.0.0.1"
UDP_PORT = 5000

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    sock.setblocking(False) # NON-BLOCKING to allow queue draining

    print("Diagnostic: Measuring UDP Queue Latency and Stale Packets")
    print("Ensure mediapipe_udp_sender.py is running...")

    cv2.namedWindow("Latency Diagnostic", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("Latency Diagnostic", 600, 400)
    
    last_frame_time = time.time()
    frames_processed = 0
    fps = 0.0
    
    avg_queue_size = 0.0
    max_queue_size = 0

    while True:
        # Drain the UDP Queue to find the NEWEST packet
        queue_size = 0
        latest_data = None
        
        while True:
            try:
                data, _ = sock.recvfrom(24)
                latest_data = data
                queue_size += 1
            except socket.error:
                break # Queue is empty
                
        if latest_data is not None:
            face, eye, ear = struct.unpack('<3d', latest_data)
            
            # Statistics
            frames_processed += 1
            if queue_size > max_queue_size:
                max_queue_size = queue_size
                
            avg_queue_size = (avg_queue_size * 0.95) + (queue_size * 0.05)
            
            current_time = time.time()
            if current_time - last_frame_time >= 1.0:
                fps = frames_processed / (current_time - last_frame_time)
                frames_processed = 0
                last_frame_time = current_time
                
            # Estimated age (Assuming Sender is 30 FPS, each queued packet adds ~33ms of latency)
            est_latency_ms = (queue_size - 1) * 33.3 
            
            status = "LIVE" if queue_size <= 1 else "STALE/QUEUING"
            color = (0, 255, 0) if queue_size <= 1 else (0, 0, 255)
            
            # UI
            img = np.zeros((400, 600, 3), dtype=np.uint8)
            cv2.putText(img, f"EAR: {ear:.3f}", (30, 80), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)
            cv2.putText(img, f"STATE: {status}", (30, 150), cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
            cv2.putText(img, f"Packets in Queue: {queue_size}", (30, 220), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            cv2.putText(img, f"Est. Age (Latency): {est_latency_ms:.1f} ms", (30, 270), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            cv2.putText(img, f"Receiver Loop FPS: {fps:.1f}", (30, 320), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            cv2.putText(img, f"Max Queue Seen: {max_queue_size}", (30, 370), cv2.FONT_HERSHEY_SIMPLEX, 1, (100, 100, 255), 2)
            
            cv2.imshow("Latency Diagnostic", img)
            
            print(f"[Queue: {queue_size} | Max: {max_queue_size} | Latency: {est_latency_ms:.1f}ms] EAR: {ear:.3f} -> {status}")
            
        else:
            # If no data is available immediately, wait a tiny bit to prevent CPU maxing
            time.sleep(0.01)
            
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            break

    cv2.destroyAllWindows()
    sock.close()
    
    print("\n--- LATENCY REPORT ---")
    print(f"Max Packets Queued: {max_queue_size}")
    print(f"Max Estimated Latency: {max_queue_size * 33.3:.1f} ms")
    if max_queue_size > 5:
        print("CONCLUSION: Severe queueing detected! Receiver was processing stale data.")
    else:
        print("CONCLUSION: Queuing is minimal. Data was live.")

if __name__ == '__main__':
    main()
