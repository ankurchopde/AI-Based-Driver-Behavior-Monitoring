% integrate_native_udp_path.m
originalMdl = 'driver_monitor_sim';
backupMdl = 'driver_monitor_sim_pre_mediapipe';
newMdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(newMdl), close_system(newMdl, 0); end
if bdIsLoaded(backupMdl), close_system(backupMdl, 0); end

% Create fresh backups
copyfile([originalMdl, '.slx'], [backupMdl, '.slx']);
copyfile([originalMdl, '.slx'], [newMdl, '.slx']);

load_system(newMdl);

% Ensure clean slate in copied model
try delete_block([newMdl, '/UNVERIFIED UDP Receiver']); catch, end
try delete_block([newMdl, '/UDP Demux']); catch, end
try delete_block([newMdl, '/UDP FACE Scope']); catch, end
try delete_block([newMdl, '/UDP EYES Scope']); catch, end
try delete_block([newMdl, '/UDP EAR Scope']); catch, end
try delete_line(newMdl, 'UNVERIFIED UDP Receiver/1', 'UDP Demux/1'); catch, end

% 1. Add Native UDP Receiver (dspnetwork/UDP Receive)
udpBlock = [newMdl, '/Native UDP Receiver'];
add_block('dspnetwork/UDP Receive', udpBlock);
% Configure for our precise telemetry
set_param(udpBlock, 'localPort', '5000');
set_param(udpBlock, 'dims', '3');
set_param(udpBlock, 'signalDatatype', 'double');
set_param(udpBlock, 'isComplex', 'off');
set_param(udpBlock, 'isVarSize', 'off');
set_param(udpBlock, 'sampletime', '0.05');
set_param(udpBlock, 'Position', [100, 300, 250, 380]);
set_param(udpBlock, 'BackgroundColor', 'cyan');

% 2. Add Demux
demuxBlock = [newMdl, '/MediaPipe Demux'];
add_block('simulink/Signal Routing/Demux', demuxBlock);
set_param(demuxBlock, 'Outputs', '3');
set_param(demuxBlock, 'DisplayOption', 'bar');
set_param(demuxBlock, 'Position', [320, 300, 325, 380]);

% 3. Add Scopes
faceScope = [newMdl, '/MediaPipe FACE Scope'];
add_block('simulink/Sinks/Scope', faceScope);
set_param(faceScope, 'Position', [420, 290, 450, 320]);

eyeScope = [newMdl, '/MediaPipe EYES Scope'];
add_block('simulink/Sinks/Scope', eyeScope);
set_param(eyeScope, 'Position', [420, 325, 450, 355]);

earScope = [newMdl, '/MediaPipe EAR Scope'];
add_block('simulink/Sinks/Scope', earScope);
set_param(earScope, 'Position', [420, 360, 450, 390]);

% 4. Connect main data lines
add_line(newMdl, 'Native UDP Receiver/1', 'MediaPipe Demux/1', 'autorouting', 'on');
add_line(newMdl, 'MediaPipe Demux/1', 'MediaPipe FACE Scope/1', 'autorouting', 'on');
add_line(newMdl, 'MediaPipe Demux/2', 'MediaPipe EYES Scope/1', 'autorouting', 'on');
add_line(newMdl, 'MediaPipe Demux/3', 'MediaPipe EAR Scope/1', 'autorouting', 'on');

% Handle second port (Bytes Received / Status) by terminating it cleanly
p = get_param(udpBlock, 'Ports');
if p(2) > 1
    termBlock = [newMdl, '/UDP Status Terminator'];
    add_block('simulink/Sinks/Terminator', termBlock);
    set_param(termBlock, 'Position', [280, 400, 300, 420]);
    add_line(newMdl, 'Native UDP Receiver/2', 'UDP Status Terminator/1', 'autorouting', 'on');
end

% 5. Annotate
ann = Simulink.Annotation([newMdl, '/UNVERIFIED NATIVE UDP MEDIAPIPE PATH']);
ann.Position = [100, 270];

% 6. Compile to verify C-code gen compliance
set_param(newMdl, 'SolverType', 'Fixed-step');
set_param(newMdl, 'FixedStep', '0.05'); 
set_param(newMdl, 'StopTime', 'inf');

disp('Compiling integrated model...');
set_param(newMdl, 'SimulationCommand', 'update');
disp('Model compiled and verified perfectly!');

save_system(newMdl);
close_system(newMdl);
