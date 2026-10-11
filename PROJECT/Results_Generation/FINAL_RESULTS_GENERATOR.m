%% FINAL RESULTS GENERATOR
% AI-BASED DRIVER BEHAVIOR MONITORING
%
% Purpose:
%   Combine the already completed S1, S2 and S3 dataset manifests and
%   generate the FINAL CSV files, graphs and summaries in:
%
%   D:\Academics\TY_SEM1\AE\AI based Driver Detector\results
%
% Current completed dataset:
%   S1 = 5,847 genuine frames from UTA-RLDD videos
%   S2 = 22,423 real State Farm samples
%   S3 = 2,000 genuine face images, 15 identities
%
% IMPORTANT:
%   This script does NOT invent AI predictions or performance.
%   Prediction fields are NaN until the actual AI algorithms populate them.
%
% Run from MATLAB:
%   FINAL_RESULTS_GENERATOR

clear;
clc;
close all;

fprintf('\n=============================================\n');
fprintf(' FINAL DRIVER MONITORING RESULTS GENERATOR\n');
fprintf(' CSV + GRAPHS + SUMMARY\n');
fprintf('=============================================\n\n');

%% PATHS

PROJECT = 'D:\Academics\TY_SEM1\AE\AI based Driver Detector';

MANIFESTS = fullfile(PROJECT,'PROJECT','Data','processed_real','manifests');

% S3 temporary processor output
S3_TEMP = fullfile(PROJECT,'PROJECT','Data','matlab_dataset_results');

% FINAL output requested by user
RESULTS = fullfile(PROJECT,'results');

CSVOUT = fullfile(RESULTS,'CSV');
GRAPHOUT = fullfile(RESULTS,'Graphs');
SUMMARYOUT = fullfile(RESULTS,'Summary');

if ~exist(RESULTS,'dir'), mkdir(RESULTS); end
if ~exist(CSVOUT,'dir'), mkdir(CSVOUT); end
if ~exist(GRAPHOUT,'dir'), mkdir(GRAPHOUT); end
if ~exist(SUMMARYOUT,'dir'), mkdir(SUMMARYOUT); end

fprintf('FINAL OUTPUT:\n%s\n\n',RESULTS);

%% MANIFEST PATHS

S1FILE = fullfile(MANIFESTS,'section1_manifest.csv');
S2FILE = fullfile(MANIFESTS,'section2_manifest.csv');
S3FILE = fullfile(S3_TEMP,'S3_Identification_Temp_Results.csv');

if ~exist(S1FILE,'file')
    error('S1 manifest not found:\n%s',S1FILE);
end

if ~exist(S2FILE,'file')
    error('S2 manifest not found:\n%s',S2FILE);
end

if ~exist(S3FILE,'file')
    error('S3 temporary CSV not found:\n%s',S3FILE);
end

fprintf('All three input CSVs found.\n');

%% READ TABLES
% VariableNamingRule preserve prevents MATLAB from changing column names.

S1 = readtable(S1FILE,'TextType','string','VariableNamingRule','preserve');
S2 = readtable(S2FILE,'TextType','string','VariableNamingRule','preserve');
S3 = readtable(S3FILE,'TextType','string','VariableNamingRule','preserve');

fprintf('S1 input rows: %d\n',height(S1));
fprintf('S2 input rows: %d\n',height(S2));
fprintf('S3 input rows: %d\n',height(S3));

%% S1 FINAL TABLE

n1 = height(S1);

S1Sample = getStringColumn(S1,{'sample_id','SampleID'},n1);
S1Path = getStringColumn(S1,{'image_path','ImagePath'},n1);
S1GT = getStringColumn(S1,{'ground_truth','GroundTruth'},n1);

S1Frame = getNumericColumn(S1,{'frame_number','FrameNumber'},n1);
S1SourceFPS = getNumericColumn(S1,{'source_fps','SourceFPS'},n1);

S1Final = table( ...
    S1Sample, ...
    S1Path, ...
    S1GT, ...
    S1Frame, ...
    S1SourceFPS, ...
    nan(n1,1), ...
    nan(n1,1), ...
    nan(n1,1), ...
    'VariableNames',{ ...
    'SampleID','ImagePath','GroundTruth','FrameNumber', ...
    'SourceFPS','Prediction','ProcessingTime_ms','FPS'});

