try
    disp('Loading model...');
    load_system('driver_monitor_sim');
    disp('Simulating model for 0 seconds to verify compilation and hardware setup...');
    simOut = sim('driver_monitor_sim', 'StopTime', '0.0');
    disp('Compilation and Initialization successful! No dimension or setup errors.');
catch ME
    disp(['Error during verification: ', ME.message]);
end
