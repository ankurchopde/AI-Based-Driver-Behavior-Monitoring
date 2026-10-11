try
    cam = webcam(1);
    img = snapshot(cam);
    clear cam; % Free it immediately
    
    grayImg = rgb2gray(img);
    faceDet = vision.CascadeObjectDetector('FrontalFaceCART');
    eyeDet = vision.CascadeObjectDetector('EyePairBig');
    
    faces = step(faceDet, grayImg);
    if ~isempty(faces)
        face = faces(1,:);
        faceImg = imcrop(grayImg, face);
        eyes = step(eyeDet, faceImg);
        
        if ~isempty(eyes)
            eyeBox = eyes(1,:);
            % Split into left and right (relative to faceImg)
            % eyeBox is [x, y, w, h]
            w = eyeBox(3); h = eyeBox(4);
            leftEyeBbox = [eyeBox(1), eyeBox(2), w/2, h];
            rightEyeBbox = [eyeBox(1) + w/2, eyeBox(2), w/2, h];
            
            leftEyeImg = imcrop(faceImg, leftEyeBbox);
            rightEyeImg = imcrop(faceImg, rightEyeBbox);
            
            disp('Left Eye Size:'); disp(size(leftEyeImg));
            disp('Right Eye Size:'); disp(size(rightEyeImg));
            
            % Simple extraction logic
            testImg = histeq(leftEyeImg);
            bw = ~imbinarize(testImg, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.45);
            bw = bwareaopen(bw, 10);
            props = regionprops(bw, 'Area', 'PixelList');
            if ~isempty(props)
                [~, maxIdx] = max([props.Area]);
                disp('Found eye blob in left eye!');
                disp(['Area: ', num2str(props(maxIdx).Area)]);
            else
                disp('No blobs found.');
            end
        else
            disp('No eyes found in face.');
        end
    else
        disp('No face found.');
    end
catch ME
    disp(['Error: ', ME.message]);
    clear cam;
end
