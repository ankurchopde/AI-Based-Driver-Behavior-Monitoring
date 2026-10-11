% fix_all_ports.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

sys = [mdl, '/DRIVER DISTRACTION DETECTION'];

% Add all missing outports
function add_out(sys, name, portnum)
    if isempty(find_system(sys, 'SearchDepth', 1, 'Name', name))
        add_block('simulink/Sinks/Out1', [sys, '/' name]);
    end
    set_param([sys, '/' name], 'Port', portnum);
end

add_out(sys, 'HL_OUT', '3');
add_out(sys, 'HR_OUT', '4');
add_out(sys, 'H_STATE', '5');
add_out(sys, 'TIMER', '6');

function add_in(sys, name, portnum)
    if isempty(find_system(sys, 'SearchDepth', 1, 'Name', name))
        add_block('simulink/Sources/In1', [sys, '/' name]);
    end
    set_param([sys, '/' name], 'Port', portnum);
end

add_in(sys, 'HAND_LEFT', '7');
add_in(sys, 'HAND_RIGHT', '8');

% Disconnect and reconnect all logic block lines
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
add_line(sys, 'Distraction Logic/6', 'TIMER/1', 'autorouting', 'on');

save_system(mdl);
disp('Ports added and saved.');
