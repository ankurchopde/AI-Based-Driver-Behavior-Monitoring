# TASK 3A: DRIVER IDENTIFICATION MODEL/METHOD SELECTION AUDIT

## 1. Context and Requirements
The goal is to implement a driver identification system that meets the following criteria:
* **Lightweight:** Feasible for eventual deployment on a Raspberry Pi Edge-AI device.
* **Accuracy:** High recognition accuracy while rejecting unknown drivers.
* **Integration:** Easily integrates with the existing MediaPipe face detection/tracking pipeline.
* **Enrollment:** Supports adding new drivers without retraining the entire system.
* **Language/Platform:** Python-based vision processing.

Since the system already uses MediaPipe for robust Face Detection and Landmarking, the primary need is a **Face Feature/Embedding Extraction** method that takes a cropped face image and outputs an embedding for similarity matching.

## 2. Candidate Approaches

We evaluate three suitable lightweight candidates:

### Candidate A: `face_recognition` library (dlib backend)
* **Description:** The most popular Python face recognition wrapper. Uses a ResNet network (dlib) to generate a 128-dimensional embedding.
* **Recognition Accuracy:** Very high (99.38% on LFW dataset).
* **Computational / RAM Req:** Moderate. Can run at ~5-10 fps on Raspberry Pi CPU.
* **Raspberry Pi Feasibility:** Good, but compiling `dlib` on a Pi can be time-consuming and sometimes tricky regarding C++ dependencies.
* **Integration:** Can easily take the cropped face from MediaPipe.
* **Unknown Detection:** Yes, via Euclidean distance thresholding.
* **Enrollment:** Easy (just store the 128D vector). No retraining.

### Candidate B: MobileFaceNet (via ONNXRuntime)
* **Description:** A highly efficient CNN specifically designed for real-time face verification on mobile and embedded devices.
* **Recognition Accuracy:** Excellent (99.55% on LFW), heavily optimized for faces.
* **Computational / RAM Req:** Very low. Model size is typically < 5 MB.
* **Raspberry Pi Feasibility:** Excellent. ONNXRuntime runs very efficiently on ARM CPUs.
* **Integration:** MediaPipe crops the face -> feed to ONNX model -> get embedding.
* **Unknown Detection:** Yes, via Cosine Similarity thresholding.
* **Enrollment:** Easy (store embedding vectors). No retraining.

### Candidate C: OpenCV SFace (`cv2.FaceRecognizerSF`)
* **Description:** A lightweight face recognition model integrated natively into OpenCV (versions 4.8+). 
* **Recognition Accuracy:** High (99.40% on LFW).
* **Computational / RAM Req:** Very low. Requires an ONNX model (around 9-10 MB) but is highly optimized using OpenCV's DNN module.
* **Raspberry Pi Feasibility:** Excellent. If `opencv-python` is installed, it works out of the box without complex C++ compilations like dlib.
* **Integration:** MediaPipe crops the face -> `cv2.FaceRecognizerSF` -> get embedding.
* **Unknown Detection:** Yes, via Cosine Distance or L2 Distance.
* **Enrollment:** Easy (store vectors). No retraining.

## 3. Comparison Matrix

| Feature | `face_recognition` (dlib) | MobileFaceNet (ONNX) | OpenCV SFace |
| :--- | :--- | :--- | :--- |
| **Accuracy** | High | Very High | High |
| **Speed (CPU)** | Moderate | Fast | Fast |
| **Dependencies** | `dlib`, `numpy` | `onnxruntime`, `numpy` | `opencv-python` (already used) |
| **RPi Install Ease**| Hard (compilation) | Easy | Very Easy |
| **Model Size** | ~27 MB | ~4-5 MB | ~10 MB |
| **Similarity Metric**| Euclidean | Cosine | Cosine / L2 |

## 4. Recommendation

**Recommended Approach: OpenCV SFace (or alternatively, MobileFaceNet via ONNX)**

**Why it is suitable for this project and Raspberry Pi:**
1. **Dependency Simplicity:** The project likely already relies on OpenCV for image handling alongside MediaPipe. OpenCV SFace leverages the `cv2.dnn` module natively, meaning zero additional heavy dependencies (like `dlib` or `tensorflow`) are required. This makes Raspberry Pi deployment drastically simpler.
2. **Performance:** The model is highly optimized for CPU inference and operates well within the constraints of edge devices.
3. **Pipeline Fit:** MediaPipe will handle the heavy lifting of detecting the face. We simply crop the face box, align it (optional but recommended), and pass it to the OpenCV SFace extractor to get a 128D feature vector. 
4. **Distance/Confidence Metrics:** It natively supports Cosine Similarity, which provides a bounded `[0, 1]` or `[-1, 1]` confidence score. This cleanly maps to our required states (IDENTIFIED, LOW_CONFIDENCE, UNKNOWN).
5. **No Retraining:** New drivers are enrolled simply by passing their cropped faces through the network and saving the resulting vectors to a JSON or CSV file.

## 5. Next Steps (Pending Approval)
If OpenCV SFace (or MobileFaceNet) is approved as the architecture, the next stage (Task 3B) will be to finalize the data structures and class interfaces before writing the enrollment script (Task 3C). No existing Section 1 or Section 2 files will be modified.
