% build_temporal_features.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Clean Slate (Remove all old logic/scopes after Demux)
blocksToDelete = {
    '/EAR Threshold', '/EAR < Thresh', '/Valid Closure', '/Time Memory', ...
    '/Time Adder', '/Reset Multiplier', '/DROWSINESS_SAMPLE_TIME', ...
    '/Closure Threshold', '/Drowsiness Check', ...
    '/FACE Scope', '/EAR Scope', '/MAR Scope', ...
    '/VALID_CLOSURE Scope', '/CLOSURE_TIMER Scope', '/DROWSINESS_ALERT Scope'
};
for i=1:length(blocksToDelete)
    try delete_block([mdl, blocksToDelete{i}]); catch, end
end
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i=1:length(lines)
    try delete_line(lines(i)); catch, end
end

% 2. Re-establish Base UDP Connection
add_line(mdl, 'Native UDP Receiver/1', 'MediaPipe DEMUX/1', 'autorouting', 'on');
add_line(mdl, 'Native UDP Receiver/2', 'UDP Status Terminator/1', 'autorouting', 'on');

% 3. SMOOTHING (Discrete FIR Filters for 10-sample Moving Average)
% EAR MA
add_block('simulink/Discrete/Discrete FIR Filter', [mdl, '/EAR MA']);
set_param([mdl, '/EAR MA'], 'CoefSource', 'Dialog parameters', 'NumCoeffs', 'ones(1,10)/10', 'InitialStates', '0.3', 'Position', [420, 160, 480, 200]);
add_line(mdl, 'MediaPipe DEMUX/2', 'EAR MA/1', 'autorouting', 'on');

% MAR MA
add_block('simulink/Discrete/Discrete FIR Filter', [mdl, '/MAR MA']);
set_param([mdl, '/MAR MA'], 'CoefSource', 'Dialog parameters', 'NumCoeffs', 'ones(1,10)/10', 'InitialStates', '0.0', 'Position', [420, 360, 480, 400]);
add_line(mdl, 'MediaPipe DEMUX/3', 'MAR MA/1', 'autorouting', 'on');


% 4. YAWN FEATURE
add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl, '/MAR > 0.247']);
set_param([mdl, '/MAR > 0.247'], 'Operator', '>', 'Position', [550, 370, 580, 400]);
add_block('simulink/Sources/Constant', [mdl, '/YAWN_THRESH']);
set_param([mdl, '/YAWN_THRESH'], 'Value', '0.247', 'Position', [480, 400, 520, 420]);
add_line(mdl, 'MAR MA/1', 'MAR > 0.247/1', 'autorouting', 'on');
add_line(mdl, 'YAWN_THRESH/1', 'MAR > 0.247/2', 'autorouting', 'on');

add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/YAWN_ACTIVE']);
set_param([mdl, '/YAWN_ACTIVE'], 'Operator', 'AND', 'Position', [650, 360, 680, 390]);
add_line(mdl, 'MediaPipe DEMUX/1', 'YAWN_ACTIVE/1', 'autorouting', 'on'); % FACE
add_line(mdl, 'MAR > 0.247/1', 'YAWN_ACTIVE/2', 'autorouting', 'on');


% 5. BLINK FEATURE
% EAR < 0.173
add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl, '/EAR < 0.173']);
set_param([mdl, '/EAR < 0.173'], 'Operator', '<', 'Position', [550, 100, 580, 130]);
add_block('simulink/Sources/Constant', [mdl, '/BLINK_THRESH']);
set_param([mdl, '/BLINK_THRESH'], 'Value', '0.173', 'Position', [480, 130, 520, 150]);
add_line(mdl, 'EAR MA/1', 'EAR < 0.173/1', 'autorouting', 'on');
add_line(mdl, 'BLINK_THRESH/1', 'EAR < 0.173/2', 'autorouting', 'on');

% Blink Active = (EAR < 0.173) AND Face
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/BLINK_ACTIVE']);
set_param([mdl, '/BLINK_ACTIVE'], 'Operator', 'AND', 'Position', [650, 70, 680, 100]);
add_line(mdl, 'MediaPipe DEMUX/1', 'BLINK_ACTIVE/1', 'autorouting', 'on');
add_line(mdl, 'EAR < 0.173/1', 'BLINK_ACTIVE/2', 'autorouting', 'on');

% Detect Blink End (Falling edge of EAR < 0.173)
add_block('simulink/Logic and Bit Operations/Detect Decrease', [mdl, '/Detect Blink End']);
set_param([mdl, '/Detect Blink End'], 'Position', [650, 120, 680, 150]);
add_line(mdl, 'EAR < 0.173/1', 'Detect Blink End/1', 'autorouting', 'on');

% Blink Event = (Blink End) AND Face
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/BLINK_EVENT']);
set_param([mdl, '/BLINK_EVENT'], 'Operator', 'AND', 'Position', [750, 120, 780, 150]);
add_line(mdl, 'Detect Blink End/1', 'BLINK_EVENT/1', 'autorouting', 'on');
add_line(mdl, 'MediaPipe DEMUX/1', 'BLINK_EVENT/2', 'autorouting', 'on');

