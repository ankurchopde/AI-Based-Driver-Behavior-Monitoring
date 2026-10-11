%% S3 IDENTIFICATION - TEMPORARY DATASET PROCESSOR
% Use this instead of CASIA train.rec.
%
% Dataset:
% D:\Academics\TY_SEM1\AE\AI based Driver Detector\dataset\
% section3_identification\extracted\
%
% Expected structure:
% extracted\
%   0\
%      image files
%   1\
%      image files
%   ...
%   14\
%      image files
%
% The folder number (0...14) is treated as the identity ground truth.
% No images are fabricated or duplicated.
%
% Output:
% dataset\matlab_dataset_results\S3_Identification_Temp_Results.csv
% dataset\matlab_dataset_results\S3_Identification_Temp_Summary.txt
% dataset\matlab_dataset_results\S3_Identification_Class_Distribution.png
% dataset\matlab_dataset_results\S3_Identification_Samples_Per_ID.png

clear;
clc;
close all;

fprintf('\n=============================================\n');
fprintf(' S3 TEMPORARY DRIVER IDENTIFICATION PROCESSOR\n');
fprintf(' REAL EXTRACTED FACE DATASET\n');
fprintf('=============================================\n\n');

PROJECT = 'D:\Academics\TY_SEM1\AE\AI based Driver Detector';
S3ROOT = fullfile(PROJECT,'dataset','section3_identification','extracted');
OUT = fullfile(PROJECT,'PROJECT','Data','matlab_dataset_results');

if ~exist(OUT,'dir')
    mkdir(OUT);
end

fprintf('S3 dataset: %s\n',S3ROOT);

if ~exist(S3ROOT,'dir')
    error('S3 extracted dataset folder not found:\n%s',S3ROOT);
end

%% Find identity folders 0...14
folders = dir(S3ROOT);
folders = folders([folders.isdir]);
folders = folders(~ismember({folders.name},{'.','..'}));

validFolders = [];

for k = 1:numel(folders)
    n = str2double(folders(k).name);
    if isfinite(n) && n >= 0 && n <= 14 && floor(n)==n
        validFolders = [validFolders; folders(k)]; %#ok<AGROW>
    end
end

[~,order] = sort(str2double({validFolders.name}));
validFolders = validFolders(order);

fprintf('Identity folders found: %d\n',numel(validFolders));

if numel(validFolders) == 0
    error('No folders named 0 to 14 were found.');
end

%% Collect images
exts = {'.jpg','.jpeg','.png','.bmp','.webp'};
rows = {};
sampleCounter = 0;

for f = 1:numel(validFolders)

    identity = string(validFolders(f).name);
    folderPath = fullfile(validFolders(f).folder,validFolders(f).name);

    files = [];
    for e = 1:numel(exts)
        files = [files; dir(fullfile(folderPath,'**',['*' exts{e}]))]; %#ok<AGROW>
    end

    fprintf('[ID %s] Images found: %d\n',identity,numel(files));

    for i = 1:numel(files)

        sampleCounter = sampleCounter + 1;

        imagePath = fullfile(files(i).folder,files(i).name);

        % Verify that the image is actually readable.
        validImage = true;
        try
            img = imread(imagePath);
            if isempty(img)
                validImage = false;
            end
        catch
            validImage = false;
        end

        if ~validImage
            continue;
        end

        info = imfinfo(imagePath);

        rows(end+1,:) = { ...
            sampleCounter, ...
            identity, ...
            string(files(i).name), ...
            string(imagePath), ...
            size(img,1), ...
            size(img,2), ...
            string(info.Format), ...
            NaN, ...
            NaN}; %#ok<SAGROW>
    end
end

%% Create table
if isempty(rows)
    error('No readable images were found inside folders 0...14.');
end

T = cell2table(rows,'VariableNames',{ ...
    'SampleID',...
    'IdentityGroundTruth',...
    'FileName',...
    'ImagePath',...
    'Height',...
    'Width',...
    'Format',...
    'Prediction',...
    'ProcessingTime_ms'});

T.FPS = NaN(height(T),1);

fprintf('\n=============================================\n');
fprintf('S3 DATASET CHECK COMPLETE\n');
fprintf('=============================================\n');
fprintf('Readable genuine images: %d\n',height(T));
fprintf('Identities: %d\n',numel(unique(T.IdentityGroundTruth)));

%% Save CSV
csvFile = fullfile(OUT,'S3_Identification_Temp_Results.csv');
writetable(T,csvFile);

fprintf('\nCSV:\n%s\n',csvFile);

%% Class distribution
figure('Name','S3 Identity Distribution','NumberTitle','off');

histogram(categorical(T.IdentityGroundTruth));
grid on;
xlabel('Identity folder');
ylabel('Number of images');
title('S3 Driver Identification Dataset - Identity Distribution');

saveas(gcf,fullfile(OUT,'S3_Identification_Class_Distribution.png'));

%% Samples per identity
ids = unique(T.IdentityGroundTruth);
counts = zeros(numel(ids),1);

for k = 1:numel(ids)
    counts(k) = sum(T.IdentityGroundTruth == ids(k));
end

figure('Name','S3 Samples Per Identity','NumberTitle','off');

bar(categorical(ids),counts);
grid on;
xlabel('Identity');
ylabel('Number of genuine images');
title('S3 Genuine Images Per Driver Identity');

saveas(gcf,fullfile(OUT,'S3_Identification_Samples_Per_ID.png'));

%% Summary
summaryFile = fullfile(OUT,'S3_Identification_Temp_Summary.txt');
fid = fopen(summaryFile,'w');

fprintf(fid,'S3 DRIVER IDENTIFICATION DATASET SUMMARY\n');
fprintf(fid,'=============================================\n\n');
fprintf(fid,'Dataset root:\n%s\n\n',S3ROOT);
fprintf(fid,'Identity folders found: %d\n',numel(ids));
fprintf(fid,'Readable genuine images: %d\n\n',height(T));

fprintf(fid,'Images per identity:\n');
for k = 1:numel(ids)
    fprintf(fid,'Identity %s: %d images\n',ids(k),counts(k));
end

fprintf(fid,'\nGround truth source:\n');
fprintf(fid,'Folder name 0...14 is used as identity ground truth.\n');

fprintf(fid,'\nPrediction:\n');
fprintf(fid,'Prediction is intentionally NaN until the actual driver\n');
fprintf(fid,'identification algorithm is run.\n');

fprintf(fid,'\nNo images were fabricated or duplicated.\n');
fprintf(fid,'This processor only reads the existing extracted images.\n');

fclose(fid);

fprintf('\n=============================================\n');
fprintf('DONE - S3 READY FOR AI PROCESSING\n');
fprintf('=============================================\n');
fprintf('Total genuine images: %d\n',height(T));
fprintf('Output folder:\n%s\n',OUT);
fprintf('\nNext: use this CSV as the S3 identification input.\n');
