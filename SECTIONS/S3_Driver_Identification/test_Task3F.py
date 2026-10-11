from Task3F_Temporal_Filter import TemporalStabilizer

class MockEvaluator:
    def __init__(self):
        self.frame_results = []
        
    def evaluate_frame(self, frame):
        if not self.frame_results:
            return "NO_FACE", None, 0.0, "Empty mock"
        return self.frame_results.pop(0)

def run_tests():
    print("\n--- Starting Task 3F Temporal Logic Tests ---")
    
    mock_eval = MockEvaluator()
    stabilizer = TemporalStabilizer(mock_eval, persistence_frames=10)
    
    def simulate_frames(count, state, driver_id=None):
        for _ in range(count):
            mock_eval.frame_results.append((state, driver_id, 1.0, "Mock"))
            c_state, c_id, _, _, _, _ = stabilizer.process_frame(None)
        return c_state, c_id

    # 1. & 11. Initial identification & Persistence boundary condition
    print("\nTest 1 & 11: Initial ID & Boundary Condition")
    assert stabilizer.confirmed_state == "NO_FACE", "Should start at NO_FACE"
    c_state, c_id = simulate_frames(9, "IDENTIFIED", 1)
    assert c_state == "NO_FACE", "Should not confirm at 9 frames"
    c_state, c_id = simulate_frames(1, "IDENTIFIED", 1)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should confirm at 10 frames"
    print("PASS: Confirmed after exactly 10 frames.")
    
    # 2. & 12. Stable identification & Multiple consecutive valid frames
    print("\nTest 2 & 12: Stable Identification")
    c_state, c_id = simulate_frames(40, "IDENTIFIED", 1)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should remain stable over 40 frames"
    print("PASS: Remained stable.")
    
    # 3. One-frame wrong identity
    print("\nTest 3: One-frame wrong identity")
    c_state, c_id = simulate_frames(1, "IDENTIFIED", 2)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should ignore single bad frame"
    c_state, c_id = simulate_frames(5, "IDENTIFIED", 1)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should recover seamlessly"
    print("PASS: Ignored single wrong frame.")
    
    # 4. Several transient wrong frames
    print("\nTest 4: Several transient wrong frames")
    c_state, c_id = simulate_frames(5, "IDENTIFIED", 2) # 5 frames of Driver 2
    assert c_state == "IDENTIFIED" and c_id == 1, "Should ignore 5 wrong frames"
    c_state, c_id = simulate_frames(5, "IDENTIFIED", 1) # back to Driver 1
    assert c_state == "IDENTIFIED" and c_id == 1, "Should recover seamlessly"
    print("PASS: Ignored transient wrong frames.")
    
    # 5. Persistent driver switch
    print("\nTest 5: Persistent driver switch")
    c_state, c_id = simulate_frames(9, "IDENTIFIED", 2)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should hold old ID until persistence met"
    c_state, c_id = simulate_frames(1, "IDENTIFIED", 2)
    assert c_state == "IDENTIFIED" and c_id == 2, "Should switch to new ID after 10 frames"
    print("PASS: Switched drivers successfully.")
    
    # 6. Unknown transition
    print("\nTest 6: Unknown transition")
    c_state, c_id = simulate_frames(10, "UNKNOWN", None)
    assert c_state == "UNKNOWN", "Should transition to UNKNOWN"
    print("PASS: Transitioned to UNKNOWN.")
    
    # 7. Low-confidence transition
    print("\nTest 7: Low-confidence transition")
    c_state, c_id = simulate_frames(10, "LOW_CONFIDENCE", 2)
    assert c_state == "LOW_CONFIDENCE", "Should transition to LOW_CONFIDENCE"
    print("PASS: Transitioned to LOW_CONFIDENCE.")
    
    # 8. No-face
    print("\nTest 8: No-face")
    c_state, c_id = simulate_frames(10, "NO_FACE", None)
    assert c_state == "NO_FACE", "Should transition to NO_FACE"
    print("PASS: Transitioned to NO_FACE.")
    
    # 9. Face recovery
    print("\nTest 9: Face recovery")
    c_state, c_id = simulate_frames(10, "IDENTIFIED", 1)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should recover from NO_FACE"
    print("PASS: Recovered face.")
    
    # 10. Identity flicker prevention
    print("\nTest 10: Identity flicker prevention")
    # Alternate between Driver 1 and Driver 2 for 20 frames
    for _ in range(10):
        c_state, c_id = simulate_frames(1, "IDENTIFIED", 2)
        c_state, c_id = simulate_frames(1, "IDENTIFIED", 1)
    assert c_state == "IDENTIFIED" and c_id == 1, "Should not flicker, hold previous stable state"
    print("PASS: Prevented flickering.")

    print("\nAll Task 3F tests passed successfully!")

if __name__ == "__main__":
    run_tests()
