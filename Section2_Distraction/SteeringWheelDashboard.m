classdef SteeringWheelDashboard < matlab.System
    % SteeringWheelDashboard Visualizes the steering wheel and hand statuses
    
    properties (Access = private, Hidden, Transient, Nontunable)
        FigHandle
        AxHandle
        LeftHandPlot
        RightHandPlot
        LeftHandText
        RightHandText
        TextHL
        TextHR
        TextOverall
        TextTimer
        TextDistraction
        TextAlert
        PanelAx
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('MATLAB')
                % Create figure
                obj.FigHandle = figure('Name', 'Task 2.5 - Steering Wheel Dashboard', 'NumberTitle', 'off', ...
                    'Position', [100, 100, 900, 500], 'MenuBar', 'none', 'ToolBar', 'none', 'Color', [0.95 0.95 0.95]);
                
                % ==============================================
                % LEFT AXES: STEERING WHEEL DIAGRAM
                % ==============================================
                obj.AxHandle = axes('Parent', obj.FigHandle, 'Position', [0.05 0.05 0.45 0.9], 'Color', [0.95 0.95 0.95]);
                hold(obj.AxHandle, 'on');
                axis(obj.AxHandle, 'off');
                axis(obj.AxHandle, 'equal');
                xlim(obj.AxHandle, [0 1]);
                ylim(obj.AxHandle, [0 1]);
                set(obj.AxHandle, 'YDir', 'reverse'); % Match image coordinates (0,0 at top-left)
                
                % Draw Steering Wheel ROI box for reference
                plot(obj.AxHandle, [0.1 0.9 0.9 0.1 0.1], [0.55 0.55 1.0 1.0 0.55], 'b--', 'LineWidth', 1.5);
                text(obj.AxHandle, 0.12, 0.58, 'WHEEL ROI', 'Color', 'b', 'FontSize', 10, 'FontWeight', 'bold');
                
                % Draw Steering Wheel (Center at X=0.5, Y=0.775)
                th = linspace(0, 2*pi, 100);
                wx = 0.5 + 0.3 * cos(th);
                wy = 0.775 + 0.225 * sin(th);
                plot(obj.AxHandle, wx, wy, 'k-', 'LineWidth', 12, 'Color', [0.2 0.2 0.2]); % Outer Rim
                
                % Hub and Spokes
                plot(obj.AxHandle, 0.5 + 0.05*cos(th), 0.775 + 0.05*sin(th), '-', 'LineWidth', 4, 'Color', [0.4 0.4 0.4]);
                plot(obj.AxHandle, [0.2 0.45], [0.775 0.775], '-', 'LineWidth', 8, 'Color', [0.3 0.3 0.3]);
                plot(obj.AxHandle, [0.55 0.8], [0.775 0.775], '-', 'LineWidth', 8, 'Color', [0.3 0.3 0.3]);
                plot(obj.AxHandle, [0.5 0.5], [0.825 1.0], '-', 'LineWidth', 8, 'Color', [0.3 0.3 0.3]);
                
                % Hand markers
                obj.LeftHandPlot = plot(obj.AxHandle, -1, -1, 'o', 'MarkerSize', 24, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
                obj.RightHandPlot = plot(obj.AxHandle, -1, -1, 'o', 'MarkerSize', 24, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
                
                obj.LeftHandText = text(obj.AxHandle, -1, -1, 'L', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
                obj.RightHandText = text(obj.AxHandle, -1, -1, 'R', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
                
                % ==============================================
                % RIGHT AXES: STATUS PANEL
                % ==============================================
                obj.PanelAx = axes('Parent', obj.FigHandle, 'Position', [0.55 0.05 0.4 0.9]);
                hold(obj.PanelAx, 'on');
                axis(obj.PanelAx, 'off');
                xlim(obj.PanelAx, [0 1]);
                ylim(obj.PanelAx, [0 1]);
                
                % Add bounding box
                plot(obj.PanelAx, [0 1 1 0 0], [0 0 1 1 0], 'k-', 'LineWidth', 2);
                
                % Titles and static text
                text(obj.PanelAx, 0.5, 0.9, 'HAND STATUS', 'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
                
                % Dynamic texts
                obj.TextHL = text(obj.PanelAx, 0.1, 0.75, 'LEFT HAND: UNKNOWN', 'FontSize', 14, 'FontWeight', 'bold');
                obj.TextHR = text(obj.PanelAx, 0.1, 0.65, 'RIGHT HAND: UNKNOWN', 'FontSize', 14, 'FontWeight', 'bold');
                
                obj.TextOverall = text(obj.PanelAx, 0.1, 0.50, 'OVERALL: UNKNOWN', 'FontSize', 14, 'FontWeight', 'bold');
                obj.TextTimer = text(obj.PanelAx, 0.1, 0.35, 'TIMER: 0.00 / 1.50 s', 'FontSize', 14, 'FontWeight', 'bold');
                
                obj.TextDistraction = text(obj.PanelAx, 0.1, 0.20, 'DISTRACTION: NORMAL', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0 0.6 0]);
                obj.TextAlert = text(obj.PanelAx, 0.1, 0.10, 'ALERT: OFF', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0 0.6 0]);
            end
        end
        
        function stepImpl(obj, hl_state, hr_state, h_state, timer, state, alert, lx, ly, rx, ry)
            if coder.target('MATLAB')
                if isempty(obj.FigHandle) || ~isvalid(obj.FigHandle)
                    return;
                end
                
                % 1. Update Hand Graphics
                if hl_state == 0 % UNKNOWN
                    set(obj.LeftHandPlot, 'XData', -1, 'YData', -1);
                    set(obj.LeftHandText, 'Position', [-1, -1, 0]);
                    strHL = 'LEFT HAND: UNKNOWN';
                    colHL = [0.4 0.4 0.4];
                elseif hl_state == 1 % ON WHEEL
                    set(obj.LeftHandPlot, 'XData', lx, 'YData', ly, 'MarkerFaceColor', [0 0.8 0]);
                    set(obj.LeftHandText, 'Position', [lx, ly, 0]);
                    strHL = 'LEFT HAND: ON WHEEL';
                    colHL = [0 0.6 0];
                else % OFF WHEEL
                    set(obj.LeftHandPlot, 'XData', lx, 'YData', ly, 'MarkerFaceColor', [1 0.5 0]);
                    set(obj.LeftHandText, 'Position', [lx, ly, 0]);
                    strHL = 'LEFT HAND: OFF WHEEL';
                    colHL = [0.8 0.4 0];
                end
                
                if hr_state == 0 % UNKNOWN
                    set(obj.RightHandPlot, 'XData', -1, 'YData', -1);
                    set(obj.RightHandText, 'Position', [-1, -1, 0]);
                    strHR = 'RIGHT HAND: UNKNOWN';
                    colHR = [0.4 0.4 0.4];
                elseif hr_state == 1 % ON WHEEL
                    set(obj.RightHandPlot, 'XData', rx, 'YData', ry, 'MarkerFaceColor', [0 0.8 0]);
                    set(obj.RightHandText, 'Position', [rx, ry, 0]);
                    strHR = 'RIGHT HAND: ON WHEEL';
                    colHR = [0 0.6 0];
                else % OFF WHEEL
                    set(obj.RightHandPlot, 'XData', rx, 'YData', ry, 'MarkerFaceColor', [1 0.5 0]);
                    set(obj.RightHandText, 'Position', [rx, ry, 0]);
                    strHR = 'RIGHT HAND: OFF WHEEL';
                    colHR = [0.8 0.4 0];
                end
                
                set(obj.TextHL, 'String', strHL, 'Color', colHL);
                set(obj.TextHR, 'String', strHR, 'Color', colHR);
                
                % 2. Update Overall State
                switch h_state
                    case 3
                        strOverall = 'OVERALL: BOTH HANDS ON';
                        colOverall = [0 0.6 0];
                    case 4
                        strOverall = 'OVERALL: ONE HAND OFF';
                        colOverall = [0.8 0.4 0];
                    case 5
                        strOverall = 'OVERALL: BOTH HANDS OFF';
                        colOverall = [0.8 0.4 0];
                    case 1
                        strOverall = 'OVERALL: LEFT ONLY (R UNK)';
                        colOverall = [0 0.5 0.5];
                    case 2
                        strOverall = 'OVERALL: RIGHT ONLY (L UNK)';
                        colOverall = [0 0.5 0.5];
                    otherwise
                        strOverall = 'OVERALL: UNKNOWN';
                        colOverall = [0.4 0.4 0.4];
                end
                set(obj.TextOverall, 'String', strOverall, 'Color', colOverall);
                
                % 3. Update Timer
                set(obj.TextTimer, 'String', sprintf('TIMER: %.2f / 1.50 s', timer));
                
                % 4. Update Distraction & Alert
                if alert == 1
                    set(obj.TextDistraction, 'String', 'DISTRACTION: DISTRACTED', 'Color', [0.8 0 0]);
                    set(obj.TextAlert, 'String', 'ALERT: ON', 'Color', [0.8 0 0]);
                else
                    if timer > 0
                        set(obj.TextDistraction, 'String', 'DISTRACTION: POTENTIAL', 'Color', [0.8 0.4 0]);
                        set(obj.TextAlert, 'String', 'ALERT: OFF', 'Color', [0.4 0.4 0.4]);
                    else
                        set(obj.TextDistraction, 'String', 'DISTRACTION: NORMAL', 'Color', [0 0.6 0]);
                        set(obj.TextAlert, 'String', 'ALERT: OFF', 'Color', [0 0.6 0]);
                    end
                end
                
                drawnow limitrate;
            end
        end
        
        function resetImpl(~)
            % nothing
        end
        
        function releaseImpl(obj)
            if coder.target('MATLAB')
                if ~isempty(obj.FigHandle) && isvalid(obj.FigHandle)
                    close(obj.FigHandle);
                end
            end
        end
    end
end
