import socket
import struct
import time
import threading
import numpy as np
from Task3H_UDP_Sender import udp_worker, telemetry_data, telemetry_lock
import Task3H_UDP_Sender

# Configure mock data
def run_tests():
    print("--- TASK 3H UDP VALIDATION ---")
    
    # 1. Start the sender thread
    Task3H_UDP_Sender.stop_thread = False
    udp_thread = threading.Thread(target=udp_worker, daemon=True)
    udp_thread.start()
    
    # 2. Setup receiver
    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_sock.bind(("127.0.0.1", 5000))
    recv_sock.settimeout(1.0)
    
    print("Receiver bound to 127.0.0.1:5000")
    
    # 3. Inject dummy telemetry
    dummy_data = (1.0, 0.25, 0.1, 15.0, 5.0, 2.0, -0.5, 0.5, 2.0, 0.95, 2.0)
    with telemetry_lock:
        Task3H_UDP_Sender.telemetry_data = dummy_data
        
    # 4. Receive and parse
    try:
        data = None
        for _ in range(5):
            data, addr = recv_sock.recvfrom(1024)
            parsed = struct.unpack('<11d', data)
            if not np.allclose(parsed, (0.0,)*11):
                break
        
        print(f"Received {len(data)} bytes from {addr}")
        assert len(data) == 88, f"Expected 88 bytes, got {len(data)}"
        print("Parsed Data:", parsed)
        
        assert np.allclose(parsed, dummy_data), "Parsed data does not match injected data"
        print("PASS: Packet size, ordering, and values are correct.")
        
    except socket.timeout:
        print("FAIL: Did not receive UDP packet.")
        return
        
    # 5. Measure frequency and backlog
    print("\nMeasuring UDP frequency...")
    recv_sock.settimeout(0.1)
    
    packets_received = 0
    start_time = time.perf_counter()
    
    while time.perf_counter() - start_time < 2.0:
        try:
            recv_sock.recvfrom(1024)
            packets_received += 1
        except socket.timeout:
            pass
            
    freq = packets_received / 2.0
    print(f"Received {packets_received} packets in 2.0 seconds -> {freq} Hz")
    
    # A true 20 Hz without backlog should give exactly 40 packets, maybe 39 or 41.
    assert 18 <= freq <= 22, f"Frequency {freq} is out of bounds (~20 Hz expected)"
    print("PASS: Frequency is strictly ~20 Hz with zero backlog behavior.")
    
    Task3H_UDP_Sender.stop_thread = True
    udp_thread.join()
    recv_sock.close()
    print("\nAll UDP validation tests passed.")

import numpy as np
if __name__ == "__main__":
    run_tests()
