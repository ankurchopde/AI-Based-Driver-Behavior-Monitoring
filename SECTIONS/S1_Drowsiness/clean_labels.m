% clean_labels.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Hide all block names except the important ones
all_blocks = find_system(mdl, 'Type', 'block');
for i = 1:length(all_blocks)
    try set_param(all_blocks{i}, 'ShowName', 'off'); catch, end
end

important_blocks = {
    '/EAR MA', ...
    '/MAR MA', ...
    '/EAR < 0.173', ...
    '/EAR < 0.138', ...
    '/MAR > 0.247', ...
    '/FINAL DROWSINESS WAVEFORMS'
};

for i = 1:length(important_blocks)
    try set_param([mdl, important_blocks{i}], 'ShowName', 'on'); catch, end
end

% Rename the active logic blocks to short labels and show them
try set_param([mdl, '/BLINK_ACTIVE'], 'Name', 'BLINK'); catch, end
try set_param([mdl, '/MICROSLEEP_ACTIVE'], 'Name', 'MICROSLEEP'); catch, end
try set_param([mdl, '/YAWN_ACTIVE'], 'Name', 'YAWN'); catch, end
try set_param([mdl, '/BLINK'], 'ShowName', 'on'); catch, end
try set_param([mdl, '/MICROSLEEP'], 'ShowName', 'on'); catch, end
try set_param([mdl, '/YAWN'], 'ShowName', 'on'); catch, end

% 2. Clear ALL signal names to start fresh
all_lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i = 1:length(all_lines)
    try set_param(all_lines(i), 'Name', ''); catch, end
end

% 3. Apply exact short engineering signal labels via PortHandles
labels = {
    '/MediaPipe DEMUX', 1, 'FACE';
    '/MediaPipe DEMUX', 2, 'RAW EAR';
    '/MediaPipe DEMUX', 3, 'RAW MAR';
    '/BLINK_EVENT', 1, 'BLINK EVENT';
    '/MS_Mult', 1, 'MS DURATION';
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
    catch
    end
end

% 4. Delete existing annotations
anns = find_system(mdl, 'FindAll', 'on', 'Type', 'annotation');
for i = 1:length(anns)
    try delete(anns(i)); catch, end
end

% 5. Create clean annotations
% Parameters (Upper Left)
ann1 = Simulink.Annotation([mdl, '/PARAMETERS' newline 'EAR blink threshold = 0.173' newline 'EAR microsleep threshold = 0.138' newline 'MAR yawn threshold = 0.247' newline 'Microsleep duration = 2 s' newline 'Smoothing window = 10 samples']);
ann1.Position = [50, 20];
ann1.HorizontalAlignment = 'left';

% Warnings (Below Parameters)
ann2 = Simulink.Annotation([mdl, '/Prototype — thresholds not formally calibrated' newline 'Real-time timing to be verified on Raspberry Pi']);
ann2.Position = [50, 110];
ann2.HorizontalAlignment = 'left';

% Abbreviations (Bottom Left/Center)
ann3 = Simulink.Annotation([mdl, '/ABBREVIATIONS' newline 'EAR = Eye Aspect Ratio' newline 'MAR = Mouth Aspect Ratio' newline 'MS = Microsleep' newline 'MA = Moving Average']);
ann3.Position = [400, 500];
ann3.HorizontalAlignment = 'left';

% State Legend (Far Right near State Block)
ann4 = Simulink.Annotation([mdl, '/STATE:' newline '0 = NORMAL' newline '1 = WARNING' newline '2 = DROWSY' newline '3 = NO_FACE']);
ann4.Position = [1050, 100];
ann4.HorizontalAlignment = 'left';

% Compile & Save
set_param(mdl, 'SimulationCommand', 'update');
disp('Label cleanup completed. Model updated.');
save_system(mdl);
close_system(mdl);
