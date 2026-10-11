import pandas as pd
import matplotlib.pyplot as plt
import os

def plot_and_save(df, x_col, y_col, title, save_path):
    if len(df) == 0 or x_col not in df.columns or y_col not in df.columns:
        return
    # Drop NaNs just for plotting
    df_plot = df.dropna(subset=[x_col, y_col])
    if len(df_plot) == 0:
        return
        
    plt.figure(figsize=(10, 4))
    plt.plot(df_plot[x_col], df_plot[y_col], label=y_col, color='tab:blue')
    plt.title(title)
    plt.xlabel(x_col)
    plt.ylabel(y_col)
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()

def main():
    # Ensure directories exist
    os.makedirs('results/section1', exist_ok=True)
    os.makedirs('results/section2', exist_ok=True)
    os.makedirs('results/section3', exist_ok=True)
    os.makedirs('results/performance', exist_ok=True)
    
    # Section 1
    if os.path.exists('Section1_Drowsiness_Results.csv'):
        df1 = pd.read_csv('Section1_Drowsiness_Results.csv')
        plot_and_save(df1, 'Frame_Number', 'EAR', 'EAR vs Frame', 'results/section1/section1_EAR_vs_Frame.png')
        plot_and_save(df1, 'Frame_Number', 'MAR', 'MAR vs Frame', 'results/section1/section1_MAR_vs_Frame.png')
        plot_and_save(df1, 'Frame_Number', 'Eye_State', 'Eye State vs Frame', 'results/section1/section1_Eye_State_vs_Frame.png')
        plot_and_save(df1, 'Frame_Number', 'PERCLOS', 'PERCLOS vs Frame', 'results/section1/section1_PERCLOS_vs_Frame.png')
        plot_and_save(df1, 'Frame_Number', 'Drowsiness_Prediction', 'Drowsiness Prediction vs Frame', 'results/section1/section1_Drowsiness_vs_Frame.png')
        
    # Section 2
    if os.path.exists('Section2_Distraction_Results.csv'):
        df2 = pd.read_csv('Section2_Distraction_Results.csv')
        plot_and_save(df2, 'Frame_Number', 'Head_Pose_Yaw', 'Head Yaw vs Frame', 'results/section2/section2_Yaw_vs_Frame.png')
        plot_and_save(df2, 'Frame_Number', 'Head_Pose_Pitch', 'Head Pitch vs Frame', 'results/section2/section2_Pitch_vs_Frame.png')
        plot_and_save(df2, 'Frame_Number', 'Hands_On_Steering', 'Hands On Steering vs Frame', 'results/section2/section2_Hands_On_Steering_vs_Frame.png')
        plot_and_save(df2, 'Frame_Number', 'Distraction_Prediction', 'Distraction vs Frame', 'results/section2/section2_Distraction_vs_Frame.png')
        
    # Section 3
    if os.path.exists('results/identification/Section3_Identification_Results.csv'):
        df3 = pd.read_csv('results/identification/Section3_Identification_Results.csv')
        plot_and_save(df3, 'Frame_Number', 'Identification_Confidence', 'ID Confidence vs Frame', 'results/section3/section3_Identity_Confidence_vs_Frame.png')
        
    # Performance (All Sections)
    if os.path.exists('PROJECT/Data/processed/Driver_Monitoring_All_Sections.csv'):
        df_all = pd.read_csv('PROJECT/Data/processed/Driver_Monitoring_All_Sections.csv')
        plot_and_save(df_all, 'Frame_Number', 'Processing_Time_ms', 'Processing Time (ms) vs Frame', 'results/performance/processing_time_all_sections.png')
        plot_and_save(df_all, 'Frame_Number', 'CPU_Usage_Percent', 'CPU Usage (%) vs Frame', 'results/performance/CPU_usage_all_sections.png')
        plot_and_save(df_all, 'Frame_Number', 'RAM_Usage_MB', 'RAM Usage (MB) vs Frame', 'results/performance/RAM_usage_all_sections.png')
        plot_and_save(df_all, 'Frame_Number', 'FPS', 'FPS vs Frame', 'results/performance/FPS_all_sections.png')

    print("Graphs generated in results/ directory.")

if __name__ == "__main__":
    main()
