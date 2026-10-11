%% MASTER DRIVER DATASET PIPELINE
% AI-Based Driver Behavior Monitoring
%
% Workflow:
%   MATLAB
%      -> runs Python preparation script
%      -> Python extracts/organizes genuine dataset samples
%      -> MATLAB reads the generated manifests
%      -> MATLAB creates consolidated CSV files
%      -> MATLAB creates graphs and summary
%
% Project scope:
%   1. Drowsiness detection
%   2. Distraction / attention detection
%   3. Driver identification
%
% No autonomous vehicle control is included.
%
% IMPORTANT:
% This script does NOT fabricate predictions. Ground truth and prediction
% columns are kept separate. Prediction columns are NaN until the actual
% AI/Simulink algorithm supplies them.

clear;
clc;
close all;

fprintf('\n=============================================\n');
fprintf(' MASTER DRIVER DATASET PIPELINE\n');
fprintf(' MATLAB -> PYTHON INPUTS -> CSV -> GRAPHS\n');
fprintf('=============================================\n\n');

%% ---------------------------------------------------------------
% 1. PROJECT PATHS
% ---------------------------------------------------------------

PROJECT = 'D:\Academics\TY_SEM1\AE\AI based Driver Detector';
DATASET = fullfile(PROJECT, 'dataset');

PYTHON_SCRIPT = fullfile(PROJECT, 'prepare_real_driver_datasets.py');
PROCESSED = fullfile(DATASET, 'processed_real');
MANIFESTS = fullfile(PROCESSED, 'manifests');
RESULTS = fullfile(DATASET, 'matlab_dataset_results');

if ~exist(RESULTS, 'dir')
    mkdir(RESULTS);
end

fprintf('PROJECT : %s\n', PROJECT);
fprintf('DATASET : %s\n', DATASET);
fprintf('PYTHON  : %s\n', PYTHON_SCRIPT);
fprintf('OUTPUT  : %s\n\n', RESULTS);

if ~exist(PROJECT, 'dir')
    error('Project folder not found: %s', PROJECT);
end

if ~exist(PYTHON_SCRIPT, 'file')
    error(['Python preparation script not found:\n' PYTHON_SCRIPT ...
           '\nPlace prepare_real_driver_datasets.py in the project root.']);
end

%% ---------------------------------------------------------------
% 2. FIND PYTHON
% ---------------------------------------------------------------

fprintf('---------------------------------------------\n');
fprintf('PYTHON CHECK\n');
fprintf('---------------------------------------------\n');

[status, pythonCmd] = system('where python');
if status ~= 0
    [status, pythonCmd] = system('where py');
end

if status ~= 0
    error(['Python was not found in PATH. Install Python and ensure it ' ...
           'is available from MATLAB system().']);
end

pythonCmd = strtrim(splitlines(pythonCmd));
pythonCmd = pythonCmd(~cellfun('isempty', pythonCmd));

if isempty(pythonCmd)
    error('Could not determine Python executable.');
end

pythonExe = strtrim(pythonCmd{1});
fprintf('Python executable: %s\n', pythonExe);

% Check required Python packages.
fprintf('Checking OpenCV / NumPy...\n');
checkCmd = sprintf('"%s" -c "import cv2,numpy; print(''PYTHON_OK'')"', pythonExe);
[status, checkOut] = system(checkCmd);

if status ~= 0
    fprintf(2, '%s\n', checkOut);
    error('Python dependencies missing. Run: pip install opencv-python numpy');
end

fprintf('%s\n', strtrim(checkOut));

%% ---------------------------------------------------------------
% 3. MATLAB CALLS PYTHON PREPARATION SCRIPT
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------\n');
fprintf('RUNNING PYTHON DATASET PREPARATION\n');
fprintf('---------------------------------------------\n');

% Python script performs:
%   S1: real UTA-RLDD video -> genuine frames
%   S2: real State Farm images -> organized labelled images
%   S3: real CASIA-WebFace train.rec -> genuine face images
%
% MATLAB waits until Python finishes.

cmd = sprintf('"%s" "%s"', pythonExe, PYTHON_SCRIPT);

fprintf('Command:\n%s\n\n', cmd);

tic;
[status, pyOutput] = system(cmd);
pythonTime = toc;

fprintf('%s\n', pyOutput);

if status ~= 0
    error('Python dataset preparation failed. Exit code: %d', status);
end

fprintf('Python preparation completed in %.2f seconds.\n', pythonTime);

