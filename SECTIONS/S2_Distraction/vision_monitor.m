function [faceDetected, eyeDetected] = vision_monitor(img)

persistent faceDetector eyeDetector

if isempty(faceDetector)

    faceDetector = vision.CascadeObjectDetector();

    eyeDetector = vision.CascadeObjectDetector('EyePairBig');

end

%% Convert to grayscale

if size(img,3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end

%% Face detection

faces = step(faceDetector, grayImg);

faceDetected = 0;
eyeDetected = 0;

if isempty(faces)
    return;
end

%% Face found

faceDetected = 1;

%% Select largest face

areas = faces(:,3) .* faces(:,4);

[~, idx] = max(areas);

faceBox = faces(idx,:);

%% Extract face region

x = max(1, round(faceBox(1)));
y = max(1, round(faceBox(2)));

w = round(faceBox(3));
h = round(faceBox(4));

imageH = size(grayImg,1);
imageW = size(grayImg,2);

w = min(w, imageW-x+1);
h = min(h, imageH-y+1);

if w <= 0 || h <= 0
    return;
end

faceGray = grayImg( ...
    y:y+h-1, ...
    x:x+w-1);

%% Eye detection

eyes = step(eyeDetector, faceGray);

if ~isempty(eyes)
    eyeDetected = 1;
end

end