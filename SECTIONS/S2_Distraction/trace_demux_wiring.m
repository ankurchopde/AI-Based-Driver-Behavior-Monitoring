% trace_demux_wiring.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

demuxBlock = [mdl, '/DEMUX'];
ph = get_param(demuxBlock, 'PortHandles');
for i=1:length(ph.Outport)
    line = get_param(ph.Outport(i), 'Line');
    if line > 0
        dst = get_param(line, 'DstBlockHandle');
        dstPorts = get_param(line, 'DstPortHandle');
        fprintf('Demux/%d -> ', i);
        for j=1:length(dst)
            fprintf('%s (Port %d) ', get_param(dst(j), 'Name'), get_param(dstPorts(j), 'PortNumber'));
        end
        fprintf('\n');
    else
        fprintf('Demux/%d -> UNCONNECTED\n', i);
    end
end
close_system(mdl, 0);
