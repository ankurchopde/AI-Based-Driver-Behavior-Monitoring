import socket
import struct
import time
import subprocess

UDP_IP = "127.0.0.1"
UDP_PORT = 5000

print("Launching mediapipe_udp_sender.py...")
sender_proc = subprocess.Popen(["python", "mediapipe_udp_sender.py"])

print("Waiting 10 seconds for camera initialization...")
time.sleep(10)

print("Starting 8-value UDP Receiver Diagnostic...")
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(False)

# Drain stale packets
while True:
    try:
        sock.recvfrom(4096)
    except BlockingIOError:
        break

SIMULINK_RATE = 20.0
INTERVAL = 1.0 / SIMULINK_RATE

max_queue_seen = 0
total_arrived = 0
valid_packets = 0
invalid_packets = 0

start_time = time.perf_counter()
next_tick = start_time + INTERVAL
ticks = 0
backlog = 0

last_print = start_time

while time.perf_counter() - start_time < 30.0:
    now = time.perf_counter()
    sleep_time = next_tick - now
    if sleep_time > 0:
        time.sleep(sleep_time)
        
    next_tick += INTERVAL
    ticks += 1
    
    packets_this_tick = 0
    last_packet_data = None
    
    # Drain everything that arrived in this 0.05s window
    while True:
        try:
            data, _ = sock.recvfrom(4096)
            packets_this_tick += 1
            total_arrived += 1
            
            if len(data) == 64:
                valid_packets += 1
                last_packet_data = struct.unpack('<8d', data)
            else:
                invalid_packets += 1
                print(f"INVALID PACKET SIZE: {len(data)} bytes (expected 64)")
                
        except BlockingIOError:
            break
            
    # Simulate Simulink reading 1 packet per tick
    if packets_this_tick > 0:
        backlog += packets_this_tick
        
    if backlog > 0:
        backlog -= 1
        
    if backlog > max_queue_seen:
        max_queue_seen = backlog
        
    # Print the decoded values briefly every 2 seconds
    if now - last_print > 2.0 and last_packet_data:
        face, ear, mar, yaw, pitch, roll, gaze_x, gaze_y = last_packet_data
        print(f"[{now - start_time:04.1f}s] F:{face:.0f} E:{ear:.2f} M:{mar:.2f} "
              f"Y:{yaw:+.1f} P:{pitch:+.1f} R:{roll:+.1f} "
              f"GX:{gaze_x:+.2f} GY:{gaze_y:+.2f}")
        last_print = now

elapsed = time.perf_counter() - start_time
sender_rate = total_arrived / elapsed

print("\n--- DIAGNOSTIC RESULTS ---")
print(f"Expected Size: 64 bytes")
print(f"Valid Packets: {valid_packets}")
print(f"Invalid Packets: {invalid_packets}")
print(f"Simulink configured tick rate: {SIMULINK_RATE} Hz")
print(f"Measured Sender Arrival Rate: {sender_rate:.2f} Hz")
print(f"Measured Receiver Tick Rate: {ticks / elapsed:.2f} Hz")
print(f"Maximum Simulated Queue Backlog: {max_queue_seen} packets")

if invalid_packets == 0 and valid_packets > 0:
    print("Conclusion: UDP packet format is EXACTLY correct (<8d, 64 bytes).")
else:
    print("Conclusion: ERROR in UDP packet format!")

if max_queue_seen < 5:
    print("Conclusion: Latency DOES NOT grow over time! Perfect 20Hz sync.")
else:
    print("Conclusion: Latency is STILL GROWING. Rate mismatch remains.")

sender_proc.terminate()