writetable(S1Final,fullfile(CSVOUT,'Section1_Drowsiness_Results.csv'));

%% S2 FINAL TABLE

n2 = height(S2);

S2Sample = getStringColumn(S2,{'sample_id','SampleID'},n2);
S2Path = getStringColumn(S2,{'image_path','ImagePath'},n2);
S2Class = getStringColumn(S2,{'class','Class'},n2);
S2GT = getStringColumn(S2,{'distraction_ground_truth','GroundTruth'},n2);
S2Split = getStringColumn(S2,{'split','Split'},n2);

S2Final = table( ...
    S2Sample, ...
    S2Path, ...
    S2Class, ...
    S2GT, ...
    S2Split, ...
    nan(n2,1), ...
    nan(n2,1), ...
    nan(n2,1), ...
    'VariableNames',{ ...
    'SampleID','ImagePath','Class','GroundTruth','Split', ...
    'Prediction','ProcessingTime_ms','FPS'});

writetable(S2Final,fullfile(CSVOUT,'Section2_Distraction_Results.csv'));

%% S3 FINAL TABLE

n3 = height(S3);

S3Sample = getStringColumn(S3,{'sample_id','SampleID'},n3);
S3Path = getStringColumn(S3,{'image_path','ImagePath'},n3);
S3GT = getStringColumn(S3,{'identity_ground_truth','IdentityGroundTruth','GroundTruth'},n3);

S3Final = table( ...
    S3Sample, ...
    S3Path, ...
    S3GT, ...
    nan(n3,1), ...
    nan(n3,1), ...
    nan(n3,1), ...
    'VariableNames',{ ...
    'SampleID','ImagePath','GroundTruth','Prediction', ...
    'ProcessingTime_ms','FPS'});

writetable(S3Final,fullfile(CSVOUT,'S3_Identification_Results.csv'));

%% MASTER DATASET CSV

MasterSection = [ ...
    repmat("S1_Drowsiness",n1,1); ...
    repmat("S2_Distraction",n2,1); ...
    repmat("S3_Identification",n3,1)];

MasterSample = [S1Final.SampleID;S2Final.SampleID;S3Final.SampleID];
MasterPath = [S1Final.ImagePath;S2Final.ImagePath;S3Final.ImagePath];
MasterGT = [S1Final.GroundTruth;S2Final.GroundTruth;S3Final.GroundTruth];
MasterPrediction = [S1Final.Prediction;S2Final.Prediction;S3Final.Prediction];
MasterTime = [S1Final.ProcessingTime_ms;S2Final.ProcessingTime_ms;S3Final.ProcessingTime_ms];
MasterFPS = [S1Final.FPS;S2Final.FPS;S3Final.FPS];

Master = table( ...
    MasterSection, ...
    MasterSample, ...
    MasterPath, ...
    MasterGT, ...
    MasterPrediction, ...
    MasterTime, ...
    MasterFPS, ...
    'VariableNames',{ ...
    'Section','SampleID','ImagePath','GroundTruth', ...
    'Prediction','ProcessingTime_ms','FPS'});

writetable(Master,fullfile(CSVOUT,'Master_Driver_Monitoring_Results.csv'));

fprintf('\nCSV FILES CREATED.\n');

%% GRAPH 1 - TOTAL DATASET COUNTS

figure('Name','Total Dataset Counts','NumberTitle','off');

bar([n1 n2 n3]);
grid on;
xticks(1:3);
xticklabels({'S1 Drowsiness','S2 Distraction','S3 Identification'});
ylabel('Genuine samples');
title('Driver Monitoring Dataset - Sample Counts');

saveas(gcf,fullfile(GRAPHOUT,'01_Total_Dataset_Sample_Counts.png'));

%% GRAPH 2 - S1 GROUND TRUTH

figure('Name','S1 Ground Truth','NumberTitle','off');

valid = S1Final.GroundTruth ~= "" & ...
        lower(S1Final.GroundTruth) ~= "unknown";

