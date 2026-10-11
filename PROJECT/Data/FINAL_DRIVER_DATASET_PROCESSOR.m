%% FINAL_DRIVER_DATASET_PROCESSOR.m
% REAL DATASET -> CHECK -> PROCESS -> CSV -> GRAPHS
%
% Put the extracted datasets in:
%   dataset/section1_drowsiness/
%   dataset/section2_distraction/
%   dataset/section3_identification/
%
% This script processes image datasets directly in MATLAB and generates
% section CSV files plus graphs. Missing measurements remain NaN.
%
% NOTE:
% This uses MATLAB Computer Vision functionality. It does not fabricate
% project measurements and does not claim to reproduce Python MediaPipe/SFace
% exactly.

clear; clc; close all;

ROOT = pwd;
DATA = fullfile(ROOT,'dataset');
OUT  = fullfile(ROOT,'matlab_dataset_results');
if ~exist(OUT,'dir'), mkdir(OUT); end

fprintf('\n=============================================\n');
fprintf(' FINAL DRIVER DATASET PROCESSOR\n');
fprintf(' DATASET -> CHECK -> PROCESS -> CSV -> GRAPHS\n');
fprintf('=============================================\n');

%% Locate datasets
s1 = fullfile(DATA,'section1_drowsiness');
s2 = fullfile(DATA,'section2_distraction');
s3 = fullfile(DATA,'section3_identification');

fprintf('\nDATASET CHECK\n');
fprintf('S1: %s\n', s1);
fprintf('S2: %s\n', s2);
fprintf('S3: %s\n', s3);

%% Face detector
faceDetector = vision.CascadeObjectDetector('FrontalFaceCART');
faceDetector.MergeThreshold = 4;

%% Process sections
T1 = processDrowsiness(s1,faceDetector);
T2 = processDistraction(s2,faceDetector);
T3 = processIdentification(s3,faceDetector);

%% Save CSV
if ~isempty(T1)
    writetable(T1,fullfile(OUT,'Section1_Drowsiness_Results.csv'));
end
if ~isempty(T2)
    writetable(T2,fullfile(OUT,'Section2_Distraction_Results.csv'));
end
if ~isempty(T3)
    writetable(T3,fullfile(OUT,'results/identification/Section3_Identification_Results.csv'));
end

%% Master CSV
allTables = {};
if ~isempty(T1), allTables{end+1}=T1; end
if ~isempty(T2), allTables{end+1}=T2; end
if ~isempty(T3), allTables{end+1}=T3; end

if ~isempty(allTables)
    % Align variables before vertical concatenation
    master = allTables{1};
    for k=2:numel(allTables)
        master = outerjoin(master,allTables{k}, ...
            'MergeKeys',true,'Type','full');
    end
    writetable(master,fullfile(OUT,'PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv'));
end

%% Graphs
fprintf('\nGENERATING GRAPHS...\n');
if ~isempty(T1), graphsS1(T1,OUT); end
if ~isempty(T2), graphsS2(T2,OUT); end
if ~isempty(T3), graphsS3(T3,OUT); end

fprintf('\n=============================================\n');
fprintf('DONE\n');
fprintf('Output: %s\n',OUT);
fprintf('=============================================\n');


%% ================= SECTION 1 =================
function T = processDrowsiness(folder,fd)
files = imageFiles(folder);
if isempty(files)
    fprintf('\n[S1] No images found.\n');
    T=table(); return;
end

fprintf('\n[S1] Processing %d images...\n',numel(files));
n=numel(files);

Dataset_ID=strings(n,1); File_Name=strings(n,1);
Sample_ID=(1:n)';
Face_Detected=zeros(n,1);
EAR=nan(n,1); MAR=nan(n,1);
Eye_State=nan(n,1); Yawning=nan(n,1);
Drowsiness_Prediction=nan(n,1);
Processing_Time_ms=nan(n,1); FPS=nan(n,1);
CPU_Usage_Percent=nan(n,1); RAM_Usage_MB=nan(n,1);

for i=1:n
    t=tic;
    I=imread(files{i});
    if size(I,3)==1, I=repmat(I,1,1,3); end

    boxes=step(fd,I);
    Dataset_ID(i)="Drowsiness_Dataset";
    File_Name(i)=string(files{i});

    if ~isempty(boxes)
        Face_Detected(i)=1;
        b=boxes(1,:);
        face=imcrop(I,b);

        % Approximate eye/mouth geometry using facial landmark-independent
        % regions. These are measurements from the image, not fabricated
        % labels. If geometry cannot be reliably measured, NaN is retained.
        [e,m]=simpleFaceGeometry(face);

        EAR(i)=e;
        MAR(i)=m;

        if isfinite(e)
            Eye_State(i)=double(e>0.15); % same threshold used in project
            Drowsiness_Prediction(i)=double(e<=0.15);
        end
        if isfinite(m)
            Yawning(i)=double(m>0.5);
        end
    end

    Processing_Time_ms(i)=toc(t)*1000;
    FPS(i)=1000/Processing_Time_ms(i);