%% ---------------------------------------------------------------
% 4. CHECK MANIFESTS
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------\n');
fprintf('CHECKING PYTHON OUTPUTS\n');
fprintf('---------------------------------------------\n');

s1Manifest = fullfile(MANIFESTS, 'section1_manifest.csv');
s2Manifest = fullfile(MANIFESTS, 'section2_manifest.csv');
s3Manifest = fullfile(MANIFESTS, 'section3_manifest.csv');

requiredFiles = {s1Manifest, s2Manifest, s3Manifest};

for k = 1:numel(requiredFiles)
    if ~exist(requiredFiles{k}, 'file')
        error('Required manifest missing: %s', requiredFiles{k});
    end
end

fprintf('All three manifests found.\n');

%% ---------------------------------------------------------------
% 5. READ S1
% ---------------------------------------------------------------

fprintf('\n[S1] Loading drowsiness manifest...\n');

S1 = readtable(s1Manifest, 'TextType', 'string');

% Standardize fields.
if ~ismember('ground_truth', S1.Properties.VariableNames)
    S1.ground_truth = strings(height(S1),1);
end

if ~ismember('image_path', S1.Properties.VariableNames)
    error('S1 manifest does not contain image_path.');
end

S1.Section = repmat("S1_Drowsiness", height(S1), 1);
S1.Prediction = nan(height(S1),1);
S1.ProcessingTime_ms = nan(height(S1),1);
S1.FPS = nan(height(S1),1);

% Keep genuine temporal source information.
if ~ismember('frame_number', S1.Properties.VariableNames)
    S1.frame_number = nan(height(S1),1);
end

if ~ismember('source_fps', S1.Properties.VariableNames)
    S1.source_fps = nan(height(S1),1);
end

fprintf('[S1] Samples: %d\n', height(S1));

%% ---------------------------------------------------------------
% 6. READ S2
% ---------------------------------------------------------------

fprintf('\n[S2] Loading distraction manifest...\n');

S2 = readtable(s2Manifest, 'TextType', 'string');

if ~ismember('distraction_ground_truth', S2.Properties.VariableNames)
    S2.distraction_ground_truth = strings(height(S2),1);
end

if ~ismember('image_path', S2.Properties.VariableNames)
    error('S2 manifest does not contain image_path.');
end

S2.Section = repmat("S2_Distraction", height(S2), 1);
S2.Prediction = nan(height(S2),1);
S2.ProcessingTime_ms = nan(height(S2),1);
S2.FPS = nan(height(S2),1);

fprintf('[S2] Samples: %d\n', height(S2));

%% ---------------------------------------------------------------
% 7. READ S3
% ---------------------------------------------------------------

fprintf('\n[S3] Loading identification manifest...\n');

S3 = readtable(s3Manifest, 'TextType', 'string');

if ~ismember('identity_ground_truth', S3.Properties.VariableNames)
    S3.identity_ground_truth = strings(height(S3),1);
end

if ~ismember('image_path', S3.Properties.VariableNames)
    error('S3 manifest does not contain image_path.');
end

S3.Section = repmat("S3_Identification", height(S3), 1);
S3.Prediction = nan(height(S3),1);
S3.ProcessingTime_ms = nan(height(S3),1);
S3.FPS = nan(height(S3),1);

fprintf('[S3] Samples: %d\n', height(S3));

%% ---------------------------------------------------------------
% 8. GENERATE SECTION CSV FILES
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------\n');
fprintf('GENERATING SECTION CSV FILES\n');
fprintf('---------------------------------------------\n');

% S1
S1CSV = table( ...
    S1.sample_id, ...
    S1.image_path, ...
    S1.ground_truth, ...
    S1.Prediction, ...
    S1.frame_number, ...
    S1.source_fps, ...
    S1.ProcessingTime_ms, ...
    S1.FPS, ...
    'VariableNames', { ...
    'SampleID','ImagePath','GroundTruth','Prediction', ...
    'FrameNumber','SourceFPS','ProcessingTime_ms','FPS'});

writetable(S1CSV, fullfile(RESULTS, 'Section1_Drowsiness_Results.csv'));

% S2
S2CSV = table( ...
    S2.sample_id, ...
    S2.image_path, ...
    S2.class, ...
    S2.distraction_ground_truth, ...
    S2.Prediction, ...
    S2.ProcessingTime_ms, ...
    S2.FPS, ...
    'VariableNames', { ...
    'SampleID','ImagePath','Class','GroundTruth', ...
    'Prediction','ProcessingTime_ms','FPS'});

