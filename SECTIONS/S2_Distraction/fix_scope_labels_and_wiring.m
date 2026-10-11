% fix_scope_labels_and_wiring.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. Check outputs of the DRIVER DISTRACTION DETECTION subsystem
distractSys = [mdl, '/DRIVER DISTRACTION DETECTION'];
sysPortHandles = get_param(distractSys, 'PortHandles');

% Outport 1 of the subsystem is STATE
% Outport 2 of the subsystem is ALERT
set_param(sysPortHandles.Outport(1), 'Name', 'DISTRACTION STATE');
set_param(sysPortHandles.Outport(2), 'Name', 'DISTRACTION ALERT');

% 2. Check the scope
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
scopePortHandles = get_param(scopeBlock, 'PortHandles');

% Re-wire explicitly
% Delete lines going to port 6 and 7 of the scope
line6 = get_param(scopePortHandles.Inport(6), 'Line');
if line6 > 0, delete_line(line6); end
line7 = get_param(scopePortHandles.Inport(7), 'Line');
if line7 > 0, delete_line(line7); end

% Re-wire Subsystem Outport 1 (STATE) to Scope Inport 6
add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/6', 'autorouting', 'on');
% Re-wire Subsystem Outport 2 (ALERT) to Scope Inport 7
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/7', 'autorouting', 'on');

% Set title string in scope if supported
try
    scopeConfig = get_param(scopeBlock, 'ScopeConfiguration');
    scopeConfig.Title = 'YAW (deg)|PITCH (deg)|ROLL (deg)|GAZE_X|GAZE_Y|DISTRACTION STATE|DISTRACTION ALERT';
catch
end

% Compile to ensure no errors
set_param(mdl, 'SimulationCommand', 'update');
save_system(mdl);
close_system(mdl, 0);
disp('Scope labels and wiring fixed.');
