% trace_scope_wiring.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
ph = get_param(scopeBlock, 'PortHandles');
for i=1:length(ph.Inport)
    line = get_param(ph.Inport(i), 'Line');
    if line > 0
        src = get_param(line, 'SrcBlockHandle');
        srcPorts = get_param(line, 'SrcPortHandle');
        fprintf('Scope/%d gets from -> %s (Port %d)\n', i, get_param(src, 'Name'), get_param(srcPorts, 'PortNumber'));
    else
        fprintf('Scope/%d -> UNCONNECTED\n', i);
    end
end
close_system(mdl, 0);
