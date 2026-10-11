function FINAL_GRAPH_GENERATOR()
% ================================================================
% AI-BASED DRIVER BEHAVIOR MONITORING
% FINAL GRAPH GENERATOR
%
% Creates EXACTLY 3 final figures:
%
%   FIGURE 1 -> S1 Drowsiness Detection
%   FIGURE 2 -> S2 Distraction / Attention
%   FIGURE 3 -> S3 Driver Identification
%
% IMPORTANT:
%   - Reads EXISTING CSV results only.
%   - Does NOT run Python.
%   - Does NOT process datasets.
%   - Does NOT rerun AI inference.
%   - Does NOT fabricate missing measurements.
%
% ================================================================

clc;
close all;

%% ================================================================
% FULL PROJECT PATHS
% ================================================================

PROJECT_ROOT = ...
    'D:\Academics\TY_SEM1\AE\AI based Driver Detector';

CSV_DIR = fullfile(PROJECT_ROOT,'results','CSV');

GRAPH_DIR = fullfile(PROJECT_ROOT,'results','Graphs');

%% Create graph directory if required

if ~exist(GRAPH_DIR,'dir')
    mkdir(GRAPH_DIR);
end

fprintf('\n');
fprintf('============================================================\n');
fprintf(' FINAL GRAPH GENERATOR\n');
fprintf('============================================================\n');
fprintf('Project : %s\n',PROJECT_ROOT);
fprintf('CSV     : %s\n',CSV_DIR);
fprintf('Graphs  : %s\n',GRAPH_DIR);
fprintf('============================================================\n');

%% ================================================================
% EXACT INPUT FILES
% ================================================================

S1_FILE = fullfile(CSV_DIR,'Section1_Drowsiness_Results.csv');

S2_FILE = fullfile(CSV_DIR,'Section2_Distraction_Results.csv');

S3_FILE = fullfile(CSV_DIR,'S3_Identification_Results.csv');

%% Check files

if ~exist(S1_FILE,'file')
    error('S1 result file not found:\n%s',S1_FILE);
end

if ~exist(S2_FILE,'file')
    error('S2 result file not found:\n%s',S2_FILE);
end

if ~exist(S3_FILE,'file')

    % Fallback only if REAL file does not exist
    S3_FILE = fullfile(CSV_DIR,'S3_Identification_Results.csv');

    if ~exist(S3_FILE,'file')
        error('S3 result file not found.');
    end

end

%% ================================================================
% LOAD EXISTING RESULTS
% ================================================================

S1 = readtable(S1_FILE,'VariableNamingRule','preserve');

S2 = readtable(S2_FILE,'VariableNamingRule','preserve');

S3 = readtable(S3_FILE,'VariableNamingRule','preserve');

fprintf('\nExisting result files loaded:\n');
fprintf('S1 rows = %d\n',height(S1));
fprintf('S2 rows = %d\n',height(S2));
fprintf('S3 rows = %d\n',height(S3));

%% ================================================================
% DELETE OLD FINAL FIGURES ONLY
% ================================================================

oldFiles = {
    'FIG1_S1_Drowsiness_Final.png'
    'FIG1_S1_Drowsiness_Final.fig'
    'FIG2_S2_Distraction_Final.png'
    'FIG2_S2_Distraction_Final.fig'
    'FIG3_S3_Identification_Final.png'
    'FIG3_S3_Identification_Final.fig'
    };

for k = 1:length(oldFiles)

    f = fullfile(GRAPH_DIR,oldFiles{k});

    if exist(f,'file')
        delete(f);
    end

end

%% ================================================================
% ================================================================
% FIGURE 1
% S1 - DROWSINESS DETECTION
% ================================================================
% ================================================================

fprintf('\nCreating FIGURE 1 - S1 Drowsiness...\n');

fig1 = figure( ...
    'Name','S1 - Drowsiness Detection', ...
    'Color','w', ...
    'Position',[50 50 1500 900]);

tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

%% ------------------------------------------------
% S1 PANEL 1
% EAR + MAR
% ------------------------------------------------

nexttile;

x1 = getNumeric(S1,'Timestamp_s');

EAR = getNumeric(S1,'EAR');

MAR = getNumeric(S1,'MAR');

plotMeasured(x1,EAR,'EAR');
hold on;

