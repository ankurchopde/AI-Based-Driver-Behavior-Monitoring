classdef DistractionLogicSystem < matlab.System
    % DistractionLogicSystem Processes head pose to determine distraction state.
    
    properties (Nontunable)
        YawThreshold = 20;
        PitchThreshold = 20;
        RollThreshold = 20;
        GazeXLeftThreshold = -0.20;
        GazeXRightThreshold = 0.20;
        GazeYUpThreshold = -0.30;
        GazeYDownThreshold = 0.40;
        DistractionDuration = 1.5;
        SampleTime = 0.05; % 20 Hz
    end
    
    properties (Access = private)
        DistractedTimer
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            obj.DistractedTimer = 0;
        end
        
        function [state, alert, hl_out, hr_out, h_state, timer_out] = stepImpl(obj, face, yaw, pitch, roll, gaze_x, gaze_y, hand_left, hand_right)
            % State Enum: 
            % 0 = FORWARD, 1 = LEFT, 2 = RIGHT, 3 = UP, 4 = DOWN, 5 = DISTRACTED, 6 = NO_FACE
            % Internal States: POTENTIAL_*, DISTRACTION_CANDIDATE, HEAD_MOVEMENT_ONLY, FORWARD_COMPENSATED, 10 = HAND_OFF_POTENTIAL
            
            state = 0;
            alert = 0;
            distraction_candidate = false;
            
            hl_out = hand_left;
            hr_out = hand_right;
            
            if hand_left == -1 && hand_right == -1
                h_state = 5; % BOTH OFF
            elseif hand_left == -1 || hand_right == -1
                h_state = 4; % ONE OFF
            elseif hand_left == 1 && hand_right == 1
                h_state = 3; % BOTH ON
            elseif hand_left == 1
                h_state = 1; % LEFT ON
            elseif hand_right == 1
                h_state = 2; % RIGHT ON
            else
                h_state = 0; % UNKNOWN
            end
            
            hand_candidate = (h_state == 4 || h_state == 5);
            
            if face == 0
                state = 6;
                obj.DistractedTimer = 0;
            else
                % Determine head direction
                head_dir = 0; % 0=FORWARD, 1=LEFT, 2=RIGHT, 3=UP, 4=DOWN
                if yaw > obj.YawThreshold
                    head_dir = 1;
                elseif yaw < -obj.YawThreshold
                    head_dir = 2;
                elseif pitch > obj.PitchThreshold
                    head_dir = 4;
                elseif pitch < -obj.PitchThreshold
                    head_dir = 3;
                end
                
                % Determine gaze direction
                gaze_dir = 0; % 0=CENTER, 1=LEFT, 2=RIGHT, 3=UP, 4=DOWN
                if gaze_x < obj.GazeXLeftThreshold
                    gaze_dir = 1;
                elseif gaze_x > obj.GazeXRightThreshold
                    gaze_dir = 2;
                elseif gaze_y < obj.GazeYUpThreshold
                    gaze_dir = 3;
                elseif gaze_y > obj.GazeYDownThreshold
                    gaze_dir = 4;
                end
                
                % Combined Attention Logic
                if head_dir == 0 && gaze_dir == 0
                    state = 0; % FORWARD
                    distraction_candidate = false;
                elseif head_dir == 0 && gaze_dir ~= 0
                    state = gaze_dir;
                    distraction_candidate = true;
                elseif (head_dir == 1 && gaze_dir == 1) || (head_dir == 2 && gaze_dir == 2) || (head_dir == 4 && gaze_dir == 4) || (head_dir == 3 && gaze_dir == 3)
                    state = 8; % DISTRACTION_CANDIDATE
                    distraction_candidate = true;
                elseif head_dir ~= 0 && gaze_dir == 0
                    state = 7; % HEAD_MOVEMENT_ONLY
                    distraction_candidate = false;
                elseif (head_dir == 1 && gaze_dir == 2) || (head_dir == 2 && gaze_dir == 1)
                    state = 9; % FORWARD_COMPENSATED
                    distraction_candidate = false;
                else
                    state = 8; % DISTRACTION_CANDIDATE
                    distraction_candidate = true;
                end
                
                if hand_candidate && ~distraction_candidate
                    state = 10; % HAND OFF POTENTIAL (if head/gaze is fine but hands are off)
                end
                
                % Temporal Persistence
                if distraction_candidate || hand_candidate
                    obj.DistractedTimer = obj.DistractedTimer + obj.SampleTime;
                    if obj.DistractedTimer >= obj.DistractionDuration
                        state = 5; % DISTRACTED
                        alert = 1;
                    end
                else
                    obj.DistractedTimer = 0;
                end
            end
            timer_out = obj.DistractedTimer;
        end
        
        function resetImpl(obj)
            obj.DistractedTimer = 0;
        end
        
        function [out1, out2, out3, out4, out5, out6] = getOutputSizeImpl(~)
            out1 = [1 1]; out2 = [1 1]; out3 = [1 1]; out4 = [1 1]; out5 = [1 1]; out6 = [1 1];
        end
        
        function [out1, out2, out3, out4, out5, out6] = getOutputDataTypeImpl(~)
            out1 = 'double'; out2 = 'double'; out3 = 'double'; out4 = 'double'; out5 = 'double'; out6 = 'double';
        end
        
        function [out1, out2, out3, out4, out5, out6] = isOutputComplexImpl(~)
            out1 = false; out2 = false; out3 = false; out4 = false; out5 = false; out6 = false;
        end
        
        function [out1, out2, out3, out4, out5, out6] = isOutputFixedSizeImpl(~)
            out1 = true; out2 = true; out3 = true; out4 = true; out5 = true; out6 = true;
        end
    end
end
