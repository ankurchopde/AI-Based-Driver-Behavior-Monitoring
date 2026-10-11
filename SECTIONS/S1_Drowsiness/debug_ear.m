try
    cam = webcam(1);
    faceDet = vision.CascadeObjectDetector('FrontalFaceCART');
    eyeDet = vision.CascadeObjectDetector('EyePairBig');
    
    disp('Starting diagnostic: Please keep your face visible.');
    disp('Capturing frame with EYES OPEN in 3 seconds...');
    pause(3);
    imgOpen = snapshot(cam);
    
    disp('Capturing frame with EYES CLOSED in 3 seconds... (Close them now!)');
    pause(3);
    imgClosed = snapshot(cam);
    
    clear cam;
    disp('Camera released. Processing...');
    
    % Process Open
    [earOpen, msgOpen] = analyzeImage(imgOpen, faceDet, eyeDet, 'Open');
    [earClosed, msgClosed] = analyzeImage(imgClosed, faceDet, eyeDet, 'Closed');
    
    disp('--- DIAGNOSTIC RESULTS ---');
    disp(['Eyes OPEN EAR: ', num2str(earOpen), ' (', msgOpen, ')']);
    disp(['Eyes CLOSED EAR: ', num2str(earClosed), ' (', msgClosed, ')']);
    
catch ME
    disp(['Error: ', ME.message]);
    clear cam;
end

function [meanEAR, msg] = analyzeImage(img, faceDet, eyeDet, stateStr)
    meanEAR = 0; msg = 'Failed';
    gray = rgb2gray(img);
    faces = step(faceDet, gray);
    if isempty(faces), msg = 'No face detected'; return; end
    
    areas = faces(:,3) .* faces(:,4);
    [~, idx] = max(areas);
    face = faces(idx, :);
    
    faceGray = imcrop(gray, face);
    eyes = step(eyeDet, faceGray);
    
    if isempty(eyes), msg = 'No EyePairBig detected'; return; end
    
    eyeAreas = eyes(:,3) .* eyes(:,4);
    [~, eIdx] = max(eyeAreas);
    eyeBox = eyes(eIdx, :);
    
    ew = eyeBox(3); eh = eyeBox(4);
    leftBbox = [eyeBox(1), eyeBox(2), ew/2, eh];
    leftEyeImg = imcrop(faceGray, leftBbox);
    
    % Run the current heuristic
    eImg = histeq(leftEyeImg);
    level = graythresh(eImg);
    bw = eImg < (level * 255 * 0.8);
    bw = bwareaopen(bw, 10);
    props = regionprops(bw, 'Area', 'PixelList', 'BoundingBox');
    if isempty(props), msg = 'No dark blob found'; return; end
    
    [~, maxIdx] = max([props.Area]);
    pixels = props(maxIdx).PixelList;
    bbox = props(maxIdx).BoundingBox;
    
    % Does the blob look like an eyebrow? (Very wide, at the top)
    if bbox(2) < eh * 0.3
        msg = 'Blob is at the top (likely eyebrow!)';
    else
        msg = 'Blob found';
    end
    
    % Calc EAR
    [~, idx1] = min(pixels(:,1)); p1 = pixels(idx1, :);
    [~, idx4] = max(pixels(:,1)); p4 = pixels(idx4, :);
    w = p4(1) - p1(1);
    if w < 5, return; end
    
    x33 = p1(1) + w/3; c33 = pixels(abs(pixels(:,1) - x33) <= max(2, w/10), :);
    if ~isempty(c33)
        [~, minIdx] = min(c33(:,2)); p2 = c33(minIdx, :);
        [~, maxIdx] = max(c33(:,2)); p6 = c33(maxIdx, :);
    else
        p2=p1; p6=p1;
    end
    
    x66 = p1(1) + 2*w/3; c66 = pixels(abs(pixels(:,1) - x66) <= max(2, w/10), :);
    if ~isempty(c66)
        [~, minIdx] = min(c66(:,2)); p3 = c66(minIdx, :);
        [~, maxIdx] = max(c66(:,2)); p5 = c66(maxIdx, :);
    else
        p3=p4; p5=p4;
    end
    
    dist = @(a,b) sqrt(sum((a-b).^2));
    meanEAR = (dist(p2,p6) + dist(p3,p5))/(2*dist(p1,p4));
    
    % Save debug image
    h = figure('Visible', 'off');
    imshow(bw); title([stateStr, ' Eye Blob']);
    hold on; plot([p1(1) p2(1) p3(1) p4(1) p5(1) p6(1)], [p1(2) p2(2) p3(2) p4(2) p5(2) p6(2)], 'rx', 'MarkerSize', 10);
    saveas(h, ['debug_', stateStr, '.png']);
    close(h);
end
