% trace_subsystem_outports.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];

outblocks = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Outport');
for i=1:length(outblocks)
    portStr = get_param(outblocks{i}, 'Port');
    nameStr = get_param(outblocks{i}, 'Name');
    fprintf('Subsystem Outport Name: %s, Port Index: %s\n', nameStr, portStr);
    
    ph = get_param(outblocks{i}, 'PortHandles');
    line = get_param(ph.Inport(1), 'Line');
    if line > 0
        src = get_param(line, 'SrcBlockHandle');
        srcPort = get_param(line, 'SrcPortHandle');
        srcPortIdx = get_param(srcPort, 'PortNumber');
        fprintf('  -> fed by %s (Port %d)\n', get_param(src(1), 'Name'), srcPortIdx);
    else
        fprintf('  -> UNCONNECTED\n');
    end
end
close_system(mdl, 0);
