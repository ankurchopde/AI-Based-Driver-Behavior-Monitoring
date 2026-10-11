try
    disp('Loading model...');
    load_system('driver_monitor_sim');
    
    disp('Setting StopTime to inf...');
    set_param('driver_monitor_sim', 'StopTime', 'inf');
    
    % Store position of the old block
    oldBlock = 'driver_monitor_sim/Detection Function';
    pos = get_param(oldBlock, 'Position');
    
    disp('Deleting old line...');
    delete_line('driver_monitor_sim', 'Detection Function/1', 'Demux/1');
    
    disp('Deleting old block...');
    delete_block(oldBlock);
    
    disp('Adding new MATLAB System block...');
    newBlock = 'driver_monitor_sim/DriverMonitorSystem';
    add_block('simulink/User-Defined Functions/MATLAB System', newBlock);
    
    disp('Configuring new block...');
    set_param(newBlock, 'Position', pos);
    set_param(newBlock, 'System', 'DriverMonitorSystem');
    
    try
        set_param(newBlock, 'SimulateUsing', 'Interpreted execution');
    catch ME2
        disp(['Warning setting SimulateUsing: ', ME2.message]);
    end
    
    disp('Connecting new block to Demux...');
    add_line('driver_monitor_sim', 'DriverMonitorSystem/1', 'Demux/1');
    
    disp('Saving model...');
    save_system('driver_monitor_sim');
    
    disp('Update complete! Model has been saved.');
catch ME
    disp(['Error: ', ME.message]);
end
