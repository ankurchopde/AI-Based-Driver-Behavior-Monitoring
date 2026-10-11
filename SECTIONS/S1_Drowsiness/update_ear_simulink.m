try
    disp('Loading model...');
    load_system('driver_monitor_sim');
    
    set_param('driver_monitor_sim/Demux', 'Outputs', '3');
    
    earScope = 'driver_monitor_sim/EAR Scope';
    if getSimulinkBlockHandle(earScope) == -1
        add_block('simulink/Sinks/Scope', earScope);
        
        demuxPos = get_param('driver_monitor_sim/Demux', 'Position');
        set_param(earScope, 'Position', [demuxPos(3)+50, demuxPos(4)+20, demuxPos(3)+90, demuxPos(4)+60]);
    end
    
    demuxPorts = get_param('driver_monitor_sim/Demux', 'PortHandles');
    out3 = demuxPorts.Outport(3);
    
    line3 = get_param(out3, 'Line');
    if line3 == -1
        lh3 = add_line('driver_monitor_sim', 'Demux/3', 'EAR Scope/1');
        set_param(lh3, 'Name', 'EAR');
    end
    
    disp('Simulating for 0 seconds to verify...');
    sim('driver_monitor_sim', 'StopTime', '0.0');
    disp('Model verified!');
    
    save_system('driver_monitor_sim');
    close_system('driver_monitor_sim');
catch ME
    disp(['Error: ', ME.message]);
    try
        close_system('driver_monitor_sim', 0);
    catch
    end
end