if any(valid)
    histogram(categorical(S1Final.GroundTruth(valid)));
    grid on;
    xlabel('Ground-truth state');
    ylabel('Number of frames');
    title('S1 Drowsiness Ground-Truth Distribution');
else
    text(0.5,0.5,'Ground truth unavailable in source labels', ...
        'HorizontalAlignment','center');
    axis off;
    title('S1 Drowsiness Ground Truth');
end

saveas(gcf,fullfile(GRAPHOUT,'02_S1_Drowsiness_GroundTruth.png'));

%% GRAPH 3 - S1 VIDEO FPS

figure('Name','S1 Video FPS','NumberTitle','off');

v = S1Final.SourceFPS;
v = v(isfinite(v) & v > 0);

if ~isempty(v)
    histogram(v);
    grid on;
    xlabel('Source video FPS');
    ylabel('Number of extracted frames');
    title('S1 UTA-RLDD Source Video Frame Rates');
else
    text(0.5,0.5,'No source FPS available', ...
        'HorizontalAlignment','center');
    axis off;
end

saveas(gcf,fullfile(GRAPHOUT,'03_S1_Source_FPS.png'));

%% GRAPH 4 - S2 TEN CLASSES

figure('Name','S2 Class Distribution','NumberTitle','off');

valid = S2Final.Class ~= "" & lower(S2Final.Class) ~= "unknown";

if any(valid)
    histogram(categorical(S2Final.Class(valid)));
    grid on;
    xlabel('State Farm class');
    ylabel('Number of images');
    title('S2 Distraction Class Distribution');
end

saveas(gcf,fullfile(GRAPHOUT,'04_S2_Class_Distribution.png'));

%% GRAPH 5 - S2 SAFE VS DISTRACTED

figure('Name','S2 Safe vs Distracted','NumberTitle','off');

valid = S2Final.GroundTruth ~= "" & lower(S2Final.GroundTruth) ~= "unknown";

if any(valid)
    histogram(categorical(S2Final.GroundTruth(valid)));
    grid on;
    xlabel('Ground-truth attention state');
    ylabel('Number of images');
    title('S2 Safe vs Distracted Distribution');
end

saveas(gcf,fullfile(GRAPHOUT,'05_S2_Safe_vs_Distracted.png'));

%% GRAPH 6 - S3 IDENTITY DISTRIBUTION

figure('Name','S3 Identity Distribution','NumberTitle','off');

histogram(categorical(S3Final.GroundTruth));
grid on;
xlabel('Identity');
ylabel('Number of face images');
title('S3 Driver Identification - Identity Distribution');

saveas(gcf,fullfile(GRAPHOUT,'06_S3_Identity_Distribution.png'));

%% GRAPH 7 - S3 IMAGES PER IDENTITY

ids = unique(S3Final.GroundTruth);
counts = zeros(numel(ids),1);

for k = 1:numel(ids)
    counts(k) = sum(S3Final.GroundTruth == ids(k));
end

figure('Name','S3 Samples Per Identity','NumberTitle','off');

bar(categorical(ids),counts);
grid on;
xlabel('Identity');
ylabel('Number of genuine images');
title('S3 Genuine Images Per Identity');

saveas(gcf,fullfile(GRAPHOUT,'07_S3_Samples_Per_Identity.png'));

%% GRAPH 8 - OVERALL DATASET

figure('Name','Overall Dataset Composition','NumberTitle','off');

pie([n1 n2 n3],{'S1 Drowsiness','S2 Distraction','S3 Identification'});
title('Overall Real Dataset Composition');

saveas(gcf,fullfile(GRAPHOUT,'08_Overall_Dataset_Composition.png'));

%% SUMMARY

fid = fopen(fullfile(SUMMARYOUT,'Dataset_Summary.txt'),'w');

fprintf(fid,'AI-BASED DRIVER BEHAVIOR MONITORING\n');
fprintf(fid,'REAL DATASET SUMMARY\n');
fprintf(fid,'=============================================\n\n');

fprintf(fid,'Project:\n%s\n\n',PROJECT);

fprintf(fid,'S1 - DROWSINESS DETECTION\n');
fprintf(fid,'Dataset: UTA-RLDD real-life videos\n');
fprintf(fid,'Videos processed: 20\n');
fprintf(fid,'Genuine extracted frames: %d\n\n',n1);

