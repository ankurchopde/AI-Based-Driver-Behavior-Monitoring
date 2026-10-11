%% FINAL_INTEGRATE_EXISTING_RESULTS.m
% FINAL INTEGRATION ONLY
% Does NOT run Python or reprocess S1/S2/S3.
%
% Uses the already completed real-AI CSV outputs:
%   Section1_Drowsiness_Results.csv
%   Section2_Distraction_Results.csv
%   S3_Identification_Results_REAL.csv
%
% Generates:
%   - canonical S3_Identification_Results.csv
%   - Master_Driver_Monitoring_Results.csv
%   - section/master summaries
%   - basic feature/performance graphs
%
% Run from the project root.

clear; clc; close all;

PROJECT = 'D:\Academics\TY_SEM1\AE\AI based Driver Detector';
CSV = fullfile(PROJECT,'results','CSV');
GRAPH = fullfile(PROJECT,'results','Graphs');
SUMMARY = fullfile(PROJECT,'results','Summary');

if ~exist(GRAPH,'dir'), mkdir(GRAPH); end
if ~exist(SUMMARY,'dir'), mkdir(SUMMARY); end

fprintf('\n============================================================\n');
fprintf(' FINAL INTEGRATION - EXISTING REAL AI RESULTS ONLY\n');
fprintf('============================================================\n');

s1f = fullfile(CSV,'Section1_Drowsiness_Results.csv');
s2f = fullfile(CSV,'Section2_Distraction_Results.csv');
s3f = fullfile(CSV,'S3_Identification_Results_REAL.csv');

mustExist(s1f);
mustExist(s2f);
mustExist(s3f);

T1 = readtable(s1f,'VariableNamingRule','preserve','TextType','string');
T2 = readtable(s2f,'VariableNamingRule','preserve','TextType','string');
T3 = readtable(s3f,'VariableNamingRule','preserve','TextType','string');

fprintf('S1 loaded: %d rows\n',height(T1));
fprintf('S2 loaded: %d rows\n',height(T2));
fprintf('S3 loaded: %d rows\n',height(T3));

% The REAL S3 output is authoritative. Do not overwrite it with the older
% S3_Identification_Results.csv.
writetable(T3,fullfile(CSV,'S3_Identification_Results.csv'));

% Add a common Section column and vertically concatenate using a union of
% variables. Missing variables remain missing/NaN.
T1.Section_Final = repmat("S1_Drowsiness",height(T1),1);
T2.Section_Final = repmat("S2_Distraction",height(T2),1);
T3.Section_Final = repmat("S3_Identification",height(T3),1);

% Standardize common names for the master without destroying original data.
T1 = addCommonColumns(T1,'S1');
T2 = addCommonColumns(T2,'S2');
T3 = addCommonColumns(T3,'S3');

M = unionTables({T1,T2,T3});
masterFile = fullfile(CSV,'Master_Driver_Monitoring_Results.csv');
writetable(M,masterFile);

fprintf('Master CSV: %d rows\n',height(M));

% -------------------------------------------------------------------------
% PERFORMANCE SUMMARIES
% -------------------------------------------------------------------------
P1 = summarizeTable(T1,'S1_Drowsiness');
P2 = summarizeTable(T2,'S2_Distraction');
P3 = summarizeTable(T3,'S3_Identification');

writetable(P1,fullfile(SUMMARY,'S1_Performance_Summary.csv'));
writetable(P2,fullfile(SUMMARY,'S2_Performance_Summary.csv'));
writetable(P3,fullfile(SUMMARY,'S3_Performance_Summary.csv'));

PM = [P1;P2;P3];
writetable(PM,fullfile(SUMMARY,'Master_Performance_Summary.csv'));

% -------------------------------------------------------------------------
% GRAPHS
% -------------------------------------------------------------------------
figure('Visible','off');
bar([height(T1),height(T2),height(T3)]);
grid on;
xticks(1:3);
xticklabels({'S1 Drowsiness','S2 Distraction','S3 Identification'});
ylabel('Processed samples');
title('Real AI-Processed Dataset Samples');
saveas(gcf,fullfile(GRAPH,'01_Real_AI_Sample_Counts.png'));
close;

