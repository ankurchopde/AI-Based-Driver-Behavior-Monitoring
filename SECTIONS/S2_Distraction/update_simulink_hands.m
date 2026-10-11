% update_simulink_hands.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. DEMUX -> 10 outputs
demuxBlock = [mdl, '/DEMUX'];
set_param(demuxBlock, 'Outputs', '10');

% 2. Subsystem Inports
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];
% Check if HAND_LEFT and HAND_RIGHT exist
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'HAND_LEFT'))
    add_block('simulink/Sources/In1', [sys, '/HAND_LEFT']);
    set_param([sys, '/HAND_LEFT'], 'Port', '7');
end
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'HAND_RIGHT'))
    add_block('simulink/Sources/In1', [sys, '/HAND_RIGHT']);
    set_param([sys, '/HAND_RIGHT'], 'Port', '8');
end

% 3. Subsystem Outports
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'HL_OUT'))
    add_block('simulink/Sinks/Out1', [sys, '/HL_OUT']);
    set_param([sys, '/HL_OUT'], 'Port', '3');
end
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'HR_OUT'))
    add_block('simulink/Sinks/Out1', [sys, '/HR_OUT']);
    set_param([sys, '/HR_OUT'], 'Port', '4');
end
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'H_STATE'))
    add_block('simulink/Sinks/Out1', [sys, '/H_STATE']);
    set_param([sys, '/H_STATE'], 'Port', '5');
end

% 4. Re-wire internal logic
% Clear all internal lines from/to the Logic Block
logicBlock = [sys, '/Distraction Logic'];
lh = get_param(logicBlock, 'LineHandles');
for i=1:length(lh.Inport), if lh.Inport(i) > 0, delete_line(lh.Inport(i)); end; end
for i=1:length(lh.Outport), if lh.Outport(i) > 0, delete_line(lh.Outport(i)); end; end

add_line(sys, 'FACE/1', 'Distraction Logic/1', 'autorouting', 'on');
add_line(sys, 'YAW/1', 'Distraction Logic/2', 'autorouting', 'on');
add_line(sys, 'PITCH/1', 'Distraction Logic/3', 'autorouting', 'on');
add_line(sys, 'ROLL/1', 'Distraction Logic/4', 'autorouting', 'on');
add_line(sys, 'GAZE_X/1', 'Distraction Logic/5', 'autorouting', 'on');
add_line(sys, 'GAZE_Y/1', 'Distraction Logic/6', 'autorouting', 'on');
add_line(sys, 'HAND_LEFT/1', 'Distraction Logic/7', 'autorouting', 'on');
add_line(sys, 'HAND_RIGHT/1', 'Distraction Logic/8', 'autorouting', 'on');

add_line(sys, 'Distraction Logic/1', 'STATE/1', 'autorouting', 'on');
add_line(sys, 'Distraction Logic/2', 'ALERT/1', 'autorouting', 'on');
add_line(sys, 'Distraction Logic/3', 'HL_OUT/1', 'autorouting', 'on');
add_line(sys, 'Distraction Logic/4', 'HR_OUT/1', 'autorouting', 'on');
add_line(sys, 'Distraction Logic/5', 'H_STATE/1', 'autorouting', 'on');

% 5. Wire DEMUX to Subsystem
% Clear Demux 9 and 10 lines if they exist
ph = get_param(demuxBlock, 'PortHandles');
if get_param(ph.Outport(9), 'Line') > 0, delete_line(get_param(ph.Outport(9), 'Line')); end
if get_param(ph.Outport(10), 'Line') > 0, delete_line(get_param(ph.Outport(10), 'Line')); end

add_line(mdl, 'DEMUX/9', 'DRIVER DISTRACTION DETECTION/7', 'autorouting', 'on');
add_line(mdl, 'DEMUX/10', 'DRIVER DISTRACTION DETECTION/8', 'autorouting', 'on');

% Name Demux ports
set_param(ph.Outport(9), 'Name', 'HAND_LEFT');
set_param(ph.Outport(10), 'Name', 'HAND_RIGHT');

% Name Subsystem Outports
sys_ph = get_param(sys, 'PortHandles');
set_param(sys_ph.Outport(3), 'Name', 'HAND_LEFT_ON_WHEEL');
set_param(sys_ph.Outport(4), 'Name', 'HAND_RIGHT_ON_WHEEL');
set_param(sys_ph.Outport(5), 'Name', 'HANDS_ON_WHEEL_STATE');

% 6. Scope setup
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
% Clear lines to scope ports 6 and 7 to shift them down
s_ph = get_param(scopeBlock, 'PortHandles');
if get_param(s_ph.Inport(6), 'Line') > 0, delete_line(get_param(s_ph.Inport(6), 'Line')); end
if get_param(s_ph.Inport(7), 'Line') > 0, delete_line(get_param(s_ph.Inport(7), 'Line')); end

set_param(scopeBlock, 'NumInputPorts', '10');
try
    scopeConfig = get_param(scopeBlock, 'ScopeConfiguration');
    scopeConfig.LayoutDimensions = [10 1];
    scopeConfig.DisplayTitles = {'YAW (deg)', 'PITCH (deg)', 'ROLL (deg)', 'GAZE_X', 'GAZE_Y', ...
        'HAND_LEFT_ON_WHEEL', 'HAND_RIGHT_ON_WHEEL', 'HANDS_ON_WHEEL_STATE', ...
        'DISTRACTION STATE', 'DISTRACTION ALERT'};
    scopeConfig.YLimits = [-90 90; -90 90; -90 90; -1 1; -1 1; -1.1 1.1; -1.1 1.1; 0 6; 0 11; -0.1 1.1];
catch
    try set_param(scopeBlock, 'LayoutDimensions', '[10 1]'); catch, end
end

% Re-wire everything to Scope
add_line(mdl, 'DRIVER DISTRACTION DETECTION/3', 'FINAL DISTRACTION WAVEFORMS/6', 'autorouting', 'on'); % HL
add_line(mdl, 'DRIVER DISTRACTION DETECTION/4', 'FINAL DISTRACTION WAVEFORMS/7', 'autorouting', 'on'); % HR
add_line(mdl, 'DRIVER DISTRACTION DETECTION/5', 'FINAL DISTRACTION WAVEFORMS/8', 'autorouting', 'on'); % H_STATE
add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/9', 'autorouting', 'on'); % STATE
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/10', 'autorouting', 'on'); % ALERT

% 7. Legend Annotation update
legendText = ['DISTRACTION STATE LEGEND' newline ...
'0  FORWARD / UNKNOWN' newline ...
'1  POTENTIAL LEFT' newline ...
'2  POTENTIAL RIGHT' newline ...
'3  UP' newline ...
'4  DOWN' newline ...
'5  DISTRACTED' newline ...
'6  NO FACE' newline ...
'7  HEAD MOVEMENT ONLY' newline ...
'8  DISTRACTION CANDIDATE' newline ...
'9  FORWARD COMPENSATED' newline ...
'10 HAND OFF WHEEL (POTENTIAL)'];
ann = find_system(mdl, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'annotation');
% assuming there is only one annotation or we just update the text
if ~isempty(ann)
    set_param(ann(1), 'Text', legendText);
end

% Compile to test
disp('Compiling model to verify...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
end
close_system(mdl, 0);
