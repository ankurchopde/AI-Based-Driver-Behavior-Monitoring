% force_scope_display_names.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% Ensure the line names are propagated and explicitly show on the scope
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];
ph = get_param(sys, 'PortHandles');
set_param(ph.Outport(1), 'Name', 'DISTRACTION STATE');
set_param(ph.Outport(2), 'Name', 'DISTRACTION ALERT');

% Ensure DEMUX names
demux = [mdl, '/DEMUX'];
ph_demux = get_param(demux, 'PortHandles');
set_param(ph_demux.Outport(4), 'Name', 'YAW (deg)');
set_param(ph_demux.Outport(5), 'Name', 'PITCH (deg)');
set_param(ph_demux.Outport(6), 'Name', 'ROLL (deg)');
set_param(ph_demux.Outport(7), 'Name', 'GAZE_X');
set_param(ph_demux.Outport(8), 'Name', 'GAZE_Y');

% If we want to force the scope to show the legend or Y-label
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
try
    % For R2015a+ Simulink scopes
    scopeConfig = get_param(scopeBlock, 'ScopeConfiguration');
    scopeConfig.DisplayTitles = {'YAW (deg)', 'PITCH (deg)', 'ROLL (deg)', 'GAZE_X', 'GAZE_Y', 'DISTRACTION STATE', 'DISTRACTION ALERT'};
catch
    % Ignore if property doesn't exist
end

% Set Y-limits just in case they are collapsed
try
    scopeConfig.YLimits = [
        -90 90;
        -90 90;
        -90 90;
        -1 1;
        -1 1;
        0 9;
        -0.1 1.1
    ];
catch
end

set_param(mdl, 'SimulationCommand', 'update');
save_system(mdl);
close_system(mdl, 0);
disp('Forced display names and Y-limits.');
