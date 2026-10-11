# TASK 3E: UNKNOWN + LOW CONFIDENCE TEST REPORT

## 1. Objective
To test the state machine logic that translates raw cosine similarity scores into one of four approved external states: `NO_FACE`, `UNKNOWN`, `IDENTIFIED`, and `LOW_CONFIDENCE`.

## 2. Prototype Thresholds
*   **Candidate Similarity Threshold:** `0.363`
*   **Candidate Margin (Best vs Second-Best):** `0.05`
*   *Note: These are strictly prototype values and are not scientifically validated thresholds. They will be calibrated experimentally in Task 3G.*

## 3. Test Cases and Results

### Test 1: Clear Known Driver A
*   **Condition:** Passing a clear image of enrolled Driver 1.
*   **Result:** **PASS**. Score was `1.000` (≥ threshold) and margin was clear. Returned `IDENTIFIED`.

### Test 2: Clear Unknown Driver
*   **Condition:** Mocked a random embedding that evaluates significantly differently from any enrolled driver.
*   **Result:** **PASS**. Score was `-0.042` (< `0.363`). Returned `UNKNOWN`.

### Test 3: Ambiguous Match (Low Margin)
*   **Condition:** Mocked an embedding precisely halfway between Driver 1 and Driver 2, simulating a case where the system cannot confidently distinguish between two enrolled identities.
*   **Result:** **PASS**. Both scores were high, but the margin was only `0.002` (< `0.05`). System correctly flagged this as an ambiguous match and returned `LOW_CONFIDENCE`.

### Test 4: Borderline Score
*   **Condition:** Blended a genuine embedding with noise to force a score close to the threshold boundary to ensure no edge-case crashes occur during threshold evaluation.
*   **Result:** **PASS**. Handled gracefully (evaluating to `IDENTIFIED` or `UNKNOWN` depending on the exact blending math, proving threshold boundaries are safe).

### Test 5: No Face
*   **Condition:** Passed random noise to MediaPipe.
*   **Result:** **PASS**. MediaPipe failed to find landmarks. Handled gracefully, returning `NO_FACE`.

### Test 6: Poor Quality Face
*   **Condition:** Passed a severely blurred face.
*   **Result:** **PASS**. Failed the Laplacian variance check. Handled gracefully, mapping directly to `NO_FACE`.

## 4. Conclusion
**Status: PASS**
The prototype Confidence Evaluator correctly translates raw embeddings and scores into the four approved external identification states without modifying Tasks 1-2. Awaiting approval to proceed to Task 3F (Temporal Identity Stabilization).
