function output = vision_monitor_sim()

persistent cam faceDetector eyeDetector hFig

%% Initialize
if isempty(cam)

    cam = webcam(1);

    faceDetector = vision.CascadeObjectDetector();
    eyeDetector = vision.CascadeObjectDetector('EyePairBig');

    hFig = figure( ...
        'Name','AI Driver Monitoring - Live Detection', ...
        'NumberTitle','off', ...
        'Color','black');

end

%% Capture frame
img = snapshot(cam);

grayImg = rgb2gray(img);

faceDetected = 0;
eyeDetected = 0;

%% Face detection
faces = step(faceDetector, grayImg);

outputImg = img;

if ~isempty(faces)

    faceDetected = 1;

    % Largest face
    areas = faces(:,3).*faces(:,4);
    [~,idx] = max(areas);
    faceBox = faces(idx,:);

    % Draw face box
    outputImg = insertShape( ...
        outputImg,'Rectangle',faceBox, ...
        'Color','cyan','LineWidth',3);

    % Face region
    x = max(1,round(faceBox(1)));
    y = max(1,round(faceBox(2)));
    w = round(faceBox(3));
    h = round(faceBox(4));

    imageH = size(grayImg,1);
    imageW = size(grayImg,2);

    w = min(w,imageW-x+1);
    h = min(h,imageH-y+1);

    if w > 0 && h > 0

        faceGray = grayImg(y:y+h-1,x:x+w-1);

        %% Eye detection
        eyes = step(eyeDetector,faceGray);

        if ~isempty(eyes)

            eyeDetected = 1;

            % Convert eye coordinates back to full image
            for k = 1:size(eyes,1)

                eyeBox = eyes(k,:);

                eyeBox(1) = eyeBox(1) + x - 1;
                eyeBox(2) = eyeBox(2) + y - 1;

                outputImg = insertShape( ...
                    outputImg,'Rectangle',eyeBox, ...
                    'Color','green','LineWidth',2);

            end
        end
    end
end

%% Status text

if faceDetected
    faceText = 'FACE: DETECTED';
else
    faceText = 'FACE: NOT DETECTED';
end

if eyeDetected
    eyeText = 'EYES: DETECTED';
else
    eyeText = 'EYES: NOT DETECTED';
end

outputImg = insertText( ...
    outputImg,[10 10],faceText, ...
    'FontSize',18, ...
    'BoxColor','black', ...
    'TextColor','white');

outputImg = insertText( ...
    outputImg,[10 45],eyeText, ...
    'FontSize',18, ...
    'BoxColor','black', ...
    'TextColor','white');

%% Display live detection
if ~isempty(hFig) && isvalid(hFig)

    figure(hFig);
    imshow(outputImg);
    title('AI Driver Monitoring - Live Detection');
    drawnow limitrate;

end

%% Send signals to Simulink
output = [faceDetected eyeDetected];

end