plotMeasured(x1,MAR,'MAR');

grid on;

xlabel('Time / Sample');
ylabel('Feature Value');

title('Eye and Mouth Features');

legend('EAR','MAR','Location','best');

%% ------------------------------------------------
% S1 PANEL 2
% PERCLOS + BLINK + YAWN
% ------------------------------------------------

nexttile;

PERCLOS = getNumeric(S1,'PERCLOS');

BLINK = getNumeric(S1,'Blink');

YAWN = getNumeric(S1,'Yawning');

plotMeasured(x1,PERCLOS,'PERCLOS');
hold on;

plotMeasured(x1,BLINK,'Blink');
plotMeasured(x1,YAWN,'Yawning');

grid on;

xlabel('Time / Sample');
ylabel('Measured Value');

title('Temporal Drowsiness Indicators');

legend( ...
    'PERCLOS', ...
    'Blink', ...
    'Yawning', ...
    'Location','best');

%% ------------------------------------------------
% S1 PANEL 3
% HEAD POSE + GAZE
% ------------------------------------------------

nexttile;

HEAD_YAW = getNumeric(S1,'Head_Pose_Yaw');

HEAD_PITCH = getNumeric(S1,'Head_Pose_Pitch');

HEAD_ROLL = getNumeric(S1,'Head_Pose_Roll');

plotMeasured(x1,HEAD_YAW,'Head Yaw');
hold on;

plotMeasured(x1,HEAD_PITCH,'Head Pitch');

plotMeasured(x1,HEAD_ROLL,'Head Roll');

grid on;

xlabel('Time / Sample');

ylabel('Angle (deg)');

title('Head Pose');

legend( ...
    'Yaw', ...
    'Pitch', ...
    'Roll', ...
    'Location','best');

%% ------------------------------------------------
% S1 PANEL 4
% GAZE + DROWSINESS OUTPUT
% ------------------------------------------------

nexttile;

GAZE = string(S1.Gaze_State);

validGaze = ...
    ~ismissing(GAZE) & ...
    GAZE ~= "";

if any(validGaze)

    gazeCategories = categories( ...
        categorical(GAZE(validGaze)));

    gazeCounts = zeros(length(gazeCategories),1);

    for k = 1:length(gazeCategories)

        gazeCounts(k) = sum( ...
            GAZE(validGaze) == string(gazeCategories{k}));

    end

    bar( ...
        categorical(gazeCategories), ...
        gazeCounts);

    ylabel('Samples');

    xlabel('Gaze State');

    title('Gaze State Distribution');

    grid on;

else

    text( ...
        0.5, ...
        0.5, ...
        'No valid gaze data', ...
        'HorizontalAlignment','center');

    axis off;

end

%% ------------------------------------------------
% S1 OVERALL TITLE
% ------------------------------------------------

sgtitle( ...
    'S1 - Driver Drowsiness Detection: EAR, MAR, PERCLOS, Blink, Yawn, Head Pose and Gaze', ...
    'FontWeight','bold', ...
    'FontSize',15);

%% ------------------------------------------------
% S1 INFORMATION
% ------------------------------------------------

faceDetected = getNumeric(S1,'Face_Detected');

validEAR = sum(~isnan(EAR));

validMAR = sum(~isnan(MAR));

validPERCLOS = sum(~isnan(PERCLOS));

validBlink = sum(~isnan(BLINK));

validYawn = sum(~isnan(YAWN));

validFace = sum(faceDetected == 1);

annotation( ...
    fig1, ...
    'textbox', ...
    [0.03 0.005 0.94 0.035], ...
    'String', ...
    sprintf( ...
    'Rows: %d | Face detected: %d | EAR: %d | MAR: %d | PERCLOS: %d | Blink: %d | Yawn: %d | Values from existing S1 CSV only', ...
    height(S1), ...
    validFace, ...
    validEAR, ...
    validMAR, ...
    validPERCLOS, ...
    validBlink, ...
    validYawn), ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'FontSize',9);

%% Save S1

exportgraphics( ...
    fig1, ...
    fullfile(GRAPH_DIR,'FIG1_S1_Drowsiness_Final.png'), ...
    'Resolution',250);

savefig( ...
    fig1, ...
    fullfile(GRAPH_DIR,'FIG1_S1_Drowsiness_Final.fig'));