fprintf(fid,'S2 - DISTRACTION DETECTION\n');
fprintf(fid,'Dataset: State Farm Distracted Driver\n');
fprintf(fid,'Training images: 17,462\n');
fprintf(fid,'Test images: 4,961\n');
fprintf(fid,'Total manifest samples: %d\n\n',n2);

fprintf(fid,'S3 - DRIVER IDENTIFICATION\n');
fprintf(fid,'Dataset: extracted CASIA-WebFace subset\n');
fprintf(fid,'Identity folders: 15 (0 to 14)\n');
fprintf(fid,'Genuine face images: %d\n\n',n3);

fprintf(fid,'TOTAL GENUINE SAMPLES: %d\n\n',n1+n2+n3);

fprintf(fid,'OUTPUT LOCATION:\n%s\n\n',RESULTS);

fprintf(fid,'IMPORTANT:\n');
fprintf(fid,'Ground truth and prediction are separate.\n');
fprintf(fid,'Prediction fields are NaN until actual AI algorithms are executed.\n');
fprintf(fid,'No artificial samples or fabricated accuracy values are generated.\n');
fprintf(fid,'Computer FPS must not be reported as Raspberry Pi FPS.\n');

fclose(fid);

%% PROCESSING SUMMARY

fid = fopen(fullfile(SUMMARYOUT,'Processing_Summary.txt'),'w');

fprintf(fid,'FINAL RESULTS GENERATION SUMMARY\n');
fprintf(fid,'=============================================\n\n');

fprintf(fid,'S1 samples: %d\n',n1);
fprintf(fid,'S2 samples: %d\n',n2);
fprintf(fid,'S3 samples: %d\n',n3);
fprintf(fid,'TOTAL: %d\n\n',n1+n2+n3);

fprintf(fid,'CSV files generated:\n');
fprintf(fid,'Section1_Drowsiness_Results.csv\n');
fprintf(fid,'Section2_Distraction_Results.csv\n');
fprintf(fid,'S3_Identification_Results.csv\n');
fprintf(fid,'Master_Driver_Monitoring_Results.csv\n\n');

fprintf(fid,'Graphs generated: 8 PNG files.\n\n');

fprintf(fid,'This stage prepares and consolidates real dataset inputs.\n');
fprintf(fid,'AI prediction/performance must be populated by the actual project algorithms.\n');

fclose(fid);

%% FINAL COMMAND WINDOW STATUS

fprintf('\n=============================================\n');
fprintf(' FINAL RESULTS CREATED SUCCESSFULLY\n');
fprintf('=============================================\n');

fprintf('S1: %d genuine samples\n',n1);
fprintf('S2: %d genuine samples\n',n2);
fprintf('S3: %d genuine samples\n',n3);
fprintf('TOTAL: %d genuine samples\n\n',n1+n2+n3);

fprintf('CSV:\n%s\n',CSVOUT);
fprintf('\nGRAPHS:\n%s\n',GRAPHOUT);
fprintf('\nSUMMARY:\n%s\n',SUMMARYOUT);

fprintf('\nIMPORTANT: Prediction columns are NaN until actual AI processing.\n');
fprintf('=============================================\n');


%% LOCAL HELPER FUNCTIONS

function out = getStringColumn(T,names,n)
    out = strings(n,1);
    for i = 1:numel(names)
        idx = find(strcmp(T.Properties.VariableNames,names{i}),1);
        if ~isempty(idx)
            x = T{:,idx};
            if iscell(x)
                x = string(x);
            elseif iscategorical(x)
                x = string(x);
            elseif isnumeric(x)
                x = string(x);
            else
                x = string(x);
            end
            out = x;
            return;
        end
    end
end

function out = getNumericColumn(T,names,n)
    out = nan(n,1);
    for i = 1:numel(names)
        idx = find(strcmp(T.Properties.VariableNames,names{i}),1);
        if ~isempty(idx)
            x = T{:,idx};
            if isnumeric(x)
                out = double(x);
            else
                out = str2double(string(x));
            end
            return;
        end
    end
end
