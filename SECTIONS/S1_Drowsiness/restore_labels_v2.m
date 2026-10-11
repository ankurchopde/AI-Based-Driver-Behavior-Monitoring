% restore_labels_v2.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% Mappings of Block Name -> Output Port Index -> Signal Name
labels = {
    '/MediaPipe DEMUX', 1, 'FACE DETECTED';
    '/MediaPipe DEMUX', 2, 'RAW EAR';
    '/MediaPipe DEMUX', 3, 'RAW MAR';
    '/EAR MA', 1, 'SMOOTHED EAR';
    '/EAR < 0.173', 1, 'EAR < 0.173';
    '/BLINK_ACTIVE', 1, 'BLINK ACTIVE';
    '/Detect Blink End', 1, 'DETECT BLINK END';
    '/BLINK_EVENT', 1, 'BLINK EVENT';
    '/EAR < 0.138', 1, 'EAR < 0.138';
    '/MICROSLEEP_ACTIVE', 1, 'MICROSLEEP ACTIVE';
    '/MS_Mult', 1, 'MICROSLEEP DURATION';
    '/MAR MA', 1, 'SMOOTHED MAR';
    '/MAR > 0.247', 1, 'MAR > 0.247';
    '/YAWN_ACTIVE', 1, 'YAWN ACTIVE';
    '/YAWN_EVENT', 1, 'YAWN EVENT';
    '/Drowsiness State Machine', 1, 'DROWSINESS STATE';
    '/Drowsiness State Machine', 2, 'DROWSINESS ALERT';
};

for i = 1:size(labels, 1)
    blockPath = [mdl, labels{i, 1}];
    portIdx = labels{i, 2};
    sigName = labels{i, 3};
    try
        phs = get_param(blockPath, 'PortHandles');
        lineHandle = get_param(phs.Outport(portIdx), 'Line');
        
        if lineHandle ~= -1
            set_param(lineHandle, 'Name', sigName);
        end
    catch ME
        disp(['Could not label ', blockPath, ' port ', num2str(portIdx), ': ', ME.message]);
    end
end

% Verify Compilation
set_param(mdl, 'SimulationCommand', 'update');
disp('Labels successfully restored via PortHandles. Model compiled successfully.');
save_system(mdl);
close_system(mdl);
