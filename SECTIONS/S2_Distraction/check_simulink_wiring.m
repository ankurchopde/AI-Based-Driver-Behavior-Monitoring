% check_simulink_wiring.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

fprintf('--- DEMUX OUTPORTS ---\n');
ph = get_param([mdl, '/DEMUX'], 'PortHandles');
for i=1:length(ph.Outport)
    line = get_param(ph.Outport(i), 'Line');
    if line > 0
        dst = get_param(line, 'DstBlockHandle');
        dstPorts = get_param(line, 'DstPortHandle');
        fprintf('Demux/%d -> ', i);
        for j=1:length(dst)
            fprintf('%s (Port %f) ', get_param(dst(j), 'Name'), dstPorts(j));
        end
        fprintf('\n');
    else
        fprintf('Demux/%d -> UNCONNECTED\n', i);
    end
end

fprintf('\n--- DRIVER DISTRACTION DETECTION INPORTS ---\n');
sys = [mdl, '/DRIVER DISTRACTION DETECTION'];
ph = get_param(sys, 'PortHandles');
for i=1:length(ph.Inport)
    line = get_param(ph.Inport(i), 'Line');
    if line > 0
        src = get_param(line, 'SrcBlockHandle');
        fprintf('Subsys Inport %d gets from -> %s\n', i, get_param(src, 'Name'));
    else
        fprintf('Subsys Inport %d is UNCONNECTED\n', i);
    end
end

fprintf('\n--- SUBSYSTEM INTERNAL WIRING ---\n');
inblocks = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Inport');
for i=1:length(inblocks)
    portStr = get_param(inblocks{i}, 'Port');
    fprintf('Inside Inport "%s" is Port %s\n', get_param(inblocks{i}, 'Name'), portStr);
    ph_in = get_param(inblocks{i}, 'PortHandles');
    line = get_param(ph_in.Outport(1), 'Line');
    if line > 0
        dst = get_param(line, 'DstBlockHandle');
        fprintf('  -> feeds %s\n', get_param(dst(1), 'Name'));
    end
end

outblocks = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Outport');
for i=1:length(outblocks)
    portStr = get_param(outblocks{i}, 'Port');
    fprintf('Inside Outport "%s" is Port %s\n', get_param(outblocks{i}, 'Name'), portStr);
    ph_out = get_param(outblocks{i}, 'PortHandles');
    line = get_param(ph_out.Inport(1), 'Line');
    if line > 0
        src = get_param(line, 'SrcBlockHandle');
        fprintf('  -> fed by %s\n', get_param(src(1), 'Name'));
    end
end

close_system(mdl, 0);
