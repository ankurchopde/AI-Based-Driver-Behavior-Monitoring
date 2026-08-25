class TemporalStabilizer:
    def __init__(self, confidence_evaluator, persistence_frames=10):
        """
        IMPORTANT: persistence_frames (default 10) is a PROTOTYPE CANDIDATE value,
        representing approximately 0.5 seconds at 20 Hz.
        It is NOT scientifically validated and will be evaluated during Task 3G.
        """
        self.evaluator = confidence_evaluator
        self.persistence_frames = persistence_frames
        
        # Internal states
        self.confirmed_state = "NO_FACE"
        self.confirmed_id = None
        
        self.candidate_state = "NO_FACE"
        self.candidate_id = None
        self.candidate_counter = 0
        
    def process_frame(self, frame):
        """
        Processes a frame through the ConfidenceEvaluator (Task 3E) and applies 
        temporal stabilization to prevent identity flickering.
        
        Returns:
        (confirmed_state, confirmed_id, raw_state, raw_id, raw_score, raw_msg)
        """
        # 1. Get raw candidate from 3E logic
        raw_state, raw_id, score, msg = self.evaluator.evaluate_frame(frame)
        
        # 2. Update Candidate Counters
        if raw_state == self.candidate_state and raw_id == self.candidate_id:
            self.candidate_counter += 1
        else:
            self.candidate_state = raw_state
            self.candidate_id = raw_id
            self.candidate_counter = 1
            
        # 3. Check Persistence
        if self.candidate_counter >= self.persistence_frames:
            self.confirmed_state = self.candidate_state
            self.confirmed_id = self.candidate_id
            
        return self.confirmed_state, self.confirmed_id, raw_state, raw_id, score, msg