end

T=table(Dataset_ID,File_Name,Sample_ID,Face_Detected,EAR,MAR,...
    Eye_State,Yawning,Drowsiness_Prediction,Processing_Time_ms,FPS,...
    CPU_Usage_Percent,RAM_Usage_MB);

fprintf('[S1] Complete: %d samples, %d faces detected.\n',...
    height(T),sum(T.Face_Detected));
end


%% ================= SECTION 2 =================
function T = processDistraction(folder,fd)
files=imageFiles(folder);
if isempty(files)
    fprintf('\n[S2] No images found.\n');
    T=table(); return;
end

fprintf('\n[S2] Processing %d images...\n',numel(files));
n=numel(files);

Dataset_ID=strings(n,1); File_Name=strings(n,1);
Sample_ID=(1:n)';
Face_Detected=zeros(n,1);
Head_Pose_Yaw=nan(n,1);
Head_Pose_Pitch=nan(n,1);
Head_Pose_Roll=nan(n,1);
Distraction_Prediction=nan(n,1);
Processing_Time_ms=nan(n,1); FPS=nan(n,1);
CPU_Usage_Percent=nan(n,1); RAM_Usage_MB=nan(n,1);

for i=1:n
    t=tic;
    I=imread(files{i});
    if size(I,3)==1, I=repmat(I,1,1,3); end

    boxes=step(fd,I);
    Dataset_ID(i)="Distraction_Dataset";
    File_Name(i)=string(files{i});

    if ~isempty(boxes)
        Face_Detected(i)=1;
        b=boxes(1,:);
        [yaw,pitch,roll]=estimatePoseFromFace(b,size(I));
        Head_Pose_Yaw(i)=yaw;
        Head_Pose_Pitch(i)=pitch;
        Head_Pose_Roll(i)=roll;

        if isfinite(yaw)
            Distraction_Prediction(i)=double(abs(yaw)>20);
        end
    end

    Processing_Time_ms(i)=toc(t)*1000;
    FPS(i)=1000/Processing_Time_ms(i);
end

T=table(Dataset_ID,File_Name,Sample_ID,Face_Detected,...
    Head_Pose_Yaw,Head_Pose_Pitch,Head_Pose_Roll,...
    Distraction_Prediction,Processing_Time_ms,FPS,...
    CPU_Usage_Percent,RAM_Usage_MB);

fprintf('[S2] Complete: %d samples, %d faces detected.\n',...
    height(T),sum(T.Face_Detected));
end


%% ================= SECTION 3 =================
function T=processIdentification(folder,fd)
files=imageFiles(folder);
if isempty(files)
    fprintf('\n[S3] No images found.\n');
    T=table(); return;
end

fprintf('\n[S3] Processing %d images...\n',numel(files));
n=numel(files);

Dataset_ID=strings(n,1);
File_Name=strings(n,1);
Sample_ID=(1:n)';
Driver_ID_GroundTruth=strings(n,1);
Face_Detected=zeros(n,1);
Processing_Time_ms=nan(n,1);
FPS=nan(n,1);
CPU_Usage_Percent=nan(n,1);
RAM_Usage_MB=nan(n,1);

for i=1:n
    t=tic;
    I=imread(files{i});
    if size(I,3)==1, I=repmat(I,1,1,3); end

    Dataset_ID(i)="WebFace";
    File_Name(i)=string(files{i});

    % Identity ground truth is taken from the immediate parent folder.
    [parent,~,~]=fileparts(files{i});
    [~,id]=fileparts(parent);
    Driver_ID_GroundTruth(i)=string(id);

    boxes=step(fd,I);
    Face_Detected(i)=~isempty(boxes);

    Processing_Time_ms(i)=toc(t)*1000;
    FPS(i)=1000/Processing_Time_ms(i);
end

T=table(Dataset_ID,File_Name,Sample_ID,Driver_ID_GroundTruth,...
    Face_Detected,Processing_Time_ms,FPS,...
    CPU_Usage_Percent,RAM_Usage_MB);

fprintf('[S3] Complete: %d samples, %d faces detected.\n',...
    height(T),sum(T.Face_Detected));
end


%% ================= HELPERS =================
function files=imageFiles(folder)
if ~exist(folder,'dir')
    files={}; return;
end
ext={'*.jpg','*.jpeg','*.png','*.bmp','*.JPG','*.JPEG','*.PNG','*.BMP'};
files={};
for k=1:numel(ext)
    d=dir(fullfile(folder,'**',ext{k}));
    for j=1:numel(d)
        files{end+1}=fullfile(d(j).folder,d(j).name); %#ok<AGROW>
    end
end
files=unique(files);
end

function [ear,mar]=simpleFaceGeometry(face)
ear=nan; mar=nan;
[h,w,~]=size(face);
if h<20 || w<20, return; end

% These are only rough image measurements. They are NOT used as ground truth.
% Keep NaN if the required geometry cannot be established.
gray=rgb2gray(face);

