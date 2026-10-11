function debug_EAR_visual()
    % Cleanup
    close all; clear cam;
    
    % Initialize Hardware & Vision
    try
        cam = webcam(1);
    catch
        error('Cannot connect to webcam(1).');
    end
    faceDet = vision.CascadeObjectDetector('FrontalFaceCART');
    eyeDet = vision.CascadeObjectDetector('EyePairBig');
    
    % Initialize Figure
    hFig = figure('Name', 'EAR Visual Diagnostic', 'Position', [100 100 800 800]);
    
    % Subplot 1: Video
    ax1 = subplot(2, 1, 1);
    hImg = imshow(zeros(480, 640, 3, 'uint8'), 'Parent', ax1);
    title(ax1, 'Live EAR 6-Point Tracking');
    
    % Subplot 2: Graph
    ax2 = subplot(2, 1, 2);
    hPlot = plot(ax2, 0, 0, 'y-', 'LineWidth', 2);
    set(ax2, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
    ylim(ax2, [0 0.6]);
    xlim(ax2, [0 150]);
    title(ax2, 'EAR History (Last 10 Seconds)');
    grid(ax2, 'on');
    
    % State Variables
    earHistory = [];
    openEARs = [];
    closedEARs = [];
    
    frameCount = 0;
    maxFrames = 300; % ~20 seconds
    
    lastEyeOffset = [];
    threshold = 0.20;
    
    disp('--- STARTING EAR CALIBRATION DIAGNOSTIC ---');
    
    while ishandle(hFig) && frameCount < maxFrames
        frameCount = frameCount + 1;
        
        if frameCount < 70
            instruction = 'Phase 1: Keep eyes OPEN';
            phase = 'OPEN';
        elseif frameCount < 140
            instruction = 'Phase 2: Close eyes NOW (for 4 seconds)';
            phase = 'CLOSED';
        else
            instruction = 'Phase 3: Free Test (Blink normally)';
            phase = 'TEST';
        end
        
        img = snapshot(cam);
        gray = rgb2gray(img);
        
        meanEAR = 0;
        stateStr = 'NO VALID EYE';
        stateColor = 'red';
        
        faces = step(faceDet, gray);
        if ~isempty(faces)
            areas = faces(:,3) .* faces(:,4);
            [~, idx] = max(areas);
            faceBox = faces(idx, :);
            
            img = insertShape(img, 'Rectangle', faceBox, 'Color', 'cyan', 'LineWidth', 2);
            
            x = max(1, round(faceBox(1)));
            y = max(1, round(faceBox(2)));
            w = round(faceBox(3));
            h = round(faceBox(4));
            
            [imgH, imgW, ~] = size(gray);
            w = min(w, imgW - x + 1);
            h = min(h, imgH - y + 1);
            
            if w > 0 && h > 0
                faceGray = gray(y:y+h-1, x:x+w-1);
                eyes = step(eyeDet, faceGray);
                
                eyeBox = [];
                if ~isempty(eyes)
                    eyeAreas = eyes(:,3) .* eyes(:,4);
                    [~, eIdx] = max(eyeAreas);
                    eyeBox = eyes(eIdx, :);
                    lastEyeOffset = eyeBox;
                elseif ~isempty(lastEyeOffset)
                    eyeBox = lastEyeOffset;
                end
                
                if ~isempty(eyeBox)
                    globalEyeBox = eyeBox;
                    globalEyeBox(1) = globalEyeBox(1) + x - 1;
                    globalEyeBox(2) = globalEyeBox(2) + y - 1;
                    img = insertShape(img, 'Rectangle', globalEyeBox, 'Color', 'magenta', 'LineWidth', 2);
                    
                    ew = eyeBox(3); eh = eyeBox(4);
                    leftEyeBbox = [eyeBox(1), eyeBox(2), ew/2, eh];
                    rightEyeBbox = [eyeBox(1) + ew/2, eyeBox(2), ew/2, eh];
                    
                    leftEyeImg = imcrop(faceGray, leftEyeBbox);
                    rightEyeImg = imcrop(faceGray, rightEyeBbox);
                    
                    [leftEAR, leftLms] = extractEyeLandmarks(leftEyeImg);
                    [rightEAR, rightLms] = extractEyeLandmarks(rightEyeImg);
                    
                    if leftEAR > 0 && rightEAR > 0
                        meanEAR = (leftEAR + rightEAR) / 2;
                    elseif leftEAR > 0
                        meanEAR = leftEAR;
                    elseif rightEAR > 0
                        meanEAR = rightEAR;
                    end
                    
                    img = drawEyeLandmarks(img, leftLms, leftEyeBbox, x, y);
                    img = drawEyeLandmarks(img, rightLms, rightEyeBbox, x, y);
                    
                    if meanEAR > 0
                        if meanEAR > threshold
                            stateStr = 'EYES: OPEN';
                            stateColor = 'green';
                        else
                            stateStr = 'EYES: CLOSED';
                            stateColor = 'red';
                        end
                        
                        if strcmp(phase, 'OPEN')
                            openEARs(end+1) = meanEAR;
                        elseif strcmp(phase, 'CLOSED')
                            closedEARs(end+1) = meanEAR;
                        end
                    end
                end
            end
        end
        
        earHistory(end+1) = meanEAR;
        
        % Annotations
        img = insertText(img, [10 10], instruction, 'FontSize', 22, 'BoxColor', 'yellow', 'TextColor', 'black');
        img = insertText(img, [10 50], sprintf('EAR = %.3f', meanEAR), 'FontSize', 20, 'BoxColor', 'white', 'TextColor', 'black');
        img = insertText(img, [10 90], stateStr, 'FontSize', 20, 'BoxColor', stateColor, 'TextColor', 'white');
        img = insertText(img, [10 130], sprintf('Threshold = %.2f', threshold), 'FontSize', 16, 'BoxColor', 'black', 'TextColor', 'white');
        
        set(hImg, 'CData', img);
        
        if length(earHistory) > 150
            earDisp = earHistory(end-149:end);
        else
            earDisp = earHistory;
        end
        set(hPlot, 'XData', 1:length(earDisp), 'YData', earDisp);
        drawnow limitrate;
    end
    
    if ishandle(hFig)
        close(hFig);
    end
    clear cam;
    
    % Print Report
    disp('--- DIAGNOSTIC CALIBRATION REPORT ---');
    if isempty(openEARs) || isempty(closedEARs)
        disp('Insufficient data. Could not detect eyes reliably during both phases.');
        return;
    end
    
    minOpen = min(openEARs); maxOpen = max(openEARs); meanOpen = mean(openEARs);
    minClosed = min(closedEARs); maxClosed = max(closedEARs); meanClosed = mean(closedEARs);
    
    disp('Eyes OPEN:');
    fprintf('  Min: %.3f\n  Max: %.3f\n  Mean: %.3f\n', minOpen, maxOpen, meanOpen);
    
    disp('Eyes CLOSED:');
    fprintf('  Min: %.3f\n  Max: %.3f\n  Mean: %.3f\n', minClosed, maxClosed, meanClosed);
    
    separation = minOpen - maxClosed;
    fprintf('\nSeparation between open(min) and closed(max): %.3f\n', separation);
    
    if separation > 0.05
        sugg = (minOpen + maxClosed) / 2;
        fprintf('SUGGESTED THRESHOLD: %.3f\n', sugg);
        disp('STATUS: Algorithm VALID for your lighting/eyes!');
    else
        disp('STATUS: WARNING - Overlap detected or separation too small.');
        disp('The dark-pixel geometric heuristic is inadequate for this environment.');
    end
end

function img = drawEyeLandmarks(img, lms, bbox, faceX, faceY)
    if isempty(lms)
        return;
    end
    
    glms = lms;
    glms(:,1) = glms(:,1) + bbox(1) + faceX - 2;
    glms(:,2) = glms(:,2) + bbox(2) + faceY - 2;
    
    img = insertMarker(img, glms, 'o', 'Color', 'yellow', 'Size', 4);
    
    lines = [
        glms(2,1) glms(2,2) glms(6,1) glms(6,2); % p2 to p6
        glms(3,1) glms(3,2) glms(5,1) glms(5,2); % p3 to p5
        glms(1,1) glms(1,2) glms(4,1) glms(4,2)  % p1 to p4
    ];
    img = insertShape(img, 'Line', lines, 'Color', 'cyan', 'LineWidth', 1);
    
    positions = zeros(6,2);
    labels = cell(1,6);
    for i=1:6
        positions(i,:) = glms(i,:) + [2 2];
        labels{i} = sprintf('p%d', i);
    end
    img = insertText(img, positions, labels, 'FontSize', 12, 'BoxOpacity', 0, 'TextColor', 'yellow');
end

function [ear, landmarks] = extractEyeLandmarks(eyeImg)
    ear = 0; landmarks = [];
    if isempty(eyeImg), return; end
    
    [h, w, ~] = size(eyeImg);
    cropY = round(h * 0.35);
    cropH = round(h * 0.50);
    if cropH < 5, return; end
    
    strip = imcrop(eyeImg, [1, cropY, w, cropH]);
    
    eImg = histeq(strip);
    level = graythresh(eImg);
    bw = eImg < (level * 255 * 0.85);
    bw = bwareaopen(bw, max(5, round((w*cropH)*0.01)));
    
    props = regionprops(bw, 'Area', 'PixelList');
    if isempty(props), return; end
    
    [~, maxIdx] = max([props.Area]);
    pixels = props(maxIdx).PixelList;
    pixels(:,2) = pixels(:,2) + cropY - 1;
    
    [~, idx1] = min(pixels(:,1)); p1 = pixels(idx1, :);
    [~, idx4] = max(pixels(:,1)); p4 = pixels(idx4, :);
    
    blobW = p4(1) - p1(1);
    if blobW < 5, return; end
    
    x33 = p1(1) + blobW/3;
    c33 = pixels(abs(pixels(:,1) - x33) <= max(2, blobW/10), :);
    if ~isempty(c33)
        [~, minIdx] = min(c33(:,2)); p2 = c33(minIdx, :);
        [~, maxIdx] = max(c33(:,2)); p6 = c33(maxIdx, :);
    else
        p2=p1; p6=p1;
    end
    
    x66 = p1(1) + 2*blobW/3;
    c66 = pixels(abs(pixels(:,1) - x66) <= max(2, blobW/10), :);
    if ~isempty(c66)
        [~, minIdx] = min(c66(:,2)); p3 = c66(minIdx, :);
        [~, maxIdx] = max(c66(:,2)); p5 = c66(maxIdx, :);
    else
        p3=p4; p5=p4;
    end
    
    landmarks = [p1; p2; p3; p4; p5; p6];
    
    dist = @(a, b) sqrt(sum((a - b).^2));
    vertical1 = dist(p2, p6);
    vertical2 = dist(p3, p5);
    horizontal = dist(p1, p4);
    
    if horizontal > 0
        ear = (vertical1 + vertical2) / (2 * horizontal);
    end
end
