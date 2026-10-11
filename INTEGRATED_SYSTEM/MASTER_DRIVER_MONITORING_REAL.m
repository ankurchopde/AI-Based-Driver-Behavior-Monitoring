%% MASTER_DRIVER_MONITORING_REAL.m
% =========================================================================
% AI-BASED DRIVER BEHAVIOR MONITORING
% FINAL MATLAB MASTER RUNNER
%
% This single MATLAB file:
%   1) Finds the project root automatically
%   2) Runs the existing Python AI processing pipeline
%   3) Collects S1/S2/S3 CSV outputs
%   4) Creates final CSV files in results/CSV
%   5) Creates feature/performance graphs in results/Graphs
%   6) Creates summary/performance CSV files in results/Summary
%
% IMPORTANT:
% - MATLAB does NOT recreate the AI algorithms.
% - Python remains responsible for MediaPipe / HeadPose / SFace processing.
% - Ground truth is never copied from predictions.
% - Missing values remain NaN.
% - FPS is measured processing FPS, not Raspberry Pi FPS.
%
% Expected Python file:
%   PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py
%
% Run:
%   >> MASTER_DRIVER_MONITORING_REAL
% =========================================================================

clear; clc; close all;

fprintf('\n============================================================\n');
fprintf(' AI-BASED DRIVER BEHAVIOR MONITORING - FINAL PIPELINE\n');
fprintf('============================================================\n');

%% 1. Locate project root
projectRoot = pwd;

% If launched from a subfolder, walk upward until the Python processor is found.
for k = 1:6
    if isfile(fullfile(projectRoot,'PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py'))
        break;
    end
    parent = fileparts(projectRoot);
    if strcmp(parent,projectRoot)
        break;
    end
    projectRoot = parent;
end

pythonFile = fullfile(projectRoot,'PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py');

if ~isfile(pythonFile)
    error(['Cannot find PROJECT/Dataset_Pipeline/dataset_processing_final_REAL_FINAL.py.' newline ...
           'Place this MATLAB file in the project root or a subfolder of it.']);
end

fprintf('[1/6] Project root:\n%s\n', projectRoot);
fprintf('Python processor:\n%s\n\n', pythonFile);

%% 2. Create final result folders
resultsRoot = fullfile(projectRoot,'results');
csvDir      = fullfile(resultsRoot,'CSV');
graphDir    = fullfile(resultsRoot,'Graphs');
summaryDir  = fullfile(resultsRoot,'Summary');
rawDir      = fullfile(resultsRoot,'Raw_Python');

if ~exist(csvDir,'dir'),     mkdir(csvDir);     end
if ~exist(graphDir,'dir'),   mkdir(graphDir);   end
if ~exist(summaryDir,'dir'), mkdir(summaryDir); end
if ~exist(rawDir,'dir'),     mkdir(rawDir);     end

%% 3. Detect Python
fprintf('[2/6] Detecting Python...\n');

[status, pyExe] = system('where python');
if status ~= 0 || isempty(strtrim(pyExe))
    [status, pyExe] = system('where py');
end

if status ~= 0 || isempty(strtrim(pyExe))
    error('Python was not found in PATH. Add Python to PATH or run MATLAB from an environment where Python is available.');
end

% First line of "where python"
pyLines = regexp(strtrim(pyExe),'\r?\n','split');
pyExe = strtrim(pyLines{1});

fprintf('Using Python: %s\n\n',pyExe);

%% 4. Run the EXISTING Python AI pipeline
fprintf('[3/6] Running actual Python AI processing...\n');
fprintf('This stage performs the feature extraction and predictions.\n');
fprintf('Do not close MATLAB or the Python console.\n\n');

oldDir = pwd;
cd(projectRoot);

cmd = sprintf('"%s" "%s"', pyExe, pythonFile);

fprintf('COMMAND:\n%s\n\n',cmd);
tic;
[pyStatus, pyOutput] = system(cmd);
pythonElapsed = toc;

cd(oldDir);

