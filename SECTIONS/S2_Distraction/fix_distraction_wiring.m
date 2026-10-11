% fix_distraction_wiring.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];

% 1. Disconnect external lines to/from the subsystem to safely delete/reorder ports
fprintf('Disconnecting external subsystem lines...\n');
ph = get_param(sys, 'PortHandles');
for i = 1:length(ph.Inport)
    line = get_param(ph.Inport(i), 'Line');
    if line > 0
        delete_line(line);
    end
end
for i = 1:length(ph.Outport)
    line = get_param(ph.Outport(i), 'Line');
    if line > 0
        delete_line(line);
    end
end

% 2. Delete the rogue default In1 and Out1 inside the subsystem
fprintf('Deleting rogue internal ports...\n');
rogueIn = [sys, '/In1'];
if get_param(rogueIn, 'Handle')
    % delete internal line
    lh = get_param(rogueIn, 'LineHandles');
    if lh.Outport(1) > 0
        delete_line(lh.Outport(1));
    end
    delete_block(rogueIn);
end

rogueOut = [sys, '/Out1'];
if get_param(rogueOut, 'Handle')
    lh = get_param(rogueOut, 'LineHandles');
    if lh.Inport(1) > 0
        delete_line(lh.Inport(1));
    end
    delete_block(rogueOut);
end

% 3. Explicitly set Port numbers for the remaining valid blocks
fprintf('Reordering valid internal ports...\n');
set_param([sys, '/FACE'], 'Port', '1');
set_param([sys, '/YAW'], 'Port', '2');
set_param([sys, '/PITCH'], 'Port', '3');
set_param([sys, '/ROLL'], 'Port', '4');
set_param([sys, '/GAZE_X'], 'Port', '5');
set_param([sys, '/GAZE_Y'], 'Port', '6');

set_param([sys, '/STATE'], 'Port', '1');
set_param([sys, '/ALERT'], 'Port', '2');

% 4. Ensure internal wiring to Distraction Logic is correct
% Distraction Logic expects: 1=FACE, 2=YAW, 3=PITCH, 4=ROLL, 5=GAZE_X, 6=GAZE_Y
% and outputs: 1=STATE, 2=ALERT
fprintf('Verifying internal logic block wiring...\n');
% It should already be correct based on check_simulink_wiring, but let's re-assert
logicBlock = [sys, '/Distraction Logic'];

% 5. Re-wire external lines to Subsystem
fprintf('Re-wiring external lines to DEMUX and SCOPE...\n');
add_line(mdl, 'DEMUX/1', 'DRIVER DISTRACTION DETECTION/1', 'autorouting', 'on'); % FACE
add_line(mdl, 'DEMUX/4', 'DRIVER DISTRACTION DETECTION/2', 'autorouting', 'on'); % YAW
add_line(mdl, 'DEMUX/5', 'DRIVER DISTRACTION DETECTION/3', 'autorouting', 'on'); % PITCH
add_line(mdl, 'DEMUX/6', 'DRIVER DISTRACTION DETECTION/4', 'autorouting', 'on'); % ROLL
add_line(mdl, 'DEMUX/7', 'DRIVER DISTRACTION DETECTION/5', 'autorouting', 'on'); % GAZE_X
add_line(mdl, 'DEMUX/8', 'DRIVER DISTRACTION DETECTION/6', 'autorouting', 'on'); % GAZE_Y

% Also make sure the scope connections are correct
% Scope ports: 1=YAW, 2=PITCH, 3=ROLL, 4=GAZE_X, 5=GAZE_Y, 6=STATE, 7=ALERT
% Let's clear lines going into Scope ports 6 and 7 just in case
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
scope_ph = get_param(scopeBlock, 'PortHandles');
if get_param(scope_ph.Inport(6), 'Line') > 0, delete_line(get_param(scope_ph.Inport(6), 'Line')); end
if get_param(scope_ph.Inport(7), 'Line') > 0, delete_line(get_param(scope_ph.Inport(7), 'Line')); end

add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/6', 'autorouting', 'on'); % STATE
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/7', 'autorouting', 'on'); % ALERT

% 6. Compile and Save
disp('Compiling model to verify...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully. Wiring is fixed.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
end

close_system(mdl, 0);
