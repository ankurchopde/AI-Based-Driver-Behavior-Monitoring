import cv2
import numpy as np

class HeadPoseEstimator:
    def __init__(self, img_size):
        self.size = img_size
        self.focal_length = self.size[1]
        self.center = (self.size[1]/2, self.size[0]/2)
        self.camera_matrix = np.array(
            [[self.focal_length, 0, self.center[0]],
             [0, self.focal_length, self.center[1]],
             [0, 0, 1]], dtype="double"
        )
        self.dist_coeffs = np.zeros((4,1))
        
        # 3D model points (generic face)
        # Adjusted for OpenCV coordinate system: X right, Y down, Z forward (away from camera)
        self.model_points = np.array([
            (0.0, 0.0, 0.0),             # Nose tip
            (0.0, 330.0, 65.0),          # Chin
            (-225.0, -170.0, 135.0),     # Left eye left corner
            (225.0, -170.0, 135.0),      # Right eye right corner
            (-150.0, 150.0, 125.0),      # Left Mouth corner
            (150.0, 150.0, 125.0)        # Right mouth corner
        ])
        
        # MediaPipe landmark indices corresponding to above points
        self.landmark_indices = [4, 152, 33, 263, 61, 291]
        
    def get_pose(self, face_landmarks):
        image_points = []
        for idx in self.landmark_indices:
            lm = face_landmarks[idx]
            x, y = int(lm.x * self.size[1]), int(lm.y * self.size[0])
            image_points.append((x, y))
            
        image_points = np.array(image_points, dtype="double")
        
        success, rotation_vector, translation_vector = cv2.solvePnP(
            self.model_points, image_points, self.camera_matrix, self.dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE
        )
        
        if not success:
            return None, None, None
            
        rmat, _ = cv2.Rodrigues(rotation_vector)
        
        # Convert rotation matrix to Euler angles
        proj_matrix = np.hstack((rmat, translation_vector))
        euler_angles = cv2.decomposeProjectionMatrix(proj_matrix)[6]
        
        pitch = euler_angles[0][0]
        yaw = euler_angles[1][0]
        roll = euler_angles[2][0]
        
        # Pitch adjustment if needed based on convention
        # For this model, looking up might be positive or negative. Let's keep it raw for now,
        # but typically we adjust to make it intuitive.
        # pitch < 0 = looking up, pitch > 0 = looking down (or vice versa depending on axes)
        
        return yaw, pitch, roll
