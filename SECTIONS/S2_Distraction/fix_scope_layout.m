% fix_scope_layout.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

scopeName = [mdl, '/FINAL DROWSINESS WAVEFORMS'];

try
    scopeObj = get_param(scopeName, 'ScopeConfiguration');
    scopeObj.LayoutDimensions = [9 1];
    
    disp('Scope LayoutDimensions set to [9 1] successfully.');
catch ME
    disp(['Failed to set ScopeConfiguration: ', ME.message]);
    
    % Fallback: Use Simulink format string property for older blocks
    try
        set_param(scopeName, 'TickLabels', 'OneTimeTick');
        set_param(scopeName, 'ZoomMode', 'on');
        set_param(scopeName, 'Grid', 'on');
    catch
    end
end

set_param(mdl, 'SimulationCommand', 'update');
disp('Model updated.');
save_system(mdl);
close_system(mdl);
