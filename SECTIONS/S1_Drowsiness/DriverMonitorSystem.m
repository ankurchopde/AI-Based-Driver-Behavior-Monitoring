classdef DriverMonitorSystem < matlab.System
    % DriverMonitorSystem Live webcam face, eye, and EAR detection
    % Outputs a 3x1 vector: [faceDetected; eyeDetected; EAR] to Simulink

    % Private properties for hardware and vision objects
    properties (Access = private)
        Cam
        FaceDetector
        EyeDetector
        VideoPlayer
        LastEyeOffset % Anchors the eye box to the face to survive blinks
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.Cam = webcam(1);
            obj.FaceDetector = vision.CascadeObjectDetector('FrontalFaceCART');
            obj.EyeDetector = vision.CascadeObjectDetector('EyePairBig');
            obj.VideoPlayer = vision.VideoPlayer('Name', 'AI Driver Monitoring - Live Detection', ...
                'Position', [100, 100, 800, 600]);
            obj.LastEyeOffset = [];
        end

        function detections = stepImpl(obj)
            img = snapshot(obj.Cam);
            grayImg = rgb2gray(img);
            
            faceDetected = 0;
            eyeDetected = 0;
            meanEAR = 0.0;
            
            faces = step(obj.FaceDetector, grayImg);
            outputImg = img;
            
            if ~isempty(faces)
                faceDetected = 1;
                
                % Largest face
                areas = faces(:,3) .* faces(:,4);
                [~, idx] = max(areas);
                faceBox = faces(idx, :);
                
                outputImg = insertShape(outputImg, 'Rectangle', faceBox, 'Color', 'cyan', 'LineWidth', 3);
                
                x = max(1, round(faceBox(1)));
                y = max(1, round(faceBox(2)));
                w = round(faceBox(3));
                h = round(faceBox(4));
                
                imageH = size(grayImg, 1);
                imageW = size(grayImg, 2);
                
                w = min(w, imageW - x + 1);
                h = min(h, imageH - y + 1);
                
                if w > 0 && h > 0
                    faceGray = grayImg(y:y+h-1, x:x+w-1);
                    eyes = step(obj.EyeDetector, faceGray);
                    
                    eyeBox = [];
                    if ~isempty(eyes)
                        eyeDetected = 1;
                        eyeAreas = eyes(:,3) .* eyes(:,4);
                        [~, eIdx] = max(eyeAreas);
                        eyeBox = eyes(eIdx, :);
                        
                        % Anchor the offset relative to the face box width/height
                        obj.LastEyeOffset = eyeBox;
                    else
                        % EyePairBig lost tracking (likely because eyes are closed!)
                        % Fallback to the anchored position
                        if ~isempty(obj.LastEyeOffset)
                            eyeBox = obj.LastEyeOffset;
                        end
                    end
                    
                    if ~isempty(eyeBox)
                        % Draw global eye bounding box
                        globalEyeBox = eyeBox;
                        globalEyeBox(1) = globalEyeBox(1) + x - 1;
                        globalEyeBox(2) = globalEyeBox(2) + y - 1;
                        outputImg = insertShape(outputImg, 'Rectangle', globalEyeBox, 'Color', 'green', 'LineWidth', 2);
                        
                        % Split eye box
                        ew = eyeBox(3); eh = eyeBox(4);
                        leftEyeBbox = [eyeBox(1), eyeBox(2), ew/2, eh];
                        rightEyeBbox = [eyeBox(1) + ew/2, eyeBox(2), ew/2, eh];
                        
                        leftEyeImg = imcrop(faceGray, leftEyeBbox);
                        rightEyeImg = imcrop(faceGray, rightEyeBbox);
                        
                        [leftEAR, leftLms] = obj.extractEyeLandmarks(leftEyeImg);
                        [rightEAR, rightLms] = obj.extractEyeLandmarks(rightEyeImg);
                        
                        if leftEAR > 0 && rightEAR > 0
                            meanEAR = (leftEAR + rightEAR) / 2;
                        elseif leftEAR > 0
                            meanEAR = leftEAR;
                        elseif rightEAR > 0
                            meanEAR = rightEAR;
                        else
                            meanEAR = 0.0;
                        end
                        
                        % Draw Landmarks
                        if ~isempty(leftLms)
                            globalLeftLms = leftLms;
                            globalLeftLms(:,1) = globalLeftLms(:,1) + leftEyeBbox(1) + x - 2;
                            globalLeftLms(:,2) = globalLeftLms(:,2) + leftEyeBbox(2) + y - 2;
                            outputImg = insertMarker(outputImg, globalLeftLms, 'x', 'Color', 'yellow', 'Size', 5);
                        end
                        
                        if ~isempty(rightLms)
                            globalRightLms = rightLms;
                            globalRightLms(:,1) = globalRightLms(:,1) + rightEyeBbox(1) + x - 2;
                            globalRightLms(:,2) = globalRightLms(:,2) + rightEyeBbox(2) + y - 2;
                            outputImg = insertMarker(outputImg, globalRightLms, 'x', 'Color', 'yellow', 'Size', 5);
                        end
                    end
                end
            end
            
            % Annotations
            faceText = conditionalStr(faceDetected, 'FACE: DETECTED', 'FACE: NOT DETECTED');
            eyeText = conditionalStr(eyeDetected, 'EYES: DETECTED', 'EYES: NOT DETECTED');
            earText = sprintf('EAR: %.3f', meanEAR);
            
            outputImg = insertText(outputImg, [10 10], faceText, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            outputImg = insertText(outputImg, [10 45], eyeText, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            outputImg = insertText(outputImg, [10 80], earText, 'FontSize', 18, 'BoxColor', 'yellow', 'TextColor', 'black');
            
            step(obj.VideoPlayer, outputImg);
            detections = [faceDetected; eyeDetected; meanEAR];
        end

        function releaseImpl(obj)
            if ~isempty(obj.VideoPlayer), release(obj.VideoPlayer); end
            if ~isempty(obj.FaceDetector), release(obj.FaceDetector); end
            if ~isempty(obj.EyeDetector), release(obj.EyeDetector); end
            if ~isempty(obj.Cam), delete(obj.Cam); end
        end
        
        function [ear, landmarks] = extractEyeLandmarks(~, eyeImg)
            ear = 0; landmarks = [];
            if isempty(eyeImg), return; end
            
            [h, w, ~] = size(eyeImg);
            
            % CRITICAL FIX: Crop out the top 35% (eyebrow) and bottom 15% (cheek)
            % This forces the logic to ONLY see the eyelid/lashes.
            cropY = round(h * 0.35);
            cropH = round(h * 0.50);
            if cropH < 5, return; end
            
            strip = imcrop(eyeImg, [1, cropY, w, cropH]);
            
            % Enhance and binarize
            eImg = histeq(strip);
            level = graythresh(eImg);
            bw = eImg < (level * 255 * 0.85); 
            
            bw = bwareaopen(bw, max(5, round((w*cropH)*0.01)));
            
            props = regionprops(bw, 'Area', 'PixelList');
            if isempty(props), return; end
            
            [~, maxIdx] = max([props.Area]);
            pixels = props(maxIdx).PixelList;
            
            % Adjust Y back to the original uncropped eyeImg
            pixels(:,2) = pixels(:,2) + cropY - 1;
            
            % 6-point logic
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
                p2 = p1; p6 = p1;
            end
            
            x66 = p1(1) + 2*blobW/3;
            c66 = pixels(abs(pixels(:,1) - x66) <= max(2, blobW/10), :);
            if ~isempty(c66)
                [~, minIdx] = min(c66(:,2)); p3 = c66(minIdx, :);
                [~, maxIdx] = max(c66(:,2)); p5 = c66(maxIdx, :);
            else
                p3 = p4; p5 = p4;
            end
            
            landmarks = [p1; p2; p3; p4; p5; p6];
            
            % EAR Formula
            dist = @(a, b) sqrt(sum((a - b).^2));
            vertical1 = dist(p2, p6);
            vertical2 = dist(p3, p5);
            horizontal = dist(p1, p4);
            
            if horizontal > 0
                ear = (vertical1 + vertical2) / (2 * horizontal);
            end
        end
        
        function out = getOutputSizeImpl(~)
            out = [3 1];
        end
        
        function out = getOutputDataTypeImpl(~)
            out = 'double';
        end
        
        function out = isOutputComplexImpl(~)
            out = false;
        end
        
        function out = isOutputFixedSizeImpl(~)
            out = true;
        end
    end
end

% Helper
function str = conditionalStr(cond, trueStr, falseStr)
    if cond
        str = trueStr;
    else
        str = falseStr;
    end
end