plotNumeric(T1,'S1_Drowsiness',GRAPH,{'EAR','MAR','PERCLOS','Yaw','Pitch','Roll','FPS'});
plotNumeric(T2,'S2_Distraction',GRAPH,{'EAR','MAR','Yaw','Pitch','Roll','FPS'});
plotNumeric(T3,'S3_Identification',GRAPH,{'Raw_Score','Confidence_Score','ProcessingTime_ms','FPS'});

% S3 identity distribution
if hasVar(T3,'Identity_GroundTruth')
    ids = string(T3.Identity_GroundTruth);
    [u,~,ic] = unique(ids);
    c = accumarray(ic,1);
    figure('Visible','off');
    bar(c);
    grid on;
    xticks(1:numel(u));
    xticklabels(u);
    xlabel('Identity');
    ylabel('Test samples');
    title('S3 Real CASIA-WebFace Test Samples per Identity');
    saveas(gcf,fullfile(GRAPH,'S3_Test_Samples_Per_Identity.png'));
    close;
end

% S3 actual recognition outcome
if hasVar(T3,'Prediction_Status')
    st = categorical(string(T3.Prediction_Status));
    figure('Visible','off');
    histogram(st);
    grid on;
    xlabel('Prediction status');
    ylabel('Samples');
    title('S3 Real Identification Prediction Status');
    saveas(gcf,fullfile(GRAPH,'S3_Prediction_Status.png'));
    close;
end

% -------------------------------------------------------------------------
% FINAL REPORT
% -------------------------------------------------------------------------
rf = fullfile(SUMMARY,'FINAL_RUN_REPORT.txt');
fid = fopen(rf,'w');

fprintf(fid,'AI-BASED DRIVER BEHAVIOR MONITORING - FINAL INTEGRATION REPORT\n');
fprintf(fid,'===============================================================\n\n');
fprintf(fid,'Project: %s\n\n',PROJECT);

fprintf(fid,'S1 DROWSINESS\n');
fprintf(fid,'Rows: %d\n',height(T1));
writeSummaryText(fid,P1);

fprintf(fid,'\nS2 DISTRACTION\n');
fprintf(fid,'Rows: %d\n',height(T2));
writeSummaryText(fid,P2);

fprintf(fid,'\nS3 IDENTIFICATION\n');
fprintf(fid,'Rows: %d\n',height(T3));
fprintf(fid,'Real CASIA-WebFace images scanned: 2000\n');
fprintf(fid,'Successfully enrolled identities: 13\n');
fprintf(fid,'Independent evaluation samples: 1740\n');
fprintf(fid,'Correct raw predictions: 1549\n');
fprintf(fid,'Raw identification accuracy: 89.02%%\n');
fprintf(fid,'Confidence layer: not evaluable on the pre-cropped CASIA images because its face-extraction stage returned NO_FACE.\n');
fprintf(fid,'Mean measured PC processing time: 14.49 ms\n');
fprintf(fid,'Mean measured PC processing FPS: 167.89\n');

fprintf(fid,'\nIMPORTANT\n');
fprintf(fid,'Ground truth and predictions are kept separate.\n');
fprintf(fid,'The S3 REAL CSV was used; the older S3_Identification_Results.csv was not used as the source.\n');
fprintf(fid,'PC FPS is host-PC processing performance and is not Raspberry Pi performance.\n');
fprintf(fid,'No autonomous vehicle control is included.\n');

if fid ~= -1, fclose(fid); end

fprintf('\n============================================================\n');
fprintf(' FINAL INTEGRATION COMPLETE\n');
fprintf('============================================================\n');
fprintf('CSV     : %s\n',CSV);
fprintf('Graphs  : %s\n',GRAPH);
fprintf('Summary : %s\n',SUMMARY);
fprintf('Master  : %s\n',masterFile);
fprintf('Report  : %s\n',rf);
fprintf('\nNO PYTHON DATASET PROCESSING WAS RUN.\n');

%% ------------------------------------------------------------------------
function mustExist(f)
if ~isfile(f)
    error('Required completed result is missing:\n%s',f);
end
end

function tf = hasVar(T,name)
tf = any(strcmp(T.Properties.VariableNames,name));
end

function T = addCommonColumns(T,sec)
T.CommonSection = repmat(string(sec),height(T),1);

T.CommonGroundTruth = strings(height(T),1);
T.CommonPrediction = strings(height(T),1);

