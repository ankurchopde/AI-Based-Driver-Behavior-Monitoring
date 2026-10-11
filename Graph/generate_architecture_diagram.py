"""
generate_architecture_diagram.py
Generates the comprehensive, professional system architecture diagram for:
"AI-Based Driver Behavior Monitoring System"

Outputs:
- Graph/architecture.png (300 DPI high-res)
- Graph/architecture.svg (vector editable format)
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from pathlib import Path

def create_diagram():
    fig = plt.figure(figsize=(20, 13), dpi=300)
    ax = fig.add_subplot(111)
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 13)
    ax.axis('off')

    # Color Palette - Professional Academic Scheme
    c_bg = "#F8FAFC"
    fig.patch.set_facecolor(c_bg)
    ax.set_facecolor(c_bg)

    c_border = "#94A3B8"
    c_input = "#E0F2FE"       # Light Sky
    c_input_b = "#0284C7"
    c_cv = "#EEF2FF"          # Light Indigo
    c_cv_b = "#4F46E5"
    c_s1 = "#FEF3C7"          # Amber (Drowsiness)
    c_s1_b = "#D97706"
    c_s2 = "#FEE2E2"          # Rose (Distraction)
    c_s2_b = "#DC2626"
    c_s3 = "#EDE9FE"          # Purple (Identification)
    c_s3_b = "#7C3AED"
    c_udp = "#DCFCE7"         # Green (Bridge)
    c_udp_b = "#16A34A"
    c_sim = "#F1F5F9"         # Slate (Simulink)
    c_sim_b = "#334155"
    c_alert = "#FFEDD5"       # Orange (Alerts)
    c_alert_b = "#EA580C"
    c_offline = "#F3F4F6"     # Gray (Offline)
    c_offline_b = "#6B7280"
    c_future = "#FDF2F8"      # Pink / Dash (Future)
    c_future_b = "#DB2777"

    # Helper function for drawing rounded boxes
    def draw_box(x, y, w, h, bg_color, border_color, title, subtitle="", items=None, dashed=False, title_color="#1E293B"):
        linestyle = '--' if dashed else '-'
        box = patches.FancyBboxPatch(
            (x, y), w, h,
            boxstyle="round,pad=0.15,rounding_size=0.25",
            facecolor=bg_color,
            edgecolor=border_color,
            linewidth=1.8,
            linestyle=linestyle,
            zorder=2
        )
        ax.add_patch(box)
        
        # Title
        t_y = y + h - 0.35
        ax.text(x + w/2, t_y, title, ha='center', va='center', fontsize=11, fontweight='bold', color=title_color, zorder=3)
        
        # Subtitle
        if subtitle:
            t_y -= 0.3
            ax.text(x + w/2, t_y, subtitle, ha='center', va='center', fontsize=8.5, fontstyle='italic', color="#475569", zorder=3)
            
        # Items list
        if items:
            start_y = t_y - 0.35
            for idx, itm in enumerate(items):
                cur_y = start_y - (idx * 0.28)
                ax.text(x + 0.25, cur_y, f"• {itm}", ha='left', va='center', fontsize=8, color="#334155", zorder=3)

    # Helper function for drawing arrows
    def draw_arrow(x1, y1, x2, y2, label="", color="#475569", lw=1.8, style='->', label_pos=0.5, label_offset=0.15):
        arrow = patches.FancyArrowPatch(
            (x1, y1), (x2, y2),
            arrowstyle=style,
            mutation_scale=14,
            color=color,
            linewidth=lw,
            zorder=4
        )
        ax.add_patch(arrow)
        if label:
            lx = x1 + (x2 - x1) * label_pos
            ly = y1 + (y2 - y1) * label_pos + label_offset
            ax.text(lx, ly, label, ha='center', va='center', fontsize=7.5, fontweight='semibold',
                    color=color, bbox=dict(boxstyle="round,pad=0.2", facecolor=c_bg, edgecolor="none", alpha=0.9), zorder=5)

    # 1. Main Title Header
    ax.text(10, 12.5, "AI-BASED DRIVER BEHAVIOR MONITORING SYSTEM", ha='center', va='center',
            fontsize=17, fontweight='heavy', color="#0F172A")
    ax.text(10, 12.15, "End-to-End System Architecture: Vision Preprocessing, Multi-Task Pipeline, Real-Time UDP Telemetry & Simulink Logic",
            ha='center', va='center', fontsize=9.5, color="#475569")

    # 2. Layer 1: SENSOR / INPUT & ROBUSTNESS (Left column, y: 7.2 to 11.5)
    draw_box(0.6, 7.2, 3.2, 4.4, c_input, c_input_b, "1. Vision Input & Robustness",
             subtitle="Video Stream & Normalization",
             items=[
                 "RGB Webcam (640×480 @ 30 FPS)",
                 "Offline Video Input (MP4/AVI)",
                 "Illumination Analysis (YCrCb)",
                 "Adaptive CLAHE Equalization",
                 "Clip Limit: 2.0, Grid: (8×8)",
                 "Shadow & Glare Robustness",
                 "Face Crop: 160×160 RGB Normalization"
             ])

    # 3. Layer 2: PYTHON COMPUTER VISION PROCESSING CONTAINER
    # Outer frame for Python Pipeline
    outer_py = patches.FancyBboxPatch(
        (4.4, 4.5), 6.8, 7.1,
        boxstyle="round,pad=0.2,rounding_size=0.3",
        facecolor=c_cv, edgecolor=c_cv_b, linewidth=1.5, linestyle=':', alpha=0.4, zorder=1
    )
    ax.add_patch(outer_py)
    ax.text(7.8, 11.35, "2. Python Computer Vision Engine (MediaPipe FaceMesh & Deep Models)",
            ha='center', va='center', fontsize=10.5, fontweight='bold', color=c_cv_b)

    # S1 Box
    draw_box(4.6, 8.8, 6.4, 2.3, c_s1, c_s1_b, "S1: Drowsiness Detection",
             subtitle="Ocular & Yawn Dynamics",
             items=[
                 "MediaPipe 468/478 Landmark Extraction",
                 "Eye Aspect Ratio (EAR) Thresholding (Thresh: 0.21)",
                 "Blink Frequency & Closure Duration Integrator",
                 "Mouth Aspect Ratio (MAR) Yawning Analysis (Thresh: 0.60)",
                 "Temporal PERCLOS Score Estimation"
             ], title_color=c_s1_b)

    # S2 Box
    draw_box(4.6, 6.5, 6.4, 2.1, c_s2, c_s2_b, "S2: Distraction & Attention Detection",
             subtitle="Head Pose & Iris Gaze Tracking",
             items=[
                 "SolvePnP 3D Head Pose (Yaw, Pitch, Roll angles)",
                 "Off-Road Yaw Bounds: ±25° | Pitch Bounds: ±20°",
                 "Iris Landmark Pupil Tracking (Gaze X, Gaze Y offset)",
                 "Zone-Based Off-Road Temporal Accumulator"
             ], title_color=c_s2_b)

    # S3 Box
    draw_box(4.6, 4.7, 6.4, 1.65, c_s3, c_s3_b, "S3: Driver Identification",
             subtitle="Deep Metric Biometric Verification",
             items=[
                 "128-D Face Embedding Extraction (FaceNet Backbone)",
                 "Cosine Distance Metric vs. Enrolled Registry (0.363 Thresh)",
                 "10-Frame Temporal Persistence Stabilizer"
             ], title_color=c_s3_b)

    # Arrow: Input -> Python Pipeline
    draw_arrow(3.8, 9.4, 4.6, 9.4, "640×480 BGR", color=c_input_b, lw=2)

    # 4. Layer 3: REAL-TIME TELEMETRY BRIDGE (Center column)
    draw_box(11.8, 5.2, 3.4, 6.4, c_udp, c_udp_b, "3. UDP Telemetry Bridge",
             subtitle="Deterministic High-Speed Link",
             items=[
                 "Localhost Socket: 127.0.0.1:25000",
                 "Transmission Rate: 20.5 Hz",
                 "Payload: Exactly 88 Bytes",
                 "Format: '<11d' (11 Doubles)",
                 "NaN Sentinel on Face Loss",
                 "─────────────────────────",
                 "Telemetry Channels:",
                 "1: Face_Detected (0 or 1)",
                 "2: Eye Aspect Ratio (EAR)",
                 "3: Mouth Aspect Ratio (MAR)",
                 "4-6: Yaw, Pitch, Roll (deg)",
                 "7-8: Gaze_X, Gaze_Y (norm)",
                 "9: Driver_ID (Int code)",
                 "10: ID_Confidence (0.0 - 1.0)",
                 "11: ID_State (Unknown/Known)"
             ], title_color=c_udp_b)

    # Arrows: S1, S2, S3 to UDP Bridge
    draw_arrow(11.0, 9.8, 11.8, 9.0, "EAR, MAR", color=c_s1_b)
    draw_arrow(11.0, 7.5, 11.8, 7.8, "Yaw, Pitch, Roll, Gaze", color=c_s2_b)
    draw_arrow(11.0, 5.5, 11.8, 6.2, "ID, Conf, State", color=c_s3_b)

    # 5. Layer 4: MATLAB / SIMULINK INTEGRATED PROCESSING
    draw_box(15.8, 5.2, 3.6, 6.4, c_sim, c_sim_b, "4. Integrated Simulink Model",
             subtitle="driver_monitor_sim_identification.slx",
             items=[
                 "UDP Receive Block (Port 25000)",
                 "DEMUX (11 Output Ports)",
                 "NaN Safety Condition Filter",
                 "S1: Blink Duration & Yawn Detectors",
                 "S2: Distraction State Machine",
                 "    (Normal, Visual Distraction, Eye Closed)",
                 "S3: Driver Identification Verification",
                 "    (Unknown Driver Lockout)",
                 "Temporal Hysteresis & Debouncing",
                 "Real-Time Diagnostic Scopes",
                 "Multi-Level Supervisory Warning Logic"
             ], title_color=c_sim_b)

    # Arrow: UDP -> Simulink
    draw_arrow(15.2, 8.4, 15.8, 8.4, "88-Byte UDP", color=c_udp_b, lw=2.2)

    # 6. Layer 5: ALERT & MONITORING OUTPUTS (Right edge / bottom right)
    draw_box(15.8, 1.4, 3.6, 3.4, c_alert, c_alert_b, "5. Warning & Status Outputs",
             subtitle="Driver Safety Interface",
             items=[
                 "Level 0: Attentive & Authorized (Green)",
                 "Level 1: Caution - Brief Inattention",
                 "Level 2: Warning - Persistent Distraction",
                 "Level 3: Critical - Drowsiness / Microsleep",
                 "Unknown Driver Status Interlock",
                 "Auditory Alert & Visual HUD Warning",
                 "Simulink Scope & Log Telemetry"
             ], title_color=c_alert_b)

    # Arrow: Simulink -> Alerts
    draw_arrow(17.6, 5.2, 17.6, 4.8, "Alert Triggers", color=c_alert_b, lw=2)

    # 7. Layer 6: OFFLINE EVALUATION WORKFLOW (Bottom Left, y: 1.4 to 4.2)
    draw_box(0.6, 1.4, 6.8, 3.4, c_offline, c_offline_b, "Offline Evaluation & Dataset Pipeline",
             subtitle="Independent Academic Validation Track",
             items=[
                 "Public Benchmarks: RLDD (Drowsiness) | YawDD (Yawn/Blink) | State Farm (Distraction)",
                 "FaceNet Model Weights & Verification Benchmark Dataset",
                 "Robustness Test Bench: 5 Simulated Lighting Scenarios (Day, Low, Glare)",
                 "Confusion Matrices: S1 (94.2% Acc), S2 (91.8% Acc), S3 (97.5% Acc)",
                 "Output Artifacts: CSV Metric Summaries & 300 DPI Validation Plots (Graph/)"
             ], title_color=c_offline_b)

    # 8. Layer 7: FUTURE EDGE AI EXTENSION (Bottom Center, y: 1.4 to 4.2)
    draw_box(7.8, 1.4, 7.4, 3.4, c_future, c_future_b, "[FUTURE EXTENSION] Edge AI Hardware Deployment",
             subtitle="Planned In-Vehicle Real-Time Unit (Not Yet Deployed)",
             items=[
                 "Target Hardware: Raspberry Pi 4 / 5 (Quad-Core ARM Cortex-A76) + Pi Camera V2/V3",
                 "Framework Optimization: OpenCV C++ / Python ONNX Runtime (Quantized INT8)",
                 "Projected Target Frame Rate: 18 - 25 FPS (without external GPU)",
                 "Automotive Integration: CAN-Bus Passive Warning Interface (Monitoring Only)",
                 "Strict Scope Boundary: Driver Alerting Only — Zero Autonomous Steering/Braking"
             ], dashed=True, title_color=c_future_b)

    # Offline arrow to Python Engine (dotted)
    draw_arrow(4.0, 4.8, 4.8, 4.8, "Trained Weights", color=c_offline_b, lw=1.2, style='->')
    # Python Engine to Future Edge (dashed arrow)
    draw_arrow(8.0, 4.5, 8.0, 4.8, "Target for Porting", color=c_future_b, lw=1.4, style='<-')

    plt.tight_layout()
    
    # Save outputs
    out_dir = Path("Graph")
    out_dir.mkdir(exist_ok=True, parents=True)
    
    png_path = out_dir / "architecture.png"
    svg_path = out_dir / "architecture.svg"
    
    plt.savefig(png_path, format="png", dpi=300, bbox_inches='tight')
    plt.savefig(svg_path, format="svg", bbox_inches='tight')
    plt.close()
    
    print(f"Architecture diagram saved to:\n- {png_path}\n- {svg_path}")

if __name__ == "__main__":
    create_diagram()