close(fig1);

fprintf('S1 figure saved.\n');

%% ================================================================
% ================================================================
% FIGURE 2
% S2 - DISTRACTION / ATTENTION
% ================================================================
% ================================================================

fprintf('\nCreating FIGURE 2 - S2 Distraction...\n');

fig2 = figure( ...
    'Name','S2 - Driver Distraction and Attention', ...
    'Color','w', ...
    'Position',[50 50 1500 900]);

tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

x2 = (1:height(S2))';

%% ------------------------------------------------
% S2 PANEL 1
% HEAD POSE
% ------------------------------------------------

nexttile;

YAW = getNumeric(S2,'Head_Pose_Yaw');

PITCH = getNumeric(S2,'Head_Pose_Pitch');

ROLL = getNumeric(S2,'Head_Pose_Roll');

plotMeasured(x2,YAW,'Yaw');
hold on;

plotMeasured(x2,PITCH,'Pitch');

plotMeasured(x2,ROLL,'Roll');

grid on;

xlabel('Sample');

ylabel('Angle (deg)');

title('Head Pose for Attention Estimation');

legend( ...
    'Yaw', ...
    'Pitch', ...
    'Roll', ...
    'Location','best');

%% ------------------------------------------------
% S2 PANEL 2
% GAZE DIRECTION
% ------------------------------------------------

nexttile;

GAZE2 = string(S2.Gaze_State);

validGaze2 = ...
    ~ismissing(GAZE2) & ...
    GAZE2 ~= "";

if any(validGaze2)

    gazeCategories2 = categories( ...
        categorical(GAZE2(validGaze2)));

    gazeCounts2 = zeros(length(gazeCategories2),1);

    for k = 1:length(gazeCategories2)

        gazeCounts2(k) = sum( ...
            GAZE2(validGaze2) == ...
            string(gazeCategories2{k}));

    end

    bar( ...
        categorical(gazeCategories2), ...
        gazeCounts2);

    grid on;

    xlabel('Gaze Direction');

    ylabel('Samples');

    title('Driver Gaze Direction');

else

    text( ...
        0.5, ...
        0.5, ...
        'No valid gaze data', ...
        'HorizontalAlignment','center');

    axis off;

end

%% ------------------------------------------------
% S2 PANEL 3
% HANDS + LOOKING AWAY
% ------------------------------------------------

nexttile;

LEFT_HAND = getNumeric(S2,'Left_Hand_On_Steering');

RIGHT_HAND = getNumeric(S2,'Right_Hand_On_Steering');

HANDS = getNumeric(S2,'Hands_On_Steering');

LOOKING_AWAY = getNumeric(S2,'Looking_Away');

plotMeasured(x2,LEFT_HAND,'Left hand');
hold on;

plotMeasured(x2,RIGHT_HAND,'Right hand');

plotMeasured(x2,HANDS,'Hands on steering');

plotMeasured(x2,LOOKING_AWAY,'Looking away');

grid on;

xlabel('Sample');

ylabel('State');

title('Steering and Attention Indicators');

legend( ...
    'Left hand', ...
    'Right hand', ...
    'Hands on steering', ...
    'Looking away', ...
    'Location','best');

%% ------------------------------------------------
% S2 PANEL 4
% DISTRACTION OUTPUT
% ------------------------------------------------

nexttile;

PRED2 = getNumeric(S2,'Distraction_Prediction');

ALERT2 = getNumeric(S2,'Distraction_Alert');

predictionCounts = [ ...
    sum(PRED2 == 0), ...
    sum(PRED2 == 1)];

alertCounts = [ ...
    sum(ALERT2 == 0), ...
    sum(ALERT2 == 1)];

outputData = [ ...
    predictionCounts; ...
    alertCounts];

bar(outputData);

grid on;

xlabel('System Output');

ylabel('Samples');

title('Distraction Prediction and Alert');

xticks(1:2);

xticklabels({ ...
    'Prediction', ...
    'Alert'});

legend( ...
    '0 = Normal', ...
    '1 = Distracted / Alert', ...
    'Location','best');

%% ------------------------------------------------
% S2 TITLE
% ------------------------------------------------

