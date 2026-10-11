%============================================================================
% config.m — Drowsiness Detection Configuration
%============================================================================
% Camera configuration
camDeviceID = 1;           % Webcam device ID (try 0 if 1 doesn't work)
camFrameRate = 30;         % Target frame rate

% Face detection parameters
faceScaleFactor = 1.1;     % Parameter specifying how much the image size
           % is reduced at each image scale
faceMinNeighbors = 3;      % Parameter specifying how many neighbors
           % each candidate rectangle should have to retain it

% Eye detection parameters
earThreshold = 0.25;       % Eye Aspect Ratio threshold for blink detection
consecutiveClosedFrames = 10;  % Number of consecutive closed frames to trigger warning

% Temporal analysis parameters
warningDuration = 2.0;     % Duration (seconds) of sustained closure to trigger warning
blinkCountWindow = 60;     % Number of frames for blink rate calculation (at 30fps = 2sec)

% Drowsiness scoring
drowsinessScoreThreshold = 0.5;  % Threshold for classifying drowsiness state

% Alert configuration
enableAudioAlert = true;   % Play MATLAB audio alert when drowsy detected
alertTextColor = [1 0 0];  % Red color for warning text
normalTextColor = [1 1 1]; % White color for normal text