% fix_messy_labels.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Strip ALL signal names from the actual wires to stop branch duplication
all_lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i = 1:length(all_lines)
    try set_param(all_lines(i), 'Name', ''); catch, end
end

% 2. Delete old floating signal annotations if any
anns = find_system(mdl, 'FindAll', 'on', 'Type', 'annotation');
for i = 1:length(anns)
    txt = get_param(anns(i), 'Text');
    % Don't delete the legends we just made!
    if ~contains(txt, 'PARAMETERS') && ~contains(txt, 'STATE:') && ~contains(txt, 'Prototype') && ~contains(txt, 'Raspberry Pi')
        try delete(anns(i)); catch, end
    end
end

% 3. Create precise floating annotations for the signal names
function create_sig_label(mdl, text, pos)
    % pos is [x, y]
    % Generate a unique ID to avoid naming collisions
    uid = char(randi([97 122], 1, 8)); 
    ann = add_block('built-in/Note', [mdl, '/', text, '_', uid]);
    set_param(ann, 'Text', text, 'Position', [pos(1), pos(2), pos(1)+80, pos(2)+15], 'DropShadow', 'off', 'HorizontalAlignment', 'center');
end

% Place labels manually near the output of their respective blocks
% DEMUX Outputs
create_sig_label(mdl, 'FACE', [220, 190]);
create_sig_label(mdl, 'RAW EAR', [220, 220]);
create_sig_label(mdl, 'RAW MAR', [220, 250]);

% MAs
create_sig_label(mdl, 'SMOOTH EAR', [370, 155]);
create_sig_label(mdl, 'SMOOTH MAR', [370, 355]);

% Blink
create_sig_label(mdl, 'BLINK', [640, 100]);
create_sig_label(mdl, 'BLINK EVT', [800, 110]);

% Microsleep
create_sig_label(mdl, 'MS ACTIVE', [640, 200]);
create_sig_label(mdl, 'MS DUR', [900, 260]);

% Yawn
create_sig_label(mdl, 'YAWN', [640, 380]);
create_sig_label(mdl, 'YAWN EVT', [810, 390]);

% State / Alert
create_sig_label(mdl, 'STATE', [1190, 210]);
create_sig_label(mdl, 'ALERT', [1190, 300]);

% 4. Fix any broken Scope wires (like the red dashed line)
% We'll safely delete all lines entering the scope and strictly re-route them
scopeName = [mdl, '/FINAL DROWSINESS WAVEFORMS'];
scopePhs = get_param(scopeName, 'PortHandles');
for i = 1:9
    line = get_param(scopePhs.Inport(i), 'Line');
    if line ~= -1
        try delete_line(line); catch, end
    end
end

% Re-wire directly to the Scope ports
add_line(mdl, 'DEMUX/2', 'FINAL DROWSINESS WAVEFORMS/1', 'autorouting', 'on');
add_line(mdl, 'EAR MA/1', 'FINAL DROWSINESS WAVEFORMS/2', 'autorouting', 'on');
add_line(mdl, 'DEMUX/3', 'FINAL DROWSINESS WAVEFORMS/3', 'autorouting', 'on');
add_line(mdl, 'MAR MA/1', 'FINAL DROWSINESS WAVEFORMS/4', 'autorouting', 'on');
% The block is actually BLINK_EVENT.
add_line(mdl, 'BLINK_EVENT/1', 'FINAL DROWSINESS WAVEFORMS/5', 'autorouting', 'on');
add_line(mdl, 'MS_Mult/1', 'FINAL DROWSINESS WAVEFORMS/6', 'autorouting', 'on');
add_line(mdl, 'Yawn/1', 'FINAL DROWSINESS WAVEFORMS/7', 'autorouting', 'on');
add_line(mdl, 'State Machine/1', 'FINAL DROWSINESS WAVEFORMS/8', 'autorouting', 'on');
add_line(mdl, 'State Machine/2', 'FINAL DROWSINESS WAVEFORMS/9', 'autorouting', 'on');

% Note: We renamed BLINK_ACTIVE to Blink, MICROSLEEP_ACTIVE to Microsleep, YAWN_ACTIVE to Yawn.
% But BLINK_EVENT was NOT in the rename list. So it's still BLINK_EVENT.

% 5. Apply Smart Auto-Routing to clean up the newly drawn lines
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i=1:length(lines)
    try set_param(lines(i), 'autorouting', 'smart'); catch, end
end

% 6. Compile Model
set_param(mdl, 'SimulationCommand', 'update');
disp('Labels replaced with clean floating annotations. Wires re-routed successfully!');
save_system(mdl);
close_system(mdl);
