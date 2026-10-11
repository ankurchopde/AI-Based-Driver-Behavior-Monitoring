% clean_labels_v2.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% Helper to safely rename blocks
function safe_rename(mdl, oldName, newName)
    try
        set_param([mdl, '/', oldName], 'Name', newName);
    catch
    end
end

% 1. Rename Blocks to Compact Names
safe_rename(mdl, 'Native UDP Receiver', 'UDP Receive');
safe_rename(mdl, 'MediaPipe DEMUX', 'DEMUX');
safe_rename(mdl, 'BLINK', 'Blink');
safe_rename(mdl, 'BLINK_ACTIVE', 'Blink');
safe_rename(mdl, 'MICROSLEEP', 'Microsleep');
safe_rename(mdl, 'MICROSLEEP_ACTIVE', 'Microsleep');
safe_rename(mdl, 'YAWN', 'Yawn');
safe_rename(mdl, 'YAWN_ACTIVE', 'Yawn');
safe_rename(mdl, 'Drowsiness State Machine', 'State Machine');
safe_rename(mdl, 'BLINK_THRESH', 'BLINK TH');
safe_rename(mdl, 'MICROSLEEP_THRESH', 'MS TH');
safe_rename(mdl, 'YAWN_THRESH', 'YAWN TH');

% Ensure these important blocks show their names
blocks_to_show = {
    '/UDP Receive', '/DEMUX', '/EAR MA', '/MAR MA', ...
    '/Blink', '/Microsleep', '/Yawn', '/State Machine', ...
    '/EAR < 0.173', '/EAR < 0.138', '/MAR > 0.247', ...
    '/BLINK TH', '/MS TH', '/YAWN TH', '/FINAL DROWSINESS WAVEFORMS'
};

% Hide all block names first
all_blocks = find_system(mdl, 'Type', 'block');
for i = 1:length(all_blocks)
    try set_param(all_blocks{i}, 'ShowName', 'off'); catch, end
end

% Show only the requested blocks
for i = 1:length(blocks_to_show)
    try set_param([mdl, blocks_to_show{i}], 'ShowName', 'on'); catch, end
end

% 2. Clear ALL signal names
all_lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i = 1:length(all_lines)
    try set_param(all_lines(i), 'Name', ''); catch, end
end

% 3. Apply exactly the short engineering signal labels
signal_map = {
    '/DEMUX', 1, 'FACE';
    '/DEMUX', 2, 'RAW EAR';
    '/DEMUX', 3, 'RAW MAR';
    '/EAR MA', 1, 'SMOOTH EAR';
    '/MAR MA', 1, 'SMOOTH MAR';
    '/Blink', 1, 'BLINK';
    '/BLINK_EVENT', 1, 'BLINK EVT';
    '/Microsleep', 1, 'MS ACTIVE';
    '/MS_Mult', 1, 'MS DUR';
    '/Yawn', 1, 'YAWN';
    '/YAWN_EVENT', 1, 'YAWN EVT';
    '/State Machine', 1, 'STATE';
    '/State Machine', 2, 'ALERT';
};

for i = 1:size(signal_map, 1)
    try
        phs = get_param([mdl, signal_map{i, 1}], 'PortHandles');
        lineHandle = get_param(phs.Outport(signal_map{i, 2}), 'Line');
        if lineHandle ~= -1
            set_param(lineHandle, 'Name', signal_map{i, 3});
        end
    catch
    end
end

% 4. Delete existing annotations
anns = find_system(mdl, 'FindAll', 'on', 'Type', 'annotation');
for i = 1:length(anns)
    try delete(anns(i)); catch, end
end

% 5. Create new requested annotations
% Legend (Upper Left)
txt_legend = ['ABBREVIATIONS / PARAMETERS' newline newline ...
              'EAR = Eye Aspect Ratio' newline ...
              'MAR = Mouth Aspect Ratio' newline ...
              'MS = Microsleep' newline ...
              'MA = Moving Average' newline ...
              'EVT = Event' newline newline ...
              'Parameters:' newline ...
              'Blink EAR threshold = 0.173' newline ...
              'Microsleep EAR threshold = 0.138' newline ...
              'Yawn MAR threshold = 0.247' newline ...
              'Microsleep duration = 2 s' newline ...
              'Smoothing window = 10 samples'];
add_block('built-in/Note', [mdl, '/LegendNote']);
set_param([mdl, '/LegendNote'], 'Text', txt_legend, 'Position', [50, 20, 250, 150], 'HorizontalAlignment', 'left');

% State Legend
txt_state = ['STATE:' newline '0 = NORMAL' newline '1 = WARNING' newline '2 = DROWSY' newline '3 = NO FACE'];
add_block('built-in/Note', [mdl, '/StateNote']);
set_param([mdl, '/StateNote'], 'Text', txt_state, 'Position', [1050, 80, 1200, 150], 'HorizontalAlignment', 'left');

% Important Notes
txt_notes1 = 'Prototype — thresholds not formally calibrated';
add_block('built-in/Note', [mdl, '/WarnNote1']);
set_param([mdl, '/WarnNote1'], 'Text', txt_notes1, 'Position', [50, 360, 300, 380], 'HorizontalAlignment', 'left');

txt_notes2 = 'Real-time timing to be verified on Raspberry Pi';
add_block('built-in/Note', [mdl, '/WarnNote2']);
set_param([mdl, '/WarnNote2'], 'Text', txt_notes2, 'Position', [50, 390, 300, 410], 'HorizontalAlignment', 'left');

% Compile & Save
set_param(mdl, 'SimulationCommand', 'update');
disp('Label and formatting cleanup completed. Model updated successfully.');
save_system(mdl);
close_system(mdl);