sgtitle( ...
    'S2 - Driver Distraction / Attention: Head Pose, Gaze, Steering and System Output', ...
    'FontWeight','bold', ...
    'FontSize',15);

%% ------------------------------------------------
% S2 INFORMATION
% ------------------------------------------------

face2 = getNumeric(S2,'Face_Detected');

validHead = sum(~isnan(YAW));

validGazeCount = sum(validGaze2);

validHands = sum(~isnan(HANDS));

validLook = sum(~isnan(LOOKING_AWAY));

validPrediction = sum(~isnan(PRED2));

validAlert = sum(~isnan(ALERT2));

annotation( ...
    fig2, ...
    'textbox', ...
    [0.03 0.005 0.94 0.035], ...
    'String', ...
    sprintf( ...
    'Rows: %d | Face detected: %d | Head-pose samples: %d | Gaze samples: %d | Hand samples: %d | Looking-away: %d | Predictions: %d | Alerts: %d', ...
    height(S2), ...
    sum(face2 == 1), ...
    validHead, ...
    validGazeCount, ...
    validHands, ...
    validLook, ...
    validPrediction, ...
    validAlert), ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'FontSize',9);

%% Save S2

exportgraphics( ...
    fig2, ...
    fullfile(GRAPH_DIR,'FIG2_S2_Distraction_Final.png'), ...
    'Resolution',250);

savefig( ...
    fig2, ...
    fullfile(GRAPH_DIR,'FIG2_S2_Distraction_Final.fig'));

close(fig2);

fprintf('S2 figure saved.\n');

%% ================================================================
% ================================================================
% FIGURE 3
% S3 - DRIVER IDENTIFICATION
% ================================================================
% ================================================================

fprintf('\nCreating FIGURE 3 - S3 Driver Identification...\n');

fig3 = figure( ...
    'Name','S3 - Driver Identification', ...
    'Color','w', ...
    'Position',[40 50 1550 900]);