writetable(S2CSV, fullfile(RESULTS, 'Section2_Distraction_Results.csv'));

% S3
S3CSV = table( ...
    S3.sample_id, ...
    S3.image_path, ...
    S3.identity_ground_truth, ...
    S3.Prediction, ...
    S3.ProcessingTime_ms, ...
    S3.FPS, ...
    'VariableNames', { ...
    'SampleID','ImagePath','GroundTruth','Prediction', ...
    'ProcessingTime_ms','FPS'});

writetable(S3CSV, fullfile(RESULTS, 'results/identification/Section3_Identification_Results.csv'));

fprintf('S1 CSV written.\n');
fprintf('S2 CSV written.\n');
fprintf('S3 CSV written.\n');

%% ---------------------------------------------------------------
% 9. MASTER CSV
% ---------------------------------------------------------------

fprintf('\nGenerating master CSV...\n');

n1 = height(S1);
n2 = height(S2);
n3 = height(S3);

Master = table( ...
    [repmat("S1_Drowsiness",n1,1); ...
     repmat("S2_Distraction",n2,1); ...
     repmat("S3_Identification",n3,1)], ...
    [S1.sample_id; S2.sample_id; S3.sample_id], ...
    [S1.image_path; S2.image_path; S3.image_path], ...
    [S1.ground_truth; S2.distraction_ground_truth; S3.identity_ground_truth], ...
    [S1.Prediction; S2.Prediction; S3.Prediction], ...
    [S1.ProcessingTime_ms; S2.ProcessingTime_ms; S3.ProcessingTime_ms], ...
    [S1.FPS; S2.FPS; S3.FPS], ...
    'VariableNames', {'Section','SampleID','ImagePath', ...
    'GroundTruth','Prediction','ProcessingTime_ms','FPS'});

writetable(Master, fullfile(RESULTS, 'PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv'));

%% ---------------------------------------------------------------
% 10. GRAPH 1 - DATASET SAMPLE COUNTS
% ---------------------------------------------------------------

figure('Name','Dataset Sample Counts','NumberTitle','off');

counts = [n1 n2 n3];

bar(counts);
grid on;
xticks(1:3);
xticklabels({'S1 Drowsiness','S2 Distraction','S3 Identification'});
ylabel('Number of genuine samples');
title('Real Dataset Sample Counts');

saveas(gcf, fullfile(RESULTS, '01_Dataset_Sample_Counts.png'));

%% ---------------------------------------------------------------
% 11. GRAPH 2 - S1 GROUND-TRUTH DISTRIBUTION
% ---------------------------------------------------------------

figure('Name','S1 Ground Truth','NumberTitle','off');

labels1 = categorical(S1.ground_truth);
valid1 = S1.ground_truth ~= "" & S1.ground_truth ~= "unknown";

if any(valid1)
    histogram(categorical(S1.ground_truth(valid1)));
    grid on;
    ylabel('Number of frames');
    xlabel('Ground-truth state');
    title('S1 UTA-RLDD Ground-Truth Distribution');
else
    text(0.5,0.5,'Ground truth not available in source path', ...
        'HorizontalAlignment','center');
    axis off;
    title('S1 Ground Truth');
end

saveas(gcf, fullfile(RESULTS, '02_S1_GroundTruth_Distribution.png'));

%% ---------------------------------------------------------------
% 12. GRAPH 3 - S2 CLASS DISTRIBUTION
% ---------------------------------------------------------------

figure('Name','S2 Class Distribution','NumberTitle','off');

if ismember('class', S2.Properties.VariableNames)
    histogram(categorical(S2.class));
    grid on;
    xlabel('State Farm class');
    ylabel('Number of images');
    title('S2 Distraction Class Distribution');
end

saveas(gcf, fullfile(RESULTS, '03_S2_Class_Distribution.png'));

%% ---------------------------------------------------------------
% 13. GRAPH 4 - S2 DISTRACTED VS SAFE
% ---------------------------------------------------------------

figure('Name','S2 Safe vs Distracted','NumberTitle','off');

histogram(categorical(S2.distraction_ground_truth));
grid on;
xlabel('Ground-truth attention state');
ylabel('Number of images');
title('S2 Safe vs Distracted Distribution');

saveas(gcf, fullfile(RESULTS, '04_S2_Safe_vs_Distracted.png'));

