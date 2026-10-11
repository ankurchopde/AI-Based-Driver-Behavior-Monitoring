try
    disp('Loading model...');
    load_system('driver_monitor_sim');
    
    if getSimulinkBlockHandle('driver_monitor_sim/FACE scope1') ~= -1
        disp('Deleting old scopes...');
        delete_line('driver_monitor_sim', 'Demux/1', 'FACE scope1/1');
        delete_line('driver_monitor_sim', 'Demux/2', 'EYES scope/1');
        delete_block('driver_monitor_sim/FACE scope1');
        delete_block('driver_monitor_sim/EYES scope');
    end
    
    dualScope = 'driver_monitor_sim/Detection Signals';
    if getSimulinkBlockHandle(dualScope) ~= -1
        delete_block(dualScope);
        % Also delete the lines connected to it if it was partially wired
        lines = find_system('driver_monitor_sim', 'FindAll', 'on', 'Type', 'line', 'Name', 'Face Detected');
        delete_line(lines);
        lines = find_system('driver_monitor_sim', 'FindAll', 'on', 'Type', 'line', 'Name', 'Eyes Detected');
        delete_line(lines);
    end
    
    disp('Adding new Dual Scope...');
    add_block('simulink/Sinks/Scope', dualScope);
    
    demuxPos = get_param('driver_monitor_sim/Demux', 'Position');
    newPos = [demuxPos(3)+50, demuxPos(2)-20, demuxPos(3)+120, demuxPos(4)+20];
    set_param(dualScope, 'Position', newPos);
    
    disp('Configuring Scope Layout...');
    scopeConfig = get_param(dualScope, 'ScopeConfiguration');
    if ~isempty(scopeConfig)
        scopeConfig.NumInputPorts = '2';
        scopeConfig.LayoutDimensions = [2 1];
    end
    
    disp('Wiring up...');
    lh1 = add_line('driver_monitor_sim', 'Demux/1', 'Detection Signals/1');
    lh2 = add_line('driver_monitor_sim', 'Demux/2', 'Detection Signals/2');
    
    set_param(lh1, 'Name', 'Face Detected');
    set_param(lh2, 'Name', 'Eyes Detected');
    
    disp('Saving model...');
    save_system('driver_monitor_sim');
    close_system('driver_monitor_sim');
    
    disp('Dual Scope update complete!');
catch ME
    disp(['Error: ', ME.message]);
end
