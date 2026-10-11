% check_model_compiles.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Success');
catch ME
    disp(ME.getReport());
end
close_system(mdl, 0);
