% update_distraction_sim_gaze.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. Update UDP Receiver to 8 values
udpBlock = [mdl, '/UDP Receive'];
set_param(udpBlock, 'dims', '[8]');

% 2. Update Demux to 8 outputs
demuxBlock = [mdl, '/DEMUX'];
set_param(demuxBlock, 'Outputs', '8');

% 3. Update Subsystem for Distraction
distractSys = [mdl, '/DRIVER DISTRACTION DETECTION'];

% Add GAZE_X and GAZE_Y ports
add_block('simulink/Sources/In1', [distractSys, '/GAZE_X']);
set_param([distractSys, '/GAZE_X'], 'Position', [20, 280, 50, 295]);
add_block('simulink/Sources/In1', [distractSys, '/GAZE_Y']);
set_param([distractSys, '/GAZE_Y'], 'Position', [20, 340, 50, 355]);

% Disconnect old lines first so we can reconnect safely if needed
logicBlock = [distractSys, '/Distraction Logic'];

% MATLAB System blocks automatically update their ports if the underlying class definition changes,
% but we might need to refresh it.
% We can just reconnect them all explicitly.
delete_line(distractSys, 'FACE/1', 'Distraction Logic/1');
delete_line(distractSys, 'YAW/1', 'Distraction Logic/2');
delete_line(distractSys, 'PITCH/1', 'Distraction Logic/3');
delete_line(distractSys, 'ROLL/1', 'Distraction Logic/4');

add_line(distractSys, 'FACE/1', 'Distraction Logic/1');
add_line(distractSys, 'YAW/1', 'Distraction Logic/2');
add_line(distractSys, 'PITCH/1', 'Distraction Logic/3');
add_line(distractSys, 'ROLL/1', 'Distraction Logic/4');
add_line(distractSys, 'GAZE_X/1', 'Distraction Logic/5');
add_line(distractSys, 'GAZE_Y/1', 'Distraction Logic/6');

% Connect Demux to new inputs in the root system
% Demux outputs: 1=FACE, 2=EAR, 3=MAR, 4=YAW, 5=PITCH, 6=ROLL, 7=GAZE_X, 8=GAZE_Y
% DRIVER DISTRACTION DETECTION subsystem inputs:
% 1=FACE, 2=YAW, 3=PITCH, 4=ROLL, 5=GAZE_X, 6=GAZE_Y
add_line(mdl, 'DEMUX/7', 'DRIVER DISTRACTION DETECTION/5', 'autorouting', 'on');
add_line(mdl, 'DEMUX/8', 'DRIVER DISTRACTION DETECTION/6', 'autorouting', 'on');

% 5. Update Scope
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
% Let's change scope to show 7 signals instead of 5, to see GAZE_X and GAZE_Y too.
set_param(scopeBlock, 'NumInputPorts', '7');
set_param(scopeBlock, 'Title', 'YAW|PITCH|ROLL|GAZE_X|GAZE_Y|STATE|ALERT');

% Re-wire scope. Previously ports 1=YAW, 2=PITCH, 3=ROLL, 4=STATE, 5=ALERT
delete_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/4');
delete_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/5');

add_line(mdl, 'DEMUX/7', 'FINAL DISTRACTION WAVEFORMS/4', 'autorouting', 'on');
add_line(mdl, 'DEMUX/8', 'FINAL DISTRACTION WAVEFORMS/5', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/6', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/7', 'autorouting', 'on');

% Compile to test
disp('Compiling model to verify dimensions...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
end

close_system(mdl, 0);
disp('Integration complete.');