%% ---------------------------------------------------------------
% 14. GRAPH 5 - S3 IDENTITY DISTRIBUTION
% ---------------------------------------------------------------

figure('Name','S3 Identity Distribution','NumberTitle','off');

if height(S3) > 0
    identities = categorical(S3.identity_ground_truth);
    histogram(identities);
    grid on;
    xlabel('Identity label');
    ylabel('Number of face images');
    title('S3 CASIA-WebFace Identity Distribution');
end

saveas(gcf, fullfile(RESULTS, '05_S3_Identity_Distribution.png'));

%% ---------------------------------------------------------------
% 15. GRAPH 6 - S1 SOURCE FPS
% ---------------------------------------------------------------

figure('Name','S1 Source FPS','NumberTitle','off');

if ismember('source_fps', S1.Properties.VariableNames)
    fpsVals = S1.source_fps;
    fpsVals = fpsVals(isfinite(fpsVals) & fpsVals > 0);

    if ~isempty(fpsVals)
        histogram(fpsVals);
        grid on;
        xlabel('Video FPS');
        ylabel('Frames');
        title('S1 Source Video Frame Rate');
    else
        text(0.5,0.5,'Source FPS unavailable', ...
            'HorizontalAlignment','center');
        axis off;
    end
end

saveas(gcf, fullfile(RESULTS, '06_S1_Source_FPS.png'));

%% ---------------------------------------------------------------
% 16. WRITE SUMMARY
% ---------------------------------------------------------------

summaryFile = fullfile(RESULTS, 'Dataset_Processing_Summary.txt');

fid = fopen(summaryFile,'w');

fprintf(fid, 'AI-BASED DRIVER BEHAVIOR MONITORING\n');
fprintf(fid, 'REAL DATASET PROCESSING SUMMARY\n');
fprintf(fid, '=============================================\n\n');

fprintf(fid, 'Project: %s\n\n', PROJECT);

fprintf(fid, 'S1 - Drowsiness Detection\n');
fprintf(fid, '  Genuine extracted frames: %d\n', n1);
fprintf(fid, '  Source: UTA-RLDD real videos\n\n');

fprintf(fid, 'S2 - Distraction Detection\n');
fprintf(fid, '  Samples in manifest: %d\n', n2);
fprintf(fid, '  Source: State Farm Distracted Driver dataset\n\n');

fprintf(fid, 'S3 - Driver Identification\n');
fprintf(fid, '  Genuine extracted face images: %d\n', n3);
fprintf(fid, '  Source: CASIA-WebFace train.rec\n\n');

fprintf(fid, 'TOTAL MANIFEST SAMPLES: %d\n\n', n1+n2+n3);

fprintf(fid, 'Processing architecture:\n');
fprintf(fid, 'MATLAB -> Python dataset preparation -> MATLAB CSV/graphs\n\n');

fprintf(fid, 'Ground truth and prediction are kept separate.\n');
fprintf(fid, 'Prediction values are NaN until the actual AI algorithm supplies them.\n');
fprintf(fid, 'No artificial samples or fabricated performance values are generated.\n');
fprintf(fid, 'PC FPS must not be reported as Raspberry Pi FPS.\n');

fclose(fid);

%% ---------------------------------------------------------------
% 17. FINAL STATUS
% ---------------------------------------------------------------

fprintf('\n=============================================\n');
fprintf('DONE\n');
fprintf('=============================================\n');

fprintf('S1 genuine frames : %d\n', n1);
fprintf('S2 samples         : %d\n', n2);
fprintf('S3 face images     : %d\n', n3);
fprintf('TOTAL              : %d\n\n', n1+n2+n3);

fprintf('CSV files:\n');
fprintf('  %s\n', fullfile(RESULTS,'Section1_Drowsiness_Results.csv'));
fprintf('  %s\n', fullfile(RESULTS,'Section2_Distraction_Results.csv'));
fprintf('  %s\n', fullfile(RESULTS,'results/identification/Section3_Identification_Results.csv'));
fprintf('  %s\n', fullfile(RESULTS,'PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv'));

fprintf('\nGraphs and summary:\n');
fprintf('  %s\n', RESULTS);

fprintf('\nNOTE:\n');
fprintf('The CSV Prediction columns are intentionally empty/NaN at this stage.\n');
fprintf('They must be populated by the actual drowsiness, distraction, and\n');
fprintf('identification AI algorithms rather than by fabricated rules.\n\n');

fprintf('=============================================\n');