% Blink Count (Accumulator)
add_block('simulink/Discrete/Unit Delay', [mdl, '/Blink Mem']);
set_param([mdl, '/Blink Mem'], 'InitialCondition', '0', 'Position', [850, 150, 880, 180]);
set_param([mdl, '/Blink Mem'], 'Orientation', 'left');
add_block('simulink/Math Operations/Add', [mdl, '/Blink Adder']);
set_param([mdl, '/Blink Adder'], 'Inputs', '++', 'Position', [850, 100, 880, 130]);
add_line(mdl, 'BLINK_EVENT/1', 'Blink Adder/1', 'autorouting', 'on');
add_line(mdl, 'Blink Mem/1', 'Blink Adder/2', 'autorouting', 'on');
add_line(mdl, 'Blink Adder/1', 'Blink Mem/1', 'autorouting', 'on');


% 6. MICROSLEEP FEATURE
% EAR < 0.138
add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl, '/EAR < 0.138']);
set_param([mdl, '/EAR < 0.138'], 'Operator', '<', 'Position', [550, 220, 580, 250]);
add_block('simulink/Sources/Constant', [mdl, '/MICROSLEEP_THRESH']);
set_param([mdl, '/MICROSLEEP_THRESH'], 'Value', '0.138', 'Position', [480, 250, 520, 270]);
add_line(mdl, 'EAR MA/1', 'EAR < 0.138/1', 'autorouting', 'on');
add_line(mdl, 'MICROSLEEP_THRESH/1', 'EAR < 0.138/2', 'autorouting', 'on');

% Microsleep Active = (EAR < 0.138) AND Face
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/MICROSLEEP_ACTIVE']);
set_param([mdl, '/MICROSLEEP_ACTIVE'], 'Operator', 'AND', 'Position', [650, 220, 680, 250]);
add_line(mdl, 'MediaPipe DEMUX/1', 'MICROSLEEP_ACTIVE/1', 'autorouting', 'on');
add_line(mdl, 'EAR < 0.138/1', 'MICROSLEEP_ACTIVE/2', 'autorouting', 'on');

% Deterministic Timer for Microsleep Duration
add_block('simulink/Sources/Constant', [mdl, '/DT_CONSTANT']);
set_param([mdl, '/DT_CONSTANT'], 'Value', '0.05', 'Position', [700, 280, 740, 300]);
add_block('simulink/Discrete/Unit Delay', [mdl, '/MS_Mem']);
set_param([mdl, '/MS_Mem'], 'InitialCondition', '0', 'Position', [850, 310, 880, 340], 'Orientation', 'left');
add_block('simulink/Math Operations/Add', [mdl, '/MS_Add']);
set_param([mdl, '/MS_Add'], 'Inputs', '++', 'Position', [800, 250, 830, 280]);
add_block('simulink/Math Operations/Product', [mdl, '/MS_Mult']);
set_param([mdl, '/MS_Mult'], 'Inputs', '**', 'Position', [870, 230, 900, 260]);

add_line(mdl, 'MS_Mem/1', 'MS_Add/1', 'autorouting', 'on');
add_line(mdl, 'DT_CONSTANT/1', 'MS_Add/2', 'autorouting', 'on');
add_line(mdl, 'MS_Add/1', 'MS_Mult/2', 'autorouting', 'on');
add_line(mdl, 'MICROSLEEP_ACTIVE/1', 'MS_Mult/1', 'autorouting', 'on');
add_line(mdl, 'MS_Mult/1', 'MS_Mem/1', 'autorouting', 'on');


% 7. SCOPES
add_block('simulink/Sinks/Scope', [mdl, '/SMOOTHED_EAR Scope']);
set_param([mdl, '/SMOOTHED_EAR Scope'], 'Position', [1000, 50, 1030, 80]);
add_line(mdl, 'EAR MA/1', 'SMOOTHED_EAR Scope/1', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [mdl, '/BLINK_EVENT Scope']);
set_param([mdl, '/BLINK_EVENT Scope'], 'Position', [1000, 100, 1030, 130]);
add_line(mdl, 'BLINK_EVENT/1', 'BLINK_EVENT Scope/1', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [mdl, '/MICROSLEEP_DURATION Scope']);
set_param([mdl, '/MICROSLEEP_DURATION Scope'], 'Position', [1000, 230, 1030, 260]);
add_line(mdl, 'MS_Mult/1', 'MICROSLEEP_DURATION Scope/1', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [mdl, '/SMOOTHED_MAR Scope']);
set_param([mdl, '/SMOOTHED_MAR Scope'], 'Position', [1000, 310, 1030, 340]);
add_line(mdl, 'MAR MA/1', 'SMOOTHED_MAR Scope/1', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [mdl, '/YAWN_ACTIVE Scope']);
set_param([mdl, '/YAWN_ACTIVE Scope'], 'Position', [1000, 360, 1030, 390]);
add_line(mdl, 'YAWN_ACTIVE/1', 'YAWN_ACTIVE Scope/1', 'autorouting', 'on');


% 8. COMPILATION VERIFICATION
set_param(mdl, 'SimulationCommand', 'update');
disp('Model compiled successfully with completely new Temporal Feature Layer!');
save_system(mdl);
close_system(mdl);
