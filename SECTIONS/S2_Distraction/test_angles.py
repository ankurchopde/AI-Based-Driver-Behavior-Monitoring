import numpy as np
import cv2

# Adjusted 3D model points (OpenCV convention: X right, Y down, Z forward)
model_points = np.array([
    (0.0, 0.0, 0.0),             # Nose tip
    (0.0, 330.0, 65.0),          # Chin
    (-225.0, -170.0, 135.0),     # Left eye left corner
    (225.0, -170.0, 135.0),      # Right eye right corner
    (-150.0, 150.0, 125.0),      # Left Mouth corner
    (150.0, 150.0, 125.0)        # Right mouth corner
])

# Create a camera matrix
img_w, img_h = 640, 480
focal_length = img_w
center = (img_w / 2, img_h / 2)
camera_matrix = np.array([
    [focal_length, 0, center[0]],
    [0, focal_length, center[1]],
    [0, 0, 1]
], dtype="double")
dist_coeffs = np.zeros((4, 1))

def simulate_pose(rvec, tvec):
    # Project model points to 2D
    image_points, _ = cv2.projectPoints(model_points, rvec, tvec, camera_matrix, dist_coeffs)
    
    # Run solvePnP
    success, rvec_est, tvec_est = cv2.solvePnP(
        model_points, image_points, camera_matrix, dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE
    )
    
    rmat, _ = cv2.Rodrigues(rvec_est)
    proj_matrix = np.hstack((rmat, tvec_est))
    euler_angles = cv2.decomposeProjectionMatrix(proj_matrix)[6]
    
    pitch = euler_angles[0][0]
    yaw = euler_angles[1][0]
    roll = euler_angles[2][0]
    
    return yaw, pitch, roll

print("Testing Forward Pose:")
rvec_fwd = np.array([0.0, 0.0, 0.0])
tvec_fwd = np.array([0.0, 0.0, 1000.0])
print(simulate_pose(rvec_fwd, tvec_fwd))

print("Testing Yaw (Turn Right) 30 degrees:")
rvec_yaw = np.array([0.0, np.deg2rad(30), 0.0])
print(simulate_pose(rvec_yaw, tvec_fwd))

print("Testing Pitch (Look Down) 30 degrees:")
rvec_pitch = np.array([np.deg2rad(30), 0.0, 0.0])
print(simulate_pose(rvec_pitch, tvec_fwd))
