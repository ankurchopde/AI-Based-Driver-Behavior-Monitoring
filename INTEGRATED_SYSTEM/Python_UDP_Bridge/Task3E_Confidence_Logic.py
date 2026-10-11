import cv2
from Task3D_Recognition_Core import RecognitionSystem

class ConfidenceEvaluator:
    def __init__(self, recognition_system: RecognitionSystem, candidate_threshold=0.363, candidate_margin=0.05):
        """
        IMPORTANT: 
        candidate_threshold (0.363) and candidate_margin (0.05) are strictly PROTOTYPE CANDIDATE VALUES.
        They are NOT scientifically validated thresholds. They must be calibrated experimentally.
        """
        self.threshold = candidate_threshold
        self.margin = candidate_margin
        self.rec_sys = recognition_system
        
    def evaluate_frame(self, frame):
        """
        Returns: (state, best_driver_id, similarity_score, message)
        States: NO_FACE, UNKNOWN, IDENTIFIED, LOW_CONFIDENCE
        """
        embedding, status = self.rec_sys.get_embedding(frame)
        
        if embedding is None:
            # Both NO_FACE and POOR_QUALITY result in the NO_FACE external state, 
            # as there is no viable face to identify.
            return "NO_FACE", None, 0.0, f"Extraction failed: {status}"
                
        if not self.rec_sys.driver_embeddings:
            return "UNKNOWN", None, 0.0, "No drivers enrolled"
            
        # Aggregate max score per enrolled driver
        driver_max_scores = {}
        for driver_id, enrolled_embs in self.rec_sys.driver_embeddings.items():
            max_s = -1.0
            for ref_emb in enrolled_embs:
                score = self.rec_sys.recognizer.match(embedding, ref_emb, cv2.FaceRecognizerSF_FR_COSINE)
                if score > max_s:
                    max_s = score
            driver_max_scores[driver_id] = max_s
            
        if not driver_max_scores:
            return "UNKNOWN", None, 0.0, "Empty database"
            
        # Sort drivers by their max score descending
        sorted_drivers = sorted(driver_max_scores.items(), key=lambda x: x[1], reverse=True)
        best_id, best_score = sorted_drivers[0]
        
        # 1. Threshold Check
        if best_score < self.threshold:
            return "UNKNOWN", None, best_score, f"Score {best_score:.3f} below prototype threshold {self.threshold}"
            
        # 2. Margin Check (if multiple drivers exist)
        if len(sorted_drivers) > 1:
            second_best_score = sorted_drivers[1][1]
            margin = best_score - second_best_score
            if margin < self.margin:
                return "LOW_CONFIDENCE", best_id, best_score, f"Margin {margin:.3f} below prototype margin {self.margin}"
                
        # 3. Success
        return "IDENTIFIED", best_id, best_score, f"Identified Driver {best_id} with score {best_score:.3f}"