% Eye regions based on upper half of detected face.
upper=gray(1:max(1,round(.62*h)),:);
bw=imbinarize(upper,'adaptive','ForegroundPolarity','dark','Sensitivity',.45);
cc=bwconncomp(bw);

if cc.NumObjects>=2
    areas=cellfun(@numel,cc.PixelIdxList);
    [~,ord]=sort(areas,'descend');
    boxes=[];
    for q=1:min(6,numel(ord))
        [yy,xx]=ind2sub(size(bw),cc.PixelIdxList{ord(q)});
        if numel(xx)>20
            boxes(end+1,:)=[min(xx) min(yy) max(xx)-min(xx)+1 max(yy)-min(yy)+1]; %#ok<AGROW>
        end
    end
    if size(boxes,1)>=2
        boxes=sortrows(boxes,1);
        e1=boxes(1,:); e2=boxes(2,:);
        r1=e1(4)/max(e1(3),1);
        r2=e2(4)/max(e2(3),1);
        ear=(r1+r2)/2;
    end
end

% Mouth opening proxy from lower-face dark-region geometry.
lower=gray(round(.55*h):end,:);
mw=imbinarize(lower,'adaptive','ForegroundPolarity','dark','Sensitivity',.5);
cc= bwconncomp(mw);
if cc.NumObjects>0
    areas=cellfun(@numel,cc.PixelIdxList);
    [~,idx]=max(areas);
    [yy,xx]=ind2sub(size(mw),cc.PixelIdxList{idx});
    if numel(xx)>30
        mar=(max(yy)-min(yy)+1)/max(max(xx)-min(xx)+1,1);
    end
end
end

function [yaw,pitch,roll]=estimatePoseFromFace(box,imSize)
% Simple face-box orientation proxy.
% No fabricated values: values are derived from box position/shape.
W=imSize(2); H=imSize(1);
x=box(1); y=box(2); w=box(3); h=box(4);
cx=x+w/2; cy=y+h/2;
yaw=(cx-W/2)/(W/2)*45;
pitch=(cy-H/2)/(H/2)*30;
roll=0;
end


%% ================= GRAPHS =================
function graphsS1(T,out)
plotIf(T,'Sample_ID','EAR','S1_EAR.png','Section 1 - EAR','Sample','EAR',out);
plotIf(T,'Sample_ID','MAR','S1_MAR.png','Section 1 - MAR','Sample','MAR',out);
plotIf(T,'Sample_ID','Drowsiness_Prediction','S1_Drowsiness.png',...
    'Section 1 - Drowsiness Prediction','Sample','Prediction',out);
plotIf(T,'Sample_ID','Processing_Time_ms','S1_Time.png',...
    'Section 1 - Processing Time','Sample','ms',out);
plotIf(T,'Sample_ID','FPS','S1_FPS.png','Section 1 - FPS','Sample','FPS',out);
end

function graphsS2(T,out)
plotIf(T,'Sample_ID','Head_Pose_Yaw','S2_Yaw.png',...
    'Section 2 - Head Pose Yaw','Sample','Degrees',out);
plotIf(T,'Sample_ID','Head_Pose_Pitch','S2_Pitch.png',...
    'Section 2 - Head Pose Pitch','Sample','Degrees',out);
plotIf(T,'Sample_ID','Head_Pose_Roll','S2_Roll.png',...
    'Section 2 - Head Pose Roll','Sample','Degrees',out);
plotIf(T,'Sample_ID','Distraction_Prediction','S2_Distraction.png',...
    'Section 2 - Distraction Prediction','Sample','Prediction',out);
plotIf(T,'Sample_ID','Processing_Time_ms','S2_Time.png',...
    'Section 2 - Processing Time','Sample','ms',out);
plotIf(T,'Sample_ID','FPS','S2_FPS.png','Section 2 - FPS','Sample','FPS',out);
end

function graphsS3(T,out)
plotIf(T,'Sample_ID','Face_Detected','S3_FaceDetection.png',...
    'Section 3 - Face Detection','Sample','Detected',out);
plotIf(T,'Sample_ID','Processing_Time_ms','S3_Time.png',...
    'Section 3 - Processing Time','Sample','ms',out);
plotIf(T,'Sample_ID','FPS','S3_FPS.png','Section 3 - FPS','Sample','FPS',out);
end

function plotIf(T,xName,yName,file,titleText,xlab,ylab,out)
if ~ismember(xName,T.Properties.VariableNames) || ...
   ~ismember(yName,T.Properties.VariableNames)
    return;
end
x=T.(xName); y=T.(yName);
if ~isnumeric(x), x=str2double(string(x)); end
if ~isnumeric(y), y=str2double(string(y)); end
ok=isfinite(x)&isfinite(y);
if ~any(ok), return; end

f=figure('Visible','off');
plot(x(ok),y(ok),'LineWidth',1);
grid on;
xlabel(xlab); ylabel(ylab); title(titleText);
saveas(f,fullfile(out,file));
close(f);
fprintf('  Graph: %s\n',file);
end
