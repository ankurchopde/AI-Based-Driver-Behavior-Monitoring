% update_final_distraction_scope.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. Remove the 3 separate scopes
scopes_to_remove = {'HEAD POSE', 'GAZE', 'DISTRACTION STATUS'};
for i = 1:length(scopes_to_remove)
    bPath = [mdl, '/', scopes_to_remove{i}];
    % Use find_system to safely check if it exists
    exists = find_system(mdl, 'SearchDepth', 1, 'Name', scopes_to_remove{i});
    if ~isempty(exists)
        % delete lines connected to it
        lh = get_param(bPath, 'LineHandles');
        for j = 1:length(lh.Inport)
            if lh.Inport(j) > 0
                delete_line(lh.Inport(j));
            end
        end
        delete_block(bPath);
    end
end

% 2. Create the single scope
scopeBlock = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
% Just in case it already exists somehow, delete it
if ~isempty(find_system(mdl, 'SearchDepth', 1, 'Name', 'FINAL DISTRACTION WAVEFORMS'))
    lh = get_param(scopeBlock, 'LineHandles');
    for j = 1:length(lh.Inport)
        if lh.Inport(j) > 0
            delete_line(lh.Inport(j));
        end
    end
    delete_block(scopeBlock);
end

add_block('simulink/Sinks/Scope', scopeBlock);
set_param(scopeBlock, 'Position', [750, 300, 850, 900]);
set_param(scopeBlock, 'NumInputPorts', '7');

% Set layout to 7 rows, 1 column
try
    scopeConfig = get_param(scopeBlock, 'ScopeConfiguration');
    scopeConfig.LayoutDimensions = [7 1];
catch
    try
        set_param(scopeBlock, 'LayoutDimensions', '[7 1]');
    catch
    end
end

% 3. Name the signals for clear legends/axes
demuxPortHandles = get_param([mdl, '/DEMUX'], 'PortHandles');
set_param(demuxPortHandles.Outport(4), 'Name', 'YAW (deg)');
set_param(demuxPortHandles.Outport(5), 'Name', 'PITCH (deg)');
set_param(demuxPortHandles.Outport(6), 'Name', 'ROLL (deg)');
set_param(demuxPortHandles.Outport(7), 'Name', 'GAZE_X');
set_param(demuxPortHandles.Outport(8), 'Name', 'GAZE_Y');

distractSys = [mdl, '/DRIVER DISTRACTION DETECTION'];
sysPortHandles = get_param(distractSys, 'PortHandles');
set_param(sysPortHandles.Outport(1), 'Name', 'DISTRACTION STATE');
set_param(sysPortHandles.Outport(2), 'Name', 'DISTRACTION ALERT');

% 4. Connect signals to the new 7-port scope
add_line(mdl, 'DEMUX/4', 'FINAL DISTRACTION WAVEFORMS/1', 'autorouting', 'on');
add_line(mdl, 'DEMUX/5', 'FINAL DISTRACTION WAVEFORMS/2', 'autorouting', 'on');
add_line(mdl, 'DEMUX/6', 'FINAL DISTRACTION WAVEFORMS/3', 'autorouting', 'on');
add_line(mdl, 'DEMUX/7', 'FINAL DISTRACTION WAVEFORMS/4', 'autorouting', 'on');
add_line(mdl, 'DEMUX/8', 'FINAL DISTRACTION WAVEFORMS/5', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'FINAL DISTRACTION WAVEFORMS/6', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'FINAL DISTRACTION WAVEFORMS/7', 'autorouting', 'on');

disp('Compiling model to verify...');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
end

close_system(mdl, 0);
disp('Visualization update complete.');
