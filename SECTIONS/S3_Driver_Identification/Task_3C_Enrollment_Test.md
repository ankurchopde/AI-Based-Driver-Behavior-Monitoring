# TASK 3C: ENROLLMENT PROTOTYPE TEST REPORT

## 1. Objective
To test the Driver Enrollment Prototype (`Task3C_Enrollment.py`), ensuring that it correctly processes camera frames, extracts OpenCV SFace embeddings, checks for face quality, and safely updates the `database` and `registry.json` files.

## 2. Test Cases and Results

### Test 1: Valid Enrollment
*   **Action:** Enrolled Driver 1 ("Alice") with 15 frames of a high-quality face.
*   **Result:** **PASS**. The system successfully created `database/driver_01`, saved 15 aligned embeddings into `embeddings.npy`, and updated `registry.json`.

### Test 2: No Face
*   **Action:** Passed frames containing random noise (no face).
*   **Result:** **PASS**. The system gracefully rejected the frame with status `NO_FACE` and did not extract embeddings.

### Test 3: Multiple Faces
*   **Action:** Passed frames containing multiple faces (concatenated).
*   **Result:** **PASS**. Handled gracefully. The script logic explicitly detects `len(results.face_landmarks) > 1` and returns `MULTIPLE_FACES`.

### Test 4: Poor Face Quality (Blur)
*   **Action:** Passed severely blurred frames (Gaussian Blur 51x51).
*   **Result:** **PASS**. The Laplacian variance check flagged the frame as `POOR_QUALITY` and rejected it before passing it to the Face Mesh model.

### Test 5: Repeated Enrollment (Overwrite Protection)
*   **Action:** Attempted to enroll Driver 1 again without the `overwrite` flag.
*   **Result:** **PASS**. The system blocked the action: `"Driver 1 already exists."`
*   **Action:** Attempted again with `overwrite=True`.
*   **Result:** **PASS**. The system successfully deleted the old folder contents and re-enrolled the driver.

### Test 6: Multiple Drivers
*   **Action:** Enrolled Driver 2 ("Bob").
*   **Result:** **PASS**. Successfully created `database/driver_02` and updated `registry.json`. 

## 3. Database State Verification
```json
{
    "1": "Alice_Overwritten",
    "2": "Bob"
}
```
*   `registry.json` correctly maps the integer IDs to the string names.
*   The system operates fully offline without any external downloads during execution.

## 4. Conclusion
**Status: PASS**
The Enrollment Prototype successfully meets all constraints of Task 3C. Awaiting approval to proceed to Task 3D (Recognition Prototype).
