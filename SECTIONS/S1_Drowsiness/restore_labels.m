% restore_labels.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% Mappings of Source Port -> Signal Name
labels = {
    'MediaPipe DEMUX/1', 'FACE DETECTED';
    'MediaPipe DEMUX/2', 'RAW EAR';
    'MediaPipe DEMUX/3', 'RAW MAR';
    'EAR MA/1', 'SMOOTHED EAR';
    'EAR < 0.173/1', 'EAR < 0.173';
    'BLINK_ACTIVE/1', 'BLINK ACTIVE';
    'Detect Blink End/1', 'DETECT BLINK END';
    'BLINK_EVENT/1', 'BLINK EVENT';
    'EAR < 0.138/1', 'EAR < 0.138';
    'MICROSLEEP_ACTIVE/1', 'MICROSLEEP ACTIVE';
    'MS_Mult/1', 'MICROSLEEP DURATION';
    'MAR MA/1', 'SMOOTHED MAR';
    'MAR > 0.247/1', 'MAR > 0.247';
    'YAWN_ACTIVE/1', 'YAWN ACTIVE';
    'YAWN_EVENT/1', 'YAWN EVENT';
    'Drowsiness State Machine/1', 'DROWSINESS STATE';
    'Drowsiness State Machine/2', 'DROWSINESS ALERT';
};

for i = 1:size(labels, 1)
    portStr = [mdl, '/', labels{i, 1}];
    try
        % Find the line connected to this port
        portHandle = get_param(portStr, 'Object');
        lineHandle = portHandle.Line;
        
        if lineHandle ~= -1
            % Set the signal name
            set_param(lineHandle, 'Name', labels{i, 2});
        end
    catch ME
        disp(['Could not label ', labels{i, 1}, ': ', ME.message]);
    end
end

% Ensure block names for important comparators are visible
blocks_to_show = {
    '/EAR < 0.173', '/EAR < 0.138', '/MAR > 0.247', ...
    '/BLINK_ACTIVE', '/MICROSLEEP_ACTIVE', '/YAWN_ACTIVE', ...
    '/Drowsiness State Machine', '/FINAL DROWSINESS WAVEFORMS'
};

for i = 1:length(blocks_to_show)
    try
        set_param([mdl, blocks_to_show{i}], 'ShowName', 'on');
    catch
    end
end

% Verify Compilation without touching layout/routing
set_param(mdl, 'SimulationCommand', 'update');
disp('Labels restored. Model compiled successfully.');
save_system(mdl);
close_system(mdl);