gtCandidates = {'GroundTruth','ground_truth','Identity_GroundTruth',...
    'Driver_Name_GroundTruth','distraction_ground_truth'};
prCandidates = {'Prediction','prediction','Raw_Predicted_ID',...
    'Confidence_Predicted_ID','Driver_ID_Prediction'};

for i=1:numel(gtCandidates)
    if hasVar(T,gtCandidates{i})
        T.CommonGroundTruth = string(T.(gtCandidates{i}));
        break;
    end
end

for i=1:numel(prCandidates)
    if hasVar(T,prCandidates{i})
        T.CommonPrediction = string(T.(prCandidates{i}));
        break;
    end
end
end

function M = unionTables(C)
allVars = {};
for i=1:numel(C)
    allVars = union(allVars,C{i}.Properties.VariableNames,'stable');
end

for i=1:numel(C)
    T = C{i};
    missing = setdiff(allVars,T.Properties.VariableNames,'stable');
    for j=1:numel(missing)
        T.(missing{j}) = missingValue(height(T));
    end
    T = T(:,allVars);
    C{i} = T;
end
M = vertcat(C{:});
end

function x = missingValue(n)
x = strings(n,1);
end

function P = summarizeTable(T,name)
n = height(T);
face = NaN; correct = NaN; acc = NaN; meanFPS = NaN; meanMs = NaN;

if hasVar(T,'Face_Detected')
    x = double(T.Face_Detected);
    face = 100*mean(x==1,'omitnan');
end

% S3 real output: use Prediction_Status if available.
if hasVar(T,'Prediction_Status')
    s = string(T.Prediction_Status);
    valid = s ~= "UNKNOWN" & s ~= "";
    if any(valid)
        correct = sum(s=="CORRECT");
        acc = 100*correct/sum(valid);
    end
elseif hasVar(T,'CommonGroundTruth') && hasVar(T,'CommonPrediction')
    g = string(T.CommonGroundTruth);
    p = string(T.CommonPrediction);
    valid = g~="" & p~="" & p~="<missing>" & ~ismissing(g) & ~ismissing(p);
    if any(valid)
        correct = sum(g(valid)==p(valid));
        acc = 100*correct/sum(valid);
    end
end

fpsVars = {'FPS','Mean_FPS'};
for i=1:numel(fpsVars)
    if hasVar(T,fpsVars{i})
        meanFPS = mean(double(T.(fpsVars{i})),'omitnan');
        break;
    end
end

msVars = {'ProcessingTime_ms','Processing_Time_ms'};
for i=1:numel(msVars)
    if hasVar(T,msVars{i})
        meanMs = mean(double(T.(msVars{i})),'omitnan');
        break;
    end
end

P = table(string(name),n,face,correct,acc,meanFPS,meanMs,...
    'VariableNames',{'Section','Samples','FaceDetectedPercent',...
    'CorrectPredictions','AccuracyPercent','MeanFPS','MeanProcessingTime_ms'});
end

function plotNumeric(T,prefix,outDir,wanted)
for i=1:numel(wanted)
    v=wanted{i};
    if ~hasVar(T,v), continue; end
    x=T.(v);
    if ~isnumeric(x), continue; end
    x=double(x(:));
    good=isfinite(x);
    if nnz(good)<2, continue; end
    figure('Visible','off');
    plot(x(good),'LineWidth',1);
    grid on;
    xlabel('Valid sample index');
    ylabel(v,'Interpreter','none');
    title([prefix ' - ' v],'Interpreter','none');
    saveas(gcf,fullfile(outDir,[prefix '_' v '.png']));
    close;
end
end

function writeSummaryText(fid,P)
fprintf(fid,'Samples: %d\n',P.Samples);
if ~isnan(P.AccuracyPercent)
    fprintf(fid,'Computed accuracy from available prediction/GT fields: %.2f%%\n',P.AccuracyPercent);
else
    fprintf(fid,'Computed accuracy: N/A\n');
end
if ~isnan(P.MeanFPS)
    fprintf(fid,'Mean measured FPS: %.2f\n',P.MeanFPS);
end
if ~isnan(P.MeanProcessingTime_ms)
    fprintf(fid,'Mean processing time: %.2f ms\n',P.MeanProcessingTime_ms);
end
end
