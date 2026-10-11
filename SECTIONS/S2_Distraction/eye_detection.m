clear;
clc;
close all;

%% Configuration
camDeviceID = 1;
maxFrames = 300;

%% Step 1: Open Webcam
fprintf('=== Opening Webcam ===\n');

camList = webcamlist;

if isempty(camList)
    error('No webcam detected.');
end

cam = webcam(camDeviceID);

fprintf('Camera: %s\n', cam.Name);

%% Step 2: Create Face Detector
fprintf('=== Loading Face Detector ===\n');

faceDetector = vision.CascadeObjectDetector();

%% Step 3: Create Eye Detector
fprintf('=== Loading Eye Detector ===\n');

eyeDetector = vision.CascadeObjectDetector('EyePairBig');

fprintf('Eye detector loaded.\n');

%% Step 4: Create Figure

figureHandle = figure( ...
    'Name', 'Driver Monitoring - Eye Detection', ...
    'NumberTitle', 'off');

%% Step 5: Real-Time Detection

fprintf('=== Starting Eye Detection ===\n');

frameCount = 0;

while frameCount < maxFrames && isvalid(figureHandle)

    %% Capture frame
    img = snapshot(cam);

    %% Convert to grayscale
    grayImg = rgb2gray(img);

    %% Detect face
    faces = step(faceDetector, grayImg);

    outputImg = img;

    if ~isempty(faces)

        % Use the largest detected face
        faceAreas = faces(:,3) .* faces(:,4);
        [~, largestIndex] = max(faceAreas);

        faceBox = faces(largestIndex,:);

        % Draw face box
        outputImg = insertShape( ...
            outputImg, ...
            'Rectangle', ...
            faceBox, ...
            'Color', 'cyan', ...
            'LineWidth', 3);

        %% Extract face region

        faceX = max(1, round(faceBox(1)));
        faceY = max(1, round(faceBox(2)));
        faceW = round(faceBox(3));
        faceH = round(faceBox(4));

        % Prevent region from going outside image
        imageHeight = size(grayImg,1);
        imageWidth  = size(grayImg,2);

        faceW = min(faceW, imageWidth - faceX + 1);
        faceH = min(faceH, imageHeight - faceY + 1);

        faceGray = grayImg( ...
            faceY:faceY+faceH-1, ...
            faceX:faceX+faceW-1);

        %% Detect eye pair inside face

        eyePairs = step(eyeDetector, faceGray);

        if ~isempty(eyePairs)

            % Select largest eye-pair region
            eyeAreas = eyePairs(:,3) .* eyePairs(:,4);
            [~, eyeIndex] = max(eyeAreas);

            eyeBox = eyePairs(eyeIndex,:);

            %% Convert face-relative coordinates
            eyeBox(1) = eyeBox(1) + faceX - 1;
            eyeBox(2) = eyeBox(2) + faceY - 1;

            %% Draw eye-pair box

            outputImg = insertShape( ...
                outputImg, ...
                'Rectangle', ...
                eyeBox, ...
                'Color', 'green', ...
                'LineWidth', 3);

            eyeStatus = 'EYES DETECTED';

        else

            eyeStatus = 'EYES NOT DETECTED';

        end

    else

        eyeStatus = 'FACE NOT DETECTED';

    end

    %% Display

    imshow(outputImg);

    title(eyeStatus);

    drawnow;

    frameCount = frameCount + 1;

end

%% Step 6: Cleanup

fprintf('=== Cleaning Up ===\n');

clear cam;

if isvalid(figureHandle)
    close(figureHandle);
end

fprintf('Eye detection test completed.\n');