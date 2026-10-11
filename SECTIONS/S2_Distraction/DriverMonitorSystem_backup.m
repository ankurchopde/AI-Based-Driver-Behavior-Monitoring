classdef DriverMonitorSystem < matlab.System
    % DriverMonitorSystem Live webcam face and eye detection with annotation
    %
    % Outputs a 2x1 vector: [faceDetected; eyeDetected] to Simulink

    % Private properties for hardware and vision objects
    properties (Access = private)
        Cam
        FaceDetector
        EyeDetector
        VideoPlayer
    end

    methods (Access = protected)
        function setupImpl(obj)
            % Initialize webcam
            obj.Cam = webcam(1);
            
            % Initialize CascadeObjectDetectors
            obj.FaceDetector = vision.CascadeObjectDetector();
            obj.EyeDetector = vision.CascadeObjectDetector('EyePairBig');
            
            % Initialize VideoPlayer for high-performance live feed
            obj.VideoPlayer = vision.VideoPlayer('Name', 'AI Driver Monitoring - Live Detection', ...
                'Position', [100, 100, 800, 600]);
        end

        function detections = stepImpl(obj)
            % 1. Capture the live frame
            img = snapshot(obj.Cam);
            grayImg = rgb2gray(img);
            
            % Initialize signals
            faceDetected = 0;
            eyeDetected = 0;
            
            % 2. Detect Face
            faces = step(obj.FaceDetector, grayImg);
            
            outputImg = img;
            
            if ~isempty(faces)
                faceDetected = 1;
                
                % Take the largest face
                areas = faces(:,3) .* faces(:,4);
                [~, idx] = max(areas);
                faceBox = faces(idx, :);
                
                % Draw Face box
                outputImg = insertShape(outputImg, 'Rectangle', faceBox, ...
                    'Color', 'cyan', 'LineWidth', 3);
                
                % Extract face region safely
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
                    
                    % 3. Detect Eyes ONLY in face region
                    eyes = step(obj.EyeDetector, faceGray);
                    
                    if ~isempty(eyes)
                        eyeDetected = 1;
                        
                        % Map eye boxes back to full image and draw
                        for k = 1:size(eyes, 1)
                            eyeBox = eyes(k, :);
                            eyeBox(1) = eyeBox(1) + x - 1;
                            eyeBox(2) = eyeBox(2) + y - 1;
                            
                            outputImg = insertShape(outputImg, 'Rectangle', eyeBox, ...
                                'Color', 'green', 'LineWidth', 2);
                        end
                    end
                end
            end
            
            % 4. Add status text annotations
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
            
            outputImg = insertText(outputImg, [10 10], faceText, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            outputImg = insertText(outputImg, [10 45], eyeText, 'FontSize', 18, 'BoxColor', 'black', 'TextColor', 'white');
            
            % 5. Display the annotated image
            step(obj.VideoPlayer, outputImg);
            
            % 6. Send signals to Simulink as a 2x1 column vector
            detections = [faceDetected; eyeDetected];
        end

        function releaseImpl(obj)
            % Clean up resources safely
            if ~isempty(obj.VideoPlayer)
                release(obj.VideoPlayer);
            end
            if ~isempty(obj.FaceDetector)
                release(obj.FaceDetector);
            end
            if ~isempty(obj.EyeDetector)
                release(obj.EyeDetector);
            end
            if ~isempty(obj.Cam)
                delete(obj.Cam); % Properly deletes the webcam handle
            end
        end
        
        % --- Simulink Output Specifications ---
        function out = getOutputSizeImpl(~)
            out = [2 1]; % Output as a 2x1 vector
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
