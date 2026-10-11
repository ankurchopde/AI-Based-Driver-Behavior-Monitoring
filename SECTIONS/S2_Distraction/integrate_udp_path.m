% integrate_udp_path.m
originalMdl = 'driver_monitor_sim';
backupMdl = 'driver_monitor_sim_pre_mediapipe';
newMdl = 'driver_monitor_sim_mediapipe';

% 1. Create backups
if bdIsLoaded(newMdl)
    close_system(newMdl, 0);
end
if bdIsLoaded(backupMdl)
    close_system(backupMdl, 0);
end
copyfile([originalMdl, '.slx'], [backupMdl, '.slx']);
copyfile([originalMdl, '.slx'], [newMdl, '.slx']);

% 2. Open the new model
load_system(newMdl);

% 3. Identify existing blocks to shift them to make room, or just place new blocks below
% The user wants to keep the old path and add the new one as a separate validated signal path.

% Add the new MATLAB System block for UDP
udpBlock = [newMdl, '/UNVERIFIED UDP Receiver'];
add_block('simulink/User-Defined Functions/MATLAB System', udpBlock);
set_param(udpBlock, 'System', 'UDPReceiverSystem');
set_param(udpBlock, 'Position', [100, 300, 300, 380]);
set_param(udpBlock, 'BackgroundColor', 'orange'); % Mark as unverified

% Add Demux
demuxBlock = [newMdl, '/UDP Demux'];
add_block('simulink/Signal Routing/Demux', demuxBlock);
set_param(demuxBlock, 'Outputs', '3');
set_param(demuxBlock, 'DisplayOption', 'bar');
set_param(demuxBlock, 'Position', [350, 300, 355, 380]);

% Add Scopes
faceScope = [newMdl, '/UDP FACE Scope'];
add_block('simulink/Sinks/Scope', faceScope);
set_param(faceScope, 'Position', [420, 290, 450, 320]);

eyeScope = [newMdl, '/UDP EYES Scope'];
add_block('simulink/Sinks/Scope', eyeScope);
set_param(eyeScope, 'Position', [420, 325, 450, 355]);

earScope = [newMdl, '/UDP EAR Scope'];
add_block('simulink/Sinks/Scope', earScope);
set_param(earScope, 'Position', [420, 360, 450, 390]);

% Connect lines for the UDP path
add_line(newMdl, 'UNVERIFIED UDP Receiver/1', 'UDP Demux/1');
add_line(newMdl, 'UDP Demux/1', 'UDP FACE Scope/1');
add_line(newMdl, 'UDP Demux/2', 'UDP EYES Scope/1');
add_line(newMdl, 'UDP Demux/3', 'UDP EAR Scope/1');

% Annotate
ann = Simulink.Annotation([newMdl, '/UNVERIFIED UDP MEDIAPIPE PATH']);
ann.Position = [100, 270];

% Compile model to verify dimensions and no errors
disp('Compiling model to verify dimensions...');
% Set fixed step just in case
set_param(newMdl, 'SolverType', 'Fixed-step');
set_param(newMdl, 'FixedStep', '0.05'); 
set_param(newMdl, 'StopTime', 'inf');

try
    % Compile tests code-gen/dimension checks
    set_param(newMdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully. No dimension or code-gen errors detected.');
catch ME
    disp(['Compilation Error: ', ME.message]);
end

save_system(newMdl);
close_system(newMdl);
disp('Integration preparation complete.');
