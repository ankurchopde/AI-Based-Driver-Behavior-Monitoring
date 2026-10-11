% cleanup_visualization.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

% 1. Find and delete the old combined scope and its lines
oldScope = [mdl, '/FINAL DISTRACTION WAVEFORMS'];
if get_param(oldScope, 'Handle')
    % delete lines connected to it
    lineHandles = get_param(oldScope, 'LineHandles');
    for i = 1:length(lineHandles.Inport)
        if lineHandles.Inport(i) > 0
            delete_line(lineHandles.Inport(i));
        end
    end
    delete_block(oldScope);
end

% 2. Name the signals from DEMUX
% Demux outputs: 1=FACE, 2=EAR, 3=MAR, 4=YAW, 5=PITCH, 6=ROLL, 7=GAZE_X, 8=GAZE_Y
demuxPortHandles = get_param([mdl, '/DEMUX'], 'PortHandles');
set_param(demuxPortHandles.Outport(4), 'Name', 'YAW');
set_param(demuxPortHandles.Outport(5), 'Name', 'PITCH');
set_param(demuxPortHandles.Outport(6), 'Name', 'ROLL');
set_param(demuxPortHandles.Outport(7), 'Name', 'GAZE_X');
set_param(demuxPortHandles.Outport(8), 'Name', 'GAZE_Y');

% Name the signals from the Subsystem
distractSys = [mdl, '/DRIVER DISTRACTION DETECTION'];
sysPortHandles = get_param(distractSys, 'PortHandles');
set_param(sysPortHandles.Outport(1), 'Name', 'DISTRACTION_STATE');
set_param(sysPortHandles.Outport(2), 'Name', 'DISTRACTION_ALERT');

% 3. Create New Scopes
% HEAD POSE
scopeHead = [mdl, '/HEAD POSE'];
add_block('simulink/Sinks/Scope', scopeHead);
set_param(scopeHead, 'Position', [650, 400, 700, 500]);
set_param(scopeHead, 'NumInputPorts', '3');
set_param(scopeHead, 'Title', 'HEAD POSE');

% GAZE
scopeGaze = [mdl, '/GAZE'];
add_block('simulink/Sinks/Scope', scopeGaze);
set_param(scopeGaze, 'Position', [650, 550, 700, 650]);
set_param(scopeGaze, 'NumInputPorts', '2');
set_param(scopeGaze, 'Title', 'GAZE');

% DISTRACTION STATUS
scopeStatus = [mdl, '/DISTRACTION STATUS'];
add_block('simulink/Sinks/Scope', scopeStatus);
set_param(scopeStatus, 'Position', [650, 700, 700, 800]);
set_param(scopeStatus, 'NumInputPorts', '2');
set_param(scopeStatus, 'Title', 'DISTRACTION STATUS');

% 4. Connect signals to Scopes
add_line(mdl, 'DEMUX/4', 'HEAD POSE/1', 'autorouting', 'on');
add_line(mdl, 'DEMUX/5', 'HEAD POSE/2', 'autorouting', 'on');
add_line(mdl, 'DEMUX/6', 'HEAD POSE/3', 'autorouting', 'on');

add_line(mdl, 'DEMUX/7', 'GAZE/1', 'autorouting', 'on');
add_line(mdl, 'DEMUX/8', 'GAZE/2', 'autorouting', 'on');

add_line(mdl, 'DRIVER DISTRACTION DETECTION/1', 'DISTRACTION STATUS/1', 'autorouting', 'on');
add_line(mdl, 'DRIVER DISTRACTION DETECTION/2', 'DISTRACTION STATUS/2', 'autorouting', 'on');

% 5. Add Legend Annotation
legendText = ['DISTRACTION STATE LEGEND' newline ...
'0  FORWARD' newline ...
'1  POTENTIAL LEFT' newline ...
'2  POTENTIAL RIGHT' newline ...
'3  UP' newline ...
'4  DOWN' newline ...
'5  DISTRACTED' newline ...
'6  NO FACE' newline ...
'7  HEAD MOVEMENT ONLY' newline ...
'8  DISTRACTION CANDIDATE' newline ...
'9  FORWARD COMPENSATED'];
ann = Simulink.Annotation([mdl, '/DISTRACTION STATE LEGEND']);
ann.Text = legendText;
ann.Position = [100, 450];
ann.DropShadow = 'on';
ann.FontSize = 10;

% 6. Enable Scope legends programmatically if possible (not always supported by direct set_param but signals are named)
% Signals are named, so scope will automatically pick up names in the legend when opened.

% Compile to test
disp('Compiling model to verify... ');
try
    set_param(mdl, 'SimulationCommand', 'update');
    disp('Model compiled successfully.');
    save_system(mdl);
catch ME
    disp(['Compilation Error: ', ME.message]);
end

close_system(mdl, 0);
disp('Visualization cleanup complete.');