% Save complete Python console output
logFile = fullfile(rawDir,'Python_Execution_Log.txt');
fid = fopen(logFile,'w');
if fid ~= -1
    fprintf(fid,'%s\n',pyOutput);
    fprintf(fid,'\nTotal MATLAB-side Python execution time: %.3f s\n',pythonElapsed);
    fclose(fid);
end

fprintf('\n------------------------------------------------------------\n');
fprintf('Python execution finished in %.2f seconds.\n',pythonElapsed);
fprintf('------------------------------------------------------------\n');
fprintf('%s\n',pyOutput);

if pyStatus ~= 0
    error(['Python processing failed with exit code %d.' newline ...
           'Read: %s'], pyStatus, logFile);
end

%% 5. Locate Python CSV outputs
fprintf('\n[4/6] Collecting Python outputs...\n');

% The current project Python processor writes these names.
candidateS1 = {
    fullfile(projectRoot,'Section1_Drowsiness_Results.csv')
    fullfile(projectRoot,'results','final','Section1_Drowsiness_Results.csv')
    fullfile(resultsRoot,'Section1_Drowsiness_Results.csv')
};

candidateS2 = {
    fullfile(projectRoot,'Section2_Distraction_Results.csv')
    fullfile(projectRoot,'results','final','Section2_Distraction_Results.csv')
    fullfile(resultsRoot,'Section2_Distraction_Results.csv')
};

candidateS3 = {
    fullfile(projectRoot,'results/identification/Section3_Identification_Results.csv')
    fullfile(projectRoot,'results','final','results/identification/Section3_Identification_Results.csv')
    fullfile(resultsRoot,'results/identification/Section3_Identification_Results.csv')
};

s1File = firstExisting(candidateS1);
s2File = firstExisting(candidateS2);
s3File = firstExisting(candidateS3);

fprintf('S1: %s\n',showPath(s1File));
fprintf('S2: %s\n',showPath(s2File));
fprintf('S3: %s\n',showPath(s3File));

if isempty(s1File) && isempty(s2File) && isempty(s3File)
    error(['Python completed without producing any expected CSV files.' newline ...
           'Check Python_Execution_Log.txt and verify that the processor is using the real datasets.']);
end

%% 6. Read, preserve column names, and save final CSVs
fprintf('\n[5/6] Creating final CSVs and graphs...\n');

T1 = readSafe(s1File);
T2 = readSafe(s2File);
T3 = readSafe(s3File);

% Save exact Python results into the final results structure.
if ~isempty(T1)
    writetable(T1,fullfile(csvDir,'Section1_Drowsiness_Results.csv'));
    fprintf('Saved Section1_Drowsiness_Results.csv: %d rows\n',height(T1));
end

if ~isempty(T2)
    writetable(T2,fullfile(csvDir,'Section2_Distraction_Results.csv'));
    fprintf('Saved Section2_Distraction_Results.csv: %d rows\n',height(T2));
end

if ~isempty(T3)
    writetable(T3,fullfile(csvDir,'S3_Identification_Results.csv'));
    fprintf('Saved S3_Identification_Results.csv: %d rows\n',height(T3));
end

%% 7. Generate feature graphs
if ~isempty(T1)
    makeFeatureGraphs(T1,'S1_Drowsiness',graphDir);
end

if ~isempty(T2)
    makeFeatureGraphs(T2,'S2_Distraction',graphDir);
end

if ~isempty(T3)
    makeFeatureGraphs(T3,'S3_Identification',graphDir);
end

%% 8. Generate performance summaries
S1 = makePerformanceSummary(T1,'S1_Drowsiness');
S2 = makePerformanceSummary(T2,'S2_Distraction');
S3 = makePerformanceSummary(T3,'S3_Identification');

if ~isempty(S1), writetable(S1,fullfile(summaryDir,'S1_Performance_Summary.csv')); end
if ~isempty(S2), writetable(S2,fullfile(summaryDir,'S2_Performance_Summary.csv')); end
if ~isempty(S3), writetable(S3,fullfile(summaryDir,'S3_Performance_Summary.csv')); end

%% 9. Master combined CSV
% Tables are allowed to have different columns. Add a Section column and
% concatenate using an outer union of variables.
master = outerUnion(T1,T2,T3);

if ~isempty(master)
    masterFile = fullfile(csvDir,'Master_Driver_Monitoring_Results.csv');
    writetable(master,masterFile);
    fprintf('Saved Master_Driver_Monitoring_Results.csv: %d rows\n',height(master));
end

%% 10. Master summary
masterSummary = table( ...
    ["S1 Drowsiness";"S2 Distraction";"S3 Identification"], ...
    [height(T1);height(T2);height(T3)], ...
    [safeSum(T1,'Face_Detected');safeSum(T2,'Face_Detected');safeSum(T3,'Face_Detected')], ...
    'VariableNames',{'Section','Samples','Face_Detected'});

writetable(masterSummary,fullfile(summaryDir,'Master_Summary.csv'));

%% 11. Final report
reportFile = fullfile(summaryDir,'FINAL_RUN_REPORT.txt');
fid = fopen(reportFile,'w');

if fid ~= -1
    fprintf(fid,'AI-BASED DRIVER BEHAVIOR MONITORING - FINAL RUN REPORT\n');
    fprintf(fid,'=========================================================\n\n');
    fprintf(fid,'Project root: %s\n',projectRoot);
    fprintf(fid,'Python processor: %s\n',pythonFile);
    fprintf(fid,'Python execution time: %.3f s\n\n',pythonElapsed);

    fprintf(fid,'SECTION 1 - DROWSINESS\n');
    fprintf(fid,'Rows processed: %d\n',height(T1));
    fprintf(fid,'\nSECTION 2 - DISTRACTION\n');
    fprintf(fid,'Rows processed: %d\n',height(T2));
    fprintf(fid,'\nSECTION 3 - IDENTIFICATION\n');
    fprintf(fid,'Rows processed: %d\n',height(T3));

    fprintf(fid,'\nOUTPUTS\n');
    fprintf(fid,'CSV directory: %s\n',csvDir);
    fprintf(fid,'Graphs directory: %s\n',graphDir);
    fprintf(fid,'Summary directory: %s\n',summaryDir);
    fprintf(fid,'Python log: %s\n',logFile);

    fprintf(fid,'\nIMPORTANT\n');
    fprintf(fid,'Ground truth and predictions are kept separate.\n');
    fprintf(fid,'NaN indicates unavailable/non-applicable measurements.\n');
    fprintf(fid,'Measured FPS is host-PC processing FPS and is not Raspberry Pi FPS.\n');

    fclose(fid);
end

%% 12. Finish
fprintf('\n============================================================\n');
fprintf(' PIPELINE COMPLETE\n');
fprintf('============================================================\n');
fprintf('CSV      : %s\n',csvDir);
fprintf('Graphs   : %s\n',graphDir);
fprintf('Summary  : %s\n',summaryDir);
fprintf('Run log  : %s\n',logFile);
fprintf('\n');

%% ========================================================================
% LOCAL FUNCTIONS
% ========================================================================

function p = firstExisting(list)
p = '';
for i = 1:numel(list)
    if isfile(list{i})
        p = list{i};
        return;
    end
end
end

function s = showPath(p)
if isempty(p)
    s = '[NOT FOUND]';
else
    s = p;
end
end

function T = readSafe(file)
if isempty(file) || ~isfile(file)
    T = table();
    return;
end
T = readtable(file,'VariableNamingRule','preserve');
end

function n = safeSum(T,var)
n = 0;
if isempty(T), return; end
if any(strcmp(T.Properties.VariableNames,var))
    x = T.(var);
    if isnumeric(x)
        n = sum(x==1,'omitnan');
    end
end
end

function makeFeatureGraphs(T,prefix,outDir)
if isempty(T), return; end

vars = T.Properties.VariableNames;

% Numeric feature plots
for i = 1:numel(vars)
    v = vars{i};
    x = T.(v);

    if ~isnumeric(x) || isempty(x)
        continue;
    end

    % Skip pure identifiers / frame counters / duplicate metrics where a
    % histogram is not informative.
    if any(strcmpi(v,{'Frame_Number','Frame','Sample','Sample_Index'}))
        continue;
    end

    x = double(x(:));
    good = isfinite(x);

    if nnz(good) < 2
        continue;
    end

    fig = figure('Visible','off','Color','w');
    plot(x(good),'LineWidth',1);
    grid on;
    xlabel('Valid Sample Index');
    ylabel(v,'Interpreter','none');
    title(sprintf('%s - %s',prefix,v),'Interpreter','none');

    safeName = regexprep(v,'[^A-Za-z0-9_]','_');
    saveas(fig,fullfile(outDir,[prefix '_' safeName '_Trend.png']));
    close(fig);

    % Distribution
    fig = figure('Visible','off','Color','w');
    histogram(x(good));
    grid on;
    xlabel(v,'Interpreter','none');
    ylabel('Count');
    title(sprintf('%s - %s Distribution',prefix,v),'Interpreter','none');

    saveas(fig,fullfile(outDir,[prefix '_' safeName '_Distribution.png']));
    close(fig);
end

% Ground-truth vs prediction where both actually exist
pairs = {
    'Drowsiness_GroundTruth','Drowsiness_Prediction','Drowsiness'
    'Distraction_GroundTruth','Distraction_Prediction','Distraction'
    'Driver_ID_GroundTruth','Driver_ID_Prediction','Identification'
};

for k = 1:size(pairs,1)
    gtName = pairs{k,1};
    prName = pairs{k,2};
    label  = pairs{k,3};

    if ~any(strcmp(vars,gtName)) || ~any(strcmp(vars,prName))
        continue;
    end

    gt = T.(gtName);
    pr = T.(prName);

    if ~isnumeric(gt) || ~isnumeric(pr)
        continue;
    end

    valid = isfinite(gt) & isfinite(pr);

    if nnz(valid)==0
        continue;
    end

    fig = figure('Visible','off','Color','w');

    confusionchart(gt(valid),pr(valid));
    title(sprintf('%s - Ground Truth vs Prediction',label));

    saveas(fig,fullfile(outDir,[prefix '_' label '_ConfusionMatrix.png']));
    close(fig);
end

% CPU / RAM / FPS overview if present
perfVars = {'FPS','Processing_Time_ms','CPU_Usage_Percent','RAM_Usage_MB'};

for i = 1:numel(perfVars)
    v = perfVars{i};
    if any(strcmp(vars,v))
        x = T.(v);
        if isnumeric(x) && any(isfinite(x))
            fig = figure('Visible','off','Color','w');
            plot(double(x),'LineWidth',1);
            grid on;
            xlabel('Sample');
            ylabel(v,'Interpreter','none');
            title(sprintf('%s - %s',prefix,v),'Interpreter','none');
            safeName = regexprep(v,'[^A-Za-z0-9_]','_');
            saveas(fig,fullfile(outDir,[prefix '_' safeName '.png']));
            close(fig);
        end
    end
end
end

function S = makePerformanceSummary(T,sectionName)
if isempty(T)
    S = table();
    return;
end

rows = {};

% Sample count
rows(end+1,:) = {'Samples',height(T)};

% Face detection
if any(strcmp(T.Properties.VariableNames,'Face_Detected'))
    x = T.Face_Detected;
    rows(end+1,:) = {'Face_Detection_Rate_percent',100*mean(x==1,'omitnan')};
end

% Processing metrics
if any(strcmp(T.Properties.VariableNames,'FPS'))
    x = T.FPS;
    rows(end+1,:) = {'Mean_FPS',mean(x,'omitnan')};
    rows(end+1,:) = {'Median_FPS',median(x,'omitnan')};
end

if any(strcmp(T.Properties.VariableNames,'Processing_Time_ms'))
    x = T.Processing_Time_ms;
    rows(end+1,:) = {'Mean_Processing_Time_ms',mean(x,'omitnan')};
    rows(end+1,:) = {'Median_Processing_Time_ms',median(x,'omitnan')};
end

if any(strcmp(T.Properties.VariableNames,'CPU_Usage_Percent'))
    rows(end+1,:) = {'Mean_CPU_percent',mean(T.CPU_Usage_Percent,'omitnan')};
end

if any(strcmp(T.Properties.VariableNames,'RAM_Usage_MB'))
    rows(end+1,:) = {'Mean_RAM_MB',mean(T.RAM_Usage_MB,'omitnan')};
end

% Binary classification accuracy only when actual GT exists.
pairs = {
    'Drowsiness_GroundTruth','Drowsiness_Prediction','Drowsiness_Accuracy_percent'
    'Distraction_GroundTruth','Distraction_Prediction','Distraction_Accuracy_percent'
};

for k = 1:size(pairs,1)
    gtName = pairs{k,1};
    prName = pairs{k,2};
    metric = pairs{k,3};

    if any(strcmp(T.Properties.VariableNames,gtName)) && ...
       any(strcmp(T.Properties.VariableNames,prName))

        gt = T.(gtName);
        pr = T.(prName);
        valid = isfinite(gt) & isfinite(pr);

        if nnz(valid)>0
            rows(end+1,:) = {metric,100*mean(gt(valid)==pr(valid))};
        end
    end
end

% Identification accuracy
if any(strcmp(T.Properties.VariableNames,'Driver_ID_GroundTruth')) && ...
   any(strcmp(T.Properties.VariableNames,'Driver_ID_Prediction'))

    gt = T.Driver_ID_GroundTruth;
    pr = T.Driver_ID_Prediction;

    if isnumeric(gt) && isnumeric(pr)
        valid = isfinite(gt) & isfinite(pr);
        if nnz(valid)>0
            rows(end+1,:) = {'Identification_Accuracy_percent',100*mean(gt(valid)==pr(valid))};
        end
    end
end

% Alert rates
alertVars = {
    'Drowsiness_Alert','Drowsiness_Alert_Rate_percent'
    'Distraction_Alert','Distraction_Alert_Rate_percent'
};

for k = 1:size(alertVars,1)
    v = alertVars{k,1};
    metric = alertVars{k,2};
    if any(strcmp(T.Properties.VariableNames,v))
        x = T.(v);
        if isnumeric(x) && any(isfinite(x))
            rows(end+1,:) = {metric,100*mean(x==1,'omitnan')};
        end
    end
end

S = cell2table(rows,'VariableNames',{'Metric','Value'});
S.Section = repmat(string(sectionName),height(S),1);
S = movevars(S,'Section','Before','Metric');
end

function M = outerUnion(T1,T2,T3)
Ts = {T1,T2,T3};
M = table();

for i = 1:numel(Ts)
    T = Ts{i};
    if isempty(T), continue; end

    T.Section = repmat(string(sprintf('S%d',i)),height(T),1);

    if isempty(M)
        M = T;
        continue;
    end

    allVars = unique([M.Properties.VariableNames T.Properties.VariableNames],...
                     'stable');

    M = addMissingVars(M,allVars);
    T = addMissingVars(T,allVars);

    M = M(:,allVars);
    T = T(:,allVars);

    % Convert incompatible variables to strings when necessary.
    for j = 1:numel(allVars)
        a = M.(allVars{j});
        b = T.(allVars{j});

        if ~strcmp(class(a),class(b))
            try
                M.(allVars{j}) = string(a);
                T.(allVars{j}) = string(b);
            catch
                M.(allVars{j}) = string(a);
                T.(allVars{j}) = string(b);
            end
        end
    end

    M = [M;T]; %#ok<AGROW>
end
end

function T = addMissingVars(T,allVars)
for i = 1:numel(allVars)
    v = allVars{i};
    if ~any(strcmp(T.Properties.VariableNames,v))
        T.(v) = repmat(missing,height(T),1);
    end
end
end
