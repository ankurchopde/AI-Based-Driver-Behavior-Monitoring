% cleanup_simulink.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
load_system(mdl);

% 1. DELETE old/duplicate unconnected scopes to free up the names
try delete_block([mdl, '/FACE Scope']); catch, end
try delete_block([mdl, '/EYES Scope']); catch, end
try delete_block([mdl, '/EAR Scope']); catch, end
try delete_block([mdl, '/EAR Scope1']); catch, end

% 2. RENAME the valid MediaPipe blocks to the clean names requested
try set_param([mdl, '/MediaPipe FACE Scope'], 'Name', 'FACE Scope'); catch, end
try set_param([mdl, '/MediaPipe EYES Scope'], 'Name', 'EYES Scope'); catch, end
try set_param([mdl, '/MediaPipe EAR Scope'], 'Name', 'EAR Scope'); catch, end
try set_param([mdl, '/MediaPipe Demux'], 'Name', 'MediaPipe DEMUX'); catch, end

% 3. DELETE all existing lines so we can explicitly route them perfectly straight
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i = 1:length(lines)
    try delete_line(lines(i)); catch, end
end

% 4. LAYOUT / SPACING (Clean, orthogonal spacing)
udpBlock = [mdl, '/Native UDP Receiver'];
set_param(udpBlock, 'Position', [100, 150, 250, 230]);

termBlock = [mdl, '/UDP Status Terminator'];
set_param(termBlock, 'Position', [280, 205, 300, 225]);

demuxBlock = [mdl, '/MediaPipe DEMUX'];
% Demux needs to be tall enough to spread the 3 lines out cleanly
set_param(demuxBlock, 'Position', [330, 140, 335, 200]);

% Scopes perfectly aligned on X=420, spaced out vertically
set_param([mdl, '/FACE Scope'], 'Position', [420, 135, 450, 165]);
set_param([mdl, '/EYES Scope'], 'Position', [420, 195, 450, 225]);
set_param([mdl, '/EAR Scope'], 'Position', [420, 255, 450, 285]);

% 5. RECONNECT perfectly
add_line(mdl, 'Native UDP Receiver/1', 'MediaPipe DEMUX/1', 'autorouting', 'on');
add_line(mdl, 'Native UDP Receiver/2', 'UDP Status Terminator/1', 'autorouting', 'on');
add_line(mdl, 'MediaPipe DEMUX/1', 'FACE Scope/1', 'autorouting', 'on');
add_line(mdl, 'MediaPipe DEMUX/2', 'EYES Scope/1', 'autorouting', 'on');
add_line(mdl, 'MediaPipe DEMUX/3', 'EAR Scope/1', 'autorouting', 'on');

% 6. VERIFY compilation
set_param(mdl, 'SimulationCommand', 'update');
disp('Model cleaned, arranged, compiled and verified successfully!');

save_system(mdl);
close_system(mdl);
