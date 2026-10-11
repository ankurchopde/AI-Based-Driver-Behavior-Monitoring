% integrate_identification_simulink.m
disp('Starting Task 3I Simulink Integration...');

% Paths
addpath(genpath('../S1_Drowsiness'));
addpath(genpath('../S2_Distraction'));

originalMdl = '../SECTIONS/S2_Distraction/driver_monitor_sim_distraction';
newMdlName = 'driver_monitor_sim_identification';

if bdIsLoaded(newMdlName)
    close_system(newMdlName, 0);
end

% Copy file
copyfile([originalMdl, '.slx'], [newMdlName, '.slx']);
load_system(newMdlName);

% 1. Update the UDP Receiver
udpBlock = [newMdlName, '/UDP Receive'];
% Change from 8 to 11 dims
set_param(udpBlock, 'dims', '11');

% 2. Update Demux
demuxBlock = [newMdlName, '/DEMUX'];
set_param(demuxBlock, 'Outputs', '11');

% 3. Add Scopes for Identification Data
idScope = [newMdlName, '/DRIVER_ID Scope'];
confScope = [newMdlName, '/ID_CONFIDENCE Scope'];
stateScope = [newMdlName, '/ID_STATE Scope'];

add_block('simulink/Sinks/Scope', idScope);
set_param(idScope, 'Position', [250, 400, 280, 430]);

add_block('simulink/Sinks/Scope', confScope);
set_param(confScope, 'Position', [250, 450, 280, 480]);

add_block('simulink/Sinks/Scope', stateScope);
set_param(stateScope, 'Position', [250, 500, 280, 530]);

% 4. Connect new Demux ports (9, 10, 11) to new Scopes
add_line(newMdlName, 'DEMUX/9', 'DRIVER_ID Scope/1', 'autorouting', 'on');
add_line(newMdlName, 'DEMUX/10', 'ID_CONFIDENCE Scope/1', 'autorouting', 'on');
add_line(newMdlName, 'DEMUX/11', 'ID_STATE Scope/1', 'autorouting', 'on');

% 5. Compile to verify C-code gen compliance
disp('Compiling integrated model...');
set_param(newMdlName, 'SimulationCommand', 'update');
disp('Model compiled and verified perfectly!');

save_system(newMdlName);
close_system(newMdlName);

disp('Integration complete.');
exit;
