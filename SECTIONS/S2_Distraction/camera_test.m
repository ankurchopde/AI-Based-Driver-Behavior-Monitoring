%============================================================================
% camera_test.m
% Stage 1 - MATLAB Webcam Test
%============================================================================

clear;
clc;
close all;

%% Step 1: Detect Available Webcams

fprintf('=== Step 1: Detecting Available Webcams ===\n');

camList = webcamlist;

if isempty(camList)
    error('No webcams found. Please connect a webcam and try again.');
end

fprintf('Found %d webcam(s):\n', length(camList));

for k = 1:length(camList)
    fprintf('  %d: %s\n', k, camList{k});
end

%% Step 2: Open Webcam

fprintf('\n=== Step 2: Opening Webcam ===\n');

camDeviceID = 1;

try
    cam = webcam(camDeviceID);

    fprintf('Webcam opened successfully.\n');

catch ME

    error('Failed to open webcam %d:\n%s', ...
        camDeviceID, ME.message);

end

%% Step 3: Display Camera Information

fprintf('\n=== Step 3: Camera Information ===\n');

fprintf('Camera: %s\n', cam.Name);

fprintf('Available resolutions:\n');

disp(cam.AvailableResolutions);

%% Step 4: Set Lower Resolution

try

    cam.Resolution = '640x480';

    fprintf('Resolution set to: %s\n', cam.Resolution);

catch

    fprintf('640x480 is not available. Using default resolution: %s\n', ...
        cam.Resolution);

end

%% Step 5: Single Frame Test

fprintf('\n=== Step 5: Single Frame Test ===\n');

try

    img = snapshot(cam);

    fprintf('Frame captured successfully.\n');

catch ME

    clear cam;

    error(['Failed to capture frame.\n\n' ...
           'MATLAB webcam error:\n%s'], ME.message);

end

%% Step 6: Display Frame

figureHandle = figure( ...
    'Name', 'AI Driver Monitoring - Camera Test', ...
    'NumberTitle', 'off');

imshow(img);

title('Webcam Test - Frame Captured Successfully');

drawnow;

fprintf('\nCamera test successful.\n');
fprintf('Close the figure to finish the test.\n');

%% Wait for Figure to Close

while isvalid(figureHandle)

    drawnow;

    pause(0.1);

end

%% Step 7: Cleanup

fprintf('\n=== Step 7: Cleanup ===\n');

clear cam;

fprintf('Webcam released.\n');
fprintf('Camera test completed successfully.\n');