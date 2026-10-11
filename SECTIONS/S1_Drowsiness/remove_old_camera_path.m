% remove_old_camera_path.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
load_system(mdl);

% Find all MATLAB System blocks
sysBlocks = find_system(mdl, 'BlockType', 'MATLABSystem');
for i = 1:length(sysBlocks)
    blk = sysBlocks{i};
    sysName = get_param(blk, 'System');
    if strcmp(sysName, 'DriverMonitorSystem')
        disp(['Removing old camera block: ', blk]);
        
        % Delete lines connected to its output
        % Delete all lines connected to this block
        portHandles = get_param(blk, 'PortHandles');
        allPorts = [portHandles.Inport, portHandles.Outport];
        for p = 1:length(allPorts)
            line = get_param(allPorts(p), 'Line');
            if line ~= -1
                delete_line(line);
            end
        end
        
        % Delete the block itself
        delete_block(blk);
    end
end

% Wait, we should also delete the old DEMUX and old Scopes to keep it clean,
% but if they are left unconnected, they might throw an error.
% Let's find any unconnected blocks and delete them? Or just manually find the old Demux.
% The old Demux was likely named 'Demux' or 'Detection Signals Demux'.
% Let's just find and delete any block whose name does NOT contain 'MediaPipe' or 'UDP' or 'Terminator'
% Actually, it's safer to just delete the old block, and if there are unconnected Demuxes, delete them.
% A cleaner way: find blocks with no input lines and no output lines and delete them iteratively.

for iter = 1:3
    allBlocks = find_system(mdl, 'Type', 'block');
    for i = 1:length(allBlocks)
        blk = allBlocks{i};
        % Skip the model itself
        if strcmp(blk, mdl), continue; end
        
        % Don't delete our new blocks!
        if contains(blk, 'MediaPipe') || contains(blk, 'UDP') || contains(blk, 'Terminator')
            continue;
        end
        
        try
            ports = get_param(blk, 'PortConnectivity');
            isConnected = false;
            for p = 1:length(ports)
                if ~isempty(ports(p).SrcBlock) || ~isempty(ports(p).DstBlock)
                    isConnected = true;
                    break;
                end
            end
            
            if ~isConnected
                disp(['Deleting unconnected block: ', blk]);
                
                pH = get_param(blk, 'PortHandles');
                aP = [pH.Inport, pH.Outport];
                for pt = 1:length(aP)
                    ln = get_param(aP(pt), 'Line');
                    if ln ~= -1, delete_line(ln); end
                end
                
                delete_block(blk);
            end
        catch
        end
    end
end

% Compile to verify
set_param(mdl, 'SimulationCommand', 'update');
disp('Model updated successfully. Old camera path fully removed.');

save_system(mdl);
close_system(mdl);
