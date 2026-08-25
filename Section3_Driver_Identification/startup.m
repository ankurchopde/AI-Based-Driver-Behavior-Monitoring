% startup.m
% Adds necessary Section folders to the MATLAB path so the Simulink model can locate its System Objects.

repo_root = fullfile(pwd, '..');

% Add Section 1 (Drowsiness System Objects)
addpath(fullfile(repo_root, 'Section1_Drowsiness'));

% Add Section 2 (Distraction System Objects)
addpath(fullfile(repo_root, 'Section2_Distraction'));

disp('Paths added successfully. You can now run driver_monitor_sim_identification.slx');
