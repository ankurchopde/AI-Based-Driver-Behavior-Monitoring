%============================================================================
% face_detection.m
% Stage 2 - Real-Time Face Detection
%============================================================================

clear;
clc;
close all;

%% Configuration

camDeviceID = 1;
maxFrames = 300;

%% Step 1 - Detect Webcam

fprintf('=== Detecting Webcam ===\n');

camList = webcamlist;

if isempty(camList)
    error('No webcam detected.');
end

fprintf('Camera: %s\n', camList{camDeviceID});

%% Step 2 - Open Webcam

fprintf('\n=== Opening Webcam ===\n');

try
    cam = webcam(camDeviceID);
    fprintf('Webcam opened: %s\n', cam.Name);
catch ME
    error('Could not open webcam:\n%s', ME.message);
end

%% Step 3 - Create Face Detector

fprintf('\n=== Loading Face Detector ===\n');

faceDetector = vision.CascadeObjectDetector();

fprintf('Face detector ready.\n');

%% Step 4 - Create Figure

figureHandle = figure( ...
    'Name', 'AI Driver Monitoring - Face Detection', ...
    'NumberTitle', 'off');

%% Step 5 - Real-Time Processing

fprintf('\n=== Starting Face Detection ===\n');

frameCount = 0;

while frameCount < maxFrames && isvalid(figureHandle)

    try

        %% Capture frame

        img = snapshot(cam);

        %% Convert to grayscale

        if size(img,3) == 3
            grayImg = rgb2gray(img);
        else
            grayImg = img;
        end

        %% Detect face

        faces = step(faceDetector, grayImg);

        %% Draw result

        outputImg = img;

        if ~isempty(faces)

            % Select largest face
            areas = faces(:,3) .* faces(:,4);
            [~, largestIndex] = max(areas);

            faceBox = faces(largestIndex,:);

            outputImg = insertShape( ...
                outputImg, ...
                'Rectangle', ...
                faceBox, ...
                'Color', 'cyan', ...
                'LineWidth', 3);

            statusText = 'FACE DETECTED';

        else

            statusText = 'NO FACE DETECTED';

        end

        %% Display

        imshow(outputImg);

        title(sprintf('%s | Frame: %d', ...
            statusText, frameCount + 1));

        drawnow limitrate;

        frameCount = frameCount + 1;

    catch ME

        % Webcam timeout recovery
        if contains(ME.message, 'Timeout occurred', ...
                'IgnoreCase', true)

            warning('Webcam timeout. Retrying...');

            pause(0.1);
            continue;

        else

            rethrow(ME);

        end

    end

end

%% Step 6 - Cleanup

fprintf('\n=== Cleaning Up ===\n');

clear cam;

if isvalid(figureHandle)
    close(figureHandle);
end

fprintf('Face detection completed.\n');