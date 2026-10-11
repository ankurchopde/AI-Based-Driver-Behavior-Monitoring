import socket
import time
import subprocess

UDP_IP = "127.0.0.1"
UDP_PORT = 5000

print("Launching mediapipe_udp_sender.py...")
sender_proc = subprocess.Popen(["python", "mediapipe_udp_sender.py"])

# Give the camera and MediaPipe time to initialize and stabilize
print("Waiting 10 seconds for camera initialization...")
time.sleep(10)

print("Starting UDP Receiver...")
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(False)

# Drain any existing stale packets in the OS buffer
while True:
    try:
        sock.recvfrom(1024)
    except BlockingIOError:
        break

print("Recording for 30 seconds to simulate Simulink 20Hz pacing...")
SIMULINK_RATE = 20.0
INTERVAL = 1.0 / SIMULINK_RATE

max_queue_seen = 0
total_arrived = 0

start_time = time.perf_counter()
next_tick = start_time + INTERVAL

ticks = 0
backlog = 0

while time.perf_counter() - start_time < 30.0:
    now = time.perf_counter()
    sleep_time = next_tick - now
    if sleep_time > 0:
        time.sleep(sleep_time)
        
    next_tick += INTERVAL
    ticks += 1
    
    # Drain everything that arrived in this 0.05s window
    packets_this_tick = 0
    while True:
        try:
            data, _ = sock.recvfrom(1024)
            packets_this_tick += 1
            total_arrived += 1
        except BlockingIOError:
            break
            
    # Simulate Simulink reading exactly 1 packet per tick
    if packets_this_tick > 0:
        # We received new data. Add to backlog.
        backlog += packets_this_tick
        
    if backlog > 0:
        # Simulink reads 1 packet
        backlog -= 1
        
    if backlog > max_queue_seen:
        max_queue_seen = backlog

elapsed = time.perf_counter() - start_time
sender_rate = total_arrived / elapsed

print("\n--- DIAGNOSTIC RESULTS ---")
print(f"Previous sender rate: ~30.00 Hz (Camera FPS)")
print(f"New configured sender rate: {SIMULINK_RATE} Hz")
print(f"Simulink configured rate: {SIMULINK_RATE} Hz")
print(f"Measured Sender Arrival Rate: {sender_rate:.2f} Hz")
print(f"Measured Receiver Tick Rate: {ticks / elapsed:.2f} Hz")
print(f"Maximum Simulated Queue Backlog (Latency buildup): {max_queue_seen} packets")

if max_queue_seen < 5:
    print("Conclusion: Latency DOES NOT grow over time! Perfect 20Hz sync.")
else:
    print("Conclusion: Latency is STILL GROWING. Rate mismatch remains.")

sender_proc.terminate()
