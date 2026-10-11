mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

scopeObj = get_param([mdl, '/FINAL DROWSINESS WAVEFORMS'], 'ScopeConfiguration');
disp(properties(scopeObj));

close_system(mdl, 0);
