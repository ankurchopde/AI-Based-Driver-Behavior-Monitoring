% name_scope_axes.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

scopeName = [mdl, '/FINAL DROWSINESS WAVEFORMS'];
scopeObj = get_param(scopeName, 'ScopeConfiguration');

axes_names = {
    'RAW EAR',
    'SMOOTH EAR',
    'RAW MAR',
    'SMOOTH MAR',
    'BLINK EVENT',
    'MS DURATION',
    'YAWN EVENT',
    'DROWSINESS STATE',
    'DROWSINESS ALERT'
};

for i = 1:9
    scopeObj.ActiveDisplay = i;
    
    % Hardcode the exact string as the Title for the specific subplot
    scopeObj.Title = axes_names{i};
    
    % Turn off the default signal-legend since we explicitly removed signal names from the wires
    scopeObj.ShowLegend = false; 
    
    % Set the Y-axis label as well for maximum clarity
    scopeObj.YLabel = axes_names{i};
end

set_param(mdl, 'SimulationCommand', 'update');
disp('Scope subplots successfully hardcoded with axis names! Diagram remains untouched.');
save_system(mdl);
close_system(mdl);
