% build_distraction_sim.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. Update UDP Receiver to 6 values
udpBlock = [mdl, '/UDP Receive'];
set_param(udpBlock, 'dims', '[6]');

% 2. Update Demux to 6 outputs
demuxBlock = [mdl, '/DEMUX'];
set_param(demuxBlock, 'Outputs', '6');

% 3. Create a Subsystem for Distraction
distractSys = [mdl, '/DRIVER DISTRACTION DETECTION'];
add_block('simulink/Ports & Subsystems/Subsystem', distractSys);
set_param(distractSys, 'Position', [400, 500, 550, 650]);
set_param(distractSys, 'BackgroundColor', 'cyan');

% Add Inports and Outports to Subsystem
add_block('simulink/Sources/In1', [distractSys, '/FACE']);
set_param([distractSys, '/FACE'], 'Position', [20, 40, 50, 55]);
add_block('simulink/Sources/In1', [distractSys, '/YAW']);
set_param([distractSys, '/YAW'], 'Position', [20, 100, 50, 115]);
add_block('simulink/Sources/In1', [distractSys, '/PITCH']);
set_param([distractSys, '/PITCH'], 'Position', [20, 160, 50, 175]);
add_block('simulink/Sources/In1', [distractSys, '/ROLL']);
set_param([distractSys, '/ROLL'], 'Position', [20, 220, 50, 235]);

add_block('simulink/Sinks/Out1', [distractSys, '/STATE']);
set_param([distractSys, '/STATE'], 'Position', [400, 100, 430, 115]);
add_block('simulink/Sinks/Out1', [distractSys, '/ALERT']);
set_param([distractSys, '/ALERT'], 'Position', [400, 160, 430, 175]);

% Add Distraction Logic System block
logicBlock = [distractSys, '/Distraction Logic'];
add_block('simulink/User-Defined Functions/MATLAB System', logicBlock);
set_param(logicBlock, 'System', 'DistractionLogicSystem');
set_param(logicBlock, 'Position', [150, 100, 300, 175]);

% Connect inside Subsystem
add_line(distractSys, 'FACE/1', 'Distraction Logic/1');
add_line(distractSys, 'YAW/1', 'Distraction Logic/2');
add_line(distractSys, 'PITCH/1', 'Distraction Logic/3');
add_line(distractSys, 'ROLL/1', 'Distraction Logic/4');

add_line(distractSys, 'Distraction Logic/1', 'STATE/1');
add_line(distractSys, 'Distraction Logic/2', 'ALERT/1');

% 4. Connect Demux to Distraction Subsystem
add_line(mdl, 'DEMUX/1', 'DRIVER DISTRACTION DETECTION/1', 'autorouting', 'on');
add_line(mdl, 'DEMUX/4', 'DRIVER DISTRACTION DETECTION/2', 'autorouting', 'on');
add_line(mdl, 'DEMUX/5', 'DRIVER DISTRACTION DETECTION/3', 'autorouting', 'on');
add_line(mdl, 'DEMUX/6', 'DRIVER DISTRACTION DETECTION/4', 'autorouting', 'on');

% 5. Add Scope for Distraction Waveforms
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
add_block('simulink/Sinks/Scope', scopeBlock);
set_param(scopeBlock, 'Position', [650, 500, 700, 600]);
set_param(scopeBlock, 'NumInputPorts', '5');
set_param(scopeBlock, 'Title', 'YAW|PITCH|ROLL|STATE|ALERT');

% Connect Scope
add_line(mdl, 'DEMUX/4', 'FINAL DISTRACTION WAVEFORMS/1', 'autorouting', 'on');
add_line(mdl, 'DEMUX/5', 'FINAL DISTRACTION WAVEFORMS/2', 'autorouting', 'on');
add_line(mdl, 'DEMUX/6', 'FINAL DISTRACTION WAVEFORMS/3', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/4', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/5', 'autorouting', 'on');

% Annotate Parameters
ann = Simulink.Annotation([mdl, '/CANDIDATE PARAMETERS' newline 'NOT FORMALLY CALIBRATED' newline 'YAW THRESHOLD = 20' newline 'PITCH THRESHOLD = 20' newline 'ROLL THRESHOLD = 20' newline 'DISTRACTION DURATION = 1.5 s']);
ann.Position = [400, 420];

% 6. Compile to test
disp('Compiling model to verify dimensions...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully. No dimension or code-gen errors detected.');
catch ME
    disp(['Compilation Error: ', ME.message]);
end

close_system(mdl, 1);
disp('Integration complete.');
