% update_simulink_dashboard.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. DEMUX -> 14 outputs
demuxBlock = [mdl, '/DEMUX'];
set_param(demuxBlock, 'Outputs', '14');

% 2. Add Timer Outport to Subsystem
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];
if isempty(find_system(sys, 'SearchDepth', 1, 'Name', 'TIMER'))
    add_block('simulink/Sinks/Out1', [sys, '/TIMER']);
    set_param([sys, '/TIMER'], 'Port', '6');
end

% 3. Connect Distraction Logic out6 to TIMER
try add_line(sys, 'Distraction Logic/6', 'TIMER/1', 'autorouting', 'on'); catch; end

% 4. Add MATLAB System block for Dashboard
dashboardBlock = [mdl, '/SteeringWheelDashboard'];
if isempty(find_system(mdl, 'SearchDepth', 1, 'Name', 'SteeringWheelDashboard'))
    add_block('simulink/User-Defined Functions/MATLAB System', dashboardBlock);
    set_param(dashboardBlock, 'System', 'SteeringWheelDashboard');
end

% 5. Mux the 10 inputs into Dashboard? No, MATLAB System block creates multiple Inports if stepImpl has multiple args.
% Wait, sometimes we need to refresh the block or update the System property to reflect the 10 ports.
set_param(dashboardBlock, 'System', 'SteeringWheelDashboard');

% 6. Wire to Dashboard
% The inputs in order: 1:hl_state, 2:hr_state, 3:h_state, 4:timer, 5:state, 6:alert, 7:lx, 8:ly, 9:rx, 10:ry

% Helper to connect with autorouting
connect_blk = @(src, dst_port) add_line(mdl, src, [get_param(dashboardBlock, 'Name') '/' num2str(dst_port)], 'autorouting', 'on');

% Delete existing lines to dashboard if any
ph = get_param(dashboardBlock, 'PortHandles');
for i=1:length(ph.Inport)
    if get_param(ph.Inport(i), 'Line') > 0
        delete_line(get_param(ph.Inport(i), 'Line'));
    end
end

% Connect Subsystem Outputs to Dashboard
try connect_blk('DRIVER DISTRACTION DETECTION/3', 1); catch; end % hl_state
try connect_blk('DRIVER DISTRACTION DETECTION/4', 2); catch; end % hr_state
try connect_blk('DRIVER DISTRACTION DETECTION/5', 3); catch; end % h_state
try connect_blk('DRIVER DISTRACTION DETECTION/6', 4); catch; end % timer
try connect_blk('DRIVER DISTRACTION DETECTION/1', 5); catch; end % state
try connect_blk('DRIVER DISTRACTION DETECTION/2', 6); catch; end % alert

% Connect DEMUX outputs to Dashboard (wrist coords)
try connect_blk('DEMUX/11', 7); catch; end % lx
try connect_blk('DEMUX/12', 8); catch; end % ly
try connect_blk('DEMUX/13', 9); catch; end % rx
try connect_blk('DEMUX/14', 10); catch; end % ry

% Set names for DEMUX 11-14
demux_ph = get_param(demuxBlock, 'PortHandles');
set_param(demux_ph.Outport(11), 'Name', 'WRIST_LX');
set_param(demux_ph.Outport(12), 'Name', 'WRIST_LY');
set_param(demux_ph.Outport(13), 'Name', 'WRIST_RX');
set_param(demux_ph.Outport(14), 'Name', 'WRIST_RY');

% Compile and save
disp('Compiling model to verify Dashboard integration...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
    disp(ME.getReport());
end
close_system(mdl, 0);