tiledlayout(1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

%% ------------------------------------------------
% S3 PANEL 1
% CONFUSION MATRIX
% ------------------------------------------------

nexttile;

GT3 = string(S3.Driver_ID_GroundTruth);

PRED3 = getNumeric(S3,'Raw_Predicted_ID');

valid3 = ...
    ~ismissing(GT3) & ...
    GT3 ~= "" & ...
    ~isnan(PRED3);

GT3 = GT3(valid3);

PRED3 = PRED3(valid3);

PRED3_STRING = string(PRED3);

driverClasses = unique( ...
    [GT3; PRED3_STRING], ...
    'stable');

CM = zeros( ...
    length(driverClasses), ...
    length(driverClasses));

for i = 1:length(GT3)

    r = find( ...
        driverClasses == GT3(i),1);

    c = find( ...
        driverClasses == PRED3_STRING(i),1);

    if ~isempty(r) && ~isempty(c)

        CM(r,c) = CM(r,c) + 1;

    end

end

imagesc(CM);

axis square;

grid on;

xlabel('Predicted Driver ID');

ylabel('Ground Truth Driver ID');

title('Driver Identification Confusion Matrix');

xticks(1:length(driverClasses));

yticks(1:length(driverClasses));

xticklabels(driverClasses);

yticklabels(driverClasses);

colorbar;

for r = 1:size(CM,1)

    for c = 1:size(CM,2)

        if CM(r,c) > 0

            text( ...
                c, ...
                r, ...
                num2str(CM(r,c)), ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold', ...
                'Color','w');

        end

    end

end

%% ------------------------------------------------
% S3 PANEL 2
% SCORE + STATUS
% ------------------------------------------------

nexttile;

SCORE3 = getNumeric(S3,'Raw_Score');

STATUS3 = string(S3.Prediction_Status);

validScore3 = ...
    SCORE3(~isnan(SCORE3));

%% Score distribution

histogram( ...
    validScore3, ...
    20);

grid on;

hold on;

xlabel('Recognition Similarity Score');

ylabel('Number of Samples');

title('Recognition Score and Decision Status');

%% Status counts

correct3 = sum(STATUS3 == "CORRECT");

incorrect3 = sum(STATUS3 == "INCORRECT");

unknown3 = sum(STATUS3 == "UNKNOWN");

statusCounts = [ ...
    correct3, ...
    incorrect3, ...
    unknown3];

yyaxis right;

plot( ...
    1:3, ...
    statusCounts, ...
    'o-', ...
    'LineWidth',2);

xticks(1:3);

xticklabels({ ...
    'Correct', ...
    'Incorrect', ...
    'Unknown'});

ylabel('Samples');

%% ------------------------------------------------
% S3 METRICS
% ------------------------------------------------

totalStatus = ...
    correct3 + incorrect3 + unknown3;

if totalStatus > 0

    identificationAccuracy = ...
        100 * correct3 / totalStatus;

else

    identificationAccuracy = NaN;

end

PROCESS3 = getNumeric( ...
    S3,'ProcessingTime_ms');

FPS3 = getNumeric( ...
    S3,'FPS');

validProcess3 = ...
    PROCESS3(~isnan(PROCESS3));

validFPS3 = ...
    FPS3(~isnan(FPS3));

if isempty(validProcess3)

    meanProcess3 = NaN;

else

    meanProcess3 = mean(validProcess3);

end

if isempty(validFPS3)

    meanFPS3 = NaN;

else

    meanFPS3 = mean(validFPS3);

end

%% ------------------------------------------------
% S3 TITLE
% ------------------------------------------------

sgtitle( ...
    sprintf( ...
    'S3 - Driver Identification: Accuracy %.2f%% | Mean PC FPS %.2f', ...
    identificationAccuracy, ...
    meanFPS3), ...
    'FontWeight','bold', ...
    'FontSize',15);

%% ------------------------------------------------
% S3 INFORMATION
% ------------------------------------------------

annotation( ...
    fig3, ...
    'textbox', ...
    [0.03 0.005 0.94 0.035], ...
    'String', ...
    sprintf( ...
    'Evaluated samples: %d | Correct: %d | Incorrect: %d | Unknown: %d | Mean processing: %.2f ms | Mean measured PC FPS: %.2f', ...
    totalStatus, ...
    correct3, ...
    incorrect3, ...
    unknown3, ...
    meanProcess3, ...
    meanFPS3), ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'FontSize',9);

%% Save S3

exportgraphics( ...
    fig3, ...
    fullfile(GRAPH_DIR,'FIG3_S3_Identification_Final.png'), ...
    'Resolution',250);

savefig( ...
    fig3, ...
    fullfile(GRAPH_DIR,'FIG3_S3_Identification_Final.fig'));

close(fig3);

fprintf('S3 figure saved.\n');

%% ================================================================
% FINAL OUTPUT
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' FINAL GRAPH GENERATION COMPLETE\n');
fprintf('============================================================\n');

fprintf('\nExactly THREE final figures generated:\n\n');

fprintf('1. %s\n', ...
    fullfile(GRAPH_DIR,'FIG1_S1_Drowsiness_Final.png'));

fprintf('2. %s\n', ...
    fullfile(GRAPH_DIR,'FIG2_S2_Distraction_Final.png'));

fprintf('3. %s\n', ...
    fullfile(GRAPH_DIR,'FIG3_S3_Identification_Final.png'));

fprintf('\nNo Python processing was performed.\n');
fprintf('No dataset processing was performed.\n');
fprintf('No AI inference was rerun.\n');
fprintf('No missing values were fabricated.\n');

fprintf('\n============================================================\n');

end


%% ================================================================
% HELPER FUNCTION
% GET NUMERIC COLUMN
% ================================================================

function v = getNumeric(T,columnName)

if ~ismember(columnName,T.Properties.VariableNames)

    v = nan(height(T),1);

    return;

end

raw = T.(columnName);

if isnumeric(raw)

    v = double(raw);

elseif islogical(raw)

    v = double(raw);

else

    v = str2double(string(raw));

end

v = v(:);

end


%% ================================================================
% HELPER FUNCTION
% PLOT ONLY VALID MEASUREMENTS
% ================================================================

function plotMeasured(x,y,labelName)

valid = ...
    ~isnan(x) & ...
    ~isnan(y);

if any(valid)

    plot( ...
        x(valid), ...
        y(valid), ...
        'LineWidth',1.0, ...
        'DisplayName',labelName);

else

    text( ...
        0.5, ...
        0.5, ...
        ['No valid ' labelName ' data'], ...
        'Units','normalized', ...
        'HorizontalAlignment','center');

end

end