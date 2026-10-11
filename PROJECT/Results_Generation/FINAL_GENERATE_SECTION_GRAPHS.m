function FINAL_GENERATE_SECTION_GRAPHS()

clc;
close all;

fprintf('\n============================================================\n');
fprintf(' FINAL GRAPH GENERATION - EXISTING RESULTS ONLY\n');
fprintf('============================================================\n');

root = pwd;

csvDir   = fullfile(root,'results','CSV');
graphDir = fullfile(root,'results','Graphs');

if ~exist(graphDir,'dir')
    mkdir(graphDir);
end

%% ============================================================
% LOAD EXISTING RESULTS
% ============================================================

S1 = readtable(fullfile(csvDir,'Section1_Drowsiness_Results.csv'), ...
    'VariableNamingRule','preserve');

S2 = readtable(fullfile(csvDir,'Section2_Distraction_Results.csv'), ...
    'VariableNamingRule','preserve');

S3 = readtable(fullfile(csvDir,'S3_Identification_Results_REAL.csv'), ...
    'VariableNamingRule','preserve');

fprintf('S1: %d rows\n',height(S1));
fprintf('S2: %d rows\n',height(S2));
fprintf('S3: %d rows\n',height(S3));

%% ============================================================
% S1 - DROWSINESS
% ONE GRAPH ONLY
% ============================================================

fprintf('\nGenerating S1 graph...\n');

gt1 = findColumn(S1, {
    'GroundTruth'
    'Ground_Truth'
    'Drowsiness_GroundTruth'
    'Drowsiness_GT'
    'GT'
    'Label'
    'Ground Truth'
});

pred1 = findColumn(S1, {
    'Prediction'
    'Predicted'
    'Predicted_Label'
    'Drowsiness_Prediction'
    'Drowsiness_Predicted'
});

if ~isempty(gt1) && ~isempty(pred1)

    gt = string(S1.(gt1));
    pr = string(S1.(pred1));

    valid = gt ~= "" & pr ~= "" & ...
            ~ismissing(gt) & ~ismissing(pr);

    gt = gt(valid);
    pr = pr(valid);

    classes = unique([gt;pr],'stable');

    C = zeros(numel(classes));

    for i = 1:numel(gt)
        a = find(classes == gt(i),1);
        b = find(classes == pr(i),1);

        if ~isempty(a) && ~isempty(b)
            C(a,b) = C(a,b) + 1;
        end
    end

    figure('Name','S1 Drowsiness Performance','Color','w');

    imagesc(C);
    axis tight;

    xlabel('Predicted Class');
    ylabel('Ground Truth Class');
    title('S1 - Drowsiness Detection: Ground Truth vs Prediction');

    xticks(1:numel(classes));
    yticks(1:numel(classes));

    xticklabels(classes);
    yticklabels(classes);

    colorbar;

    for r = 1:size(C,1)
        for c = 1:size(C,2)
            text(c,r,num2str(C(r,c)), ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold');
        end
    end

    saveas(gcf,fullfile(graphDir,'S1_Drowsiness_Performance.png'));
    close;

else
    warning('S1 GT/prediction columns could not be detected.');
end


%% ============================================================
% S2 - DISTRACTION
% ONE GRAPH ONLY
% ============================================================

fprintf('Generating S2 graph...\n');

gt2 = findColumn(S2, {
    'GroundTruth'
    'Ground_Truth'
    'Distraction_GroundTruth'
    'Distraction_GT'
    'GT'
    'Label'
    'Ground Truth'
});

pred2 = findColumn(S2, {
    'Prediction'
    'Predicted'
    'Predicted_Label'
    'Distraction_Prediction'
    'Distraction_Predicted'
});

if ~isempty(gt2) && ~isempty(pred2)

    gt = string(S2.(gt2));
    pr = string(S2.(pred2));

    valid = gt ~= "" & pr ~= "" & ...
            ~ismissing(gt) & ~ismissing(pr);

    gt = gt(valid);
    pr = pr(valid);

    classes = unique([gt;pr],'stable');

    C = zeros(numel(classes));

    for i = 1:numel(gt)

        a = find(classes == gt(i),1);
        b = find(classes == pr(i),1);

        if ~isempty(a) && ~isempty(b)
            C(a,b) = C(a,b) + 1;
        end
    end

    figure('Name','S2 Distraction Performance','Color','w');

    imagesc(C);
    axis tight;

    xlabel('Predicted Class');
    ylabel('Ground Truth Class');
    title('S2 - Driver Distraction: Ground Truth vs Prediction');

    xticks(1:numel(classes));
    yticks(1:numel(classes));

    xticklabels(classes);
    yticklabels(classes);

    colorbar;

    for r = 1:size(C,1)
        for c = 1:size(C,2)
            text(c,r,num2str(C(r,c)), ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold');
        end
    end

    saveas(gcf,fullfile(graphDir,'S2_Distraction_Performance.png'));
    close;

else
    warning('S2 GT/prediction columns could not be detected.');
end


%% ============================================================
% S3 - DRIVER IDENTIFICATION
% ONE GRAPH ONLY
% ============================================================

fprintf('Generating S3 graph...\n');

gt3 = findColumn(S3, {
    'Driver_ID_GroundTruth'
    'Identity_GroundTruth'
    'GroundTruth'
    'Ground_Truth'
    'GT'
});

pred3 = findColumn(S3, {
    'Raw_Predicted_ID'
    'Predicted_ID'
    'Prediction'
    'Predicted'
});

if ~isempty(gt3) && ~isempty(pred3)

    gt = string(S3.(gt3));
    pr = string(S3.(pred3));

    valid = gt ~= "" & pr ~= "" & ...
            ~ismissing(gt) & ~ismissing(pr);

    gt = gt(valid);
    pr = pr(valid);

    classes = unique([gt;pr],'stable');

    C = zeros(numel(classes));

    for i = 1:numel(gt)

        a = find(classes == gt(i),1);
        b = find(classes == pr(i),1);

        if ~isempty(a) && ~isempty(b)
            C(a,b) = C(a,b) + 1;
        end
    end

    figure('Name','S3 Driver Identification','Color','w');

    imagesc(C);
    axis tight;

    xlabel('Predicted Driver ID');
    ylabel('Ground Truth Driver ID');
    title('S3 - Driver Identification: Ground Truth vs Prediction');

    xticks(1:numel(classes));
    yticks(1:numel(classes));

    xticklabels(classes);
    yticklabels(classes);

    colorbar;

    for r = 1:size(C,1)
        for c = 1:size(C,2)
            text(c,r,num2str(C(r,c)), ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold');
        end
    end

    saveas(gcf,fullfile(graphDir,'S3_Driver_Identification_Performance.png'));
    close;

else
    warning('S3 GT/prediction columns could not be detected.');
end


%% ============================================================
% DONE
% ============================================================

fprintf('\n============================================================\n');
fprintf(' GRAPH GENERATION COMPLETE\n');
fprintf('============================================================\n');

fprintf('Graphs folder:\n%s\n',graphDir);

fprintf('\nExactly one graph generated for each section.\n');
fprintf('No dataset processing or AI inference was performed.\n');

end


%% ============================================================
% COLUMN DETECTOR
% ============================================================

function col = findColumn(T,candidates)

col = '';

names = T.Properties.VariableNames;

for i = 1:numel(candidates)

    target = string(candidates{i});

    for j = 1:numel(names)

        if strcmpi(string(names{j}),target)
            col = names{j};
            return;
        end
    end
end

% Partial match fallback
for i = 1:numel(candidates)

    target = lower(string(candidates{i}));

    for j = 1:numel(names)

        current = lower(string(names{j}));

        if contains(current,target)
            col = names{j};
            return;
        end
    end
end

end