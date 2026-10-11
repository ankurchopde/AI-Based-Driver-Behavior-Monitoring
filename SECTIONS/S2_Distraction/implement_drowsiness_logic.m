% implement_drowsiness_logic.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
load_system(mdl);

% Add new blocks for Temporal Drowsiness Logic

% 1. EAR Threshold Constant
add_block('simulink/Sources/Constant', [mdl, '/EAR Threshold']);
set_param([mdl, '/EAR Threshold'], 'Value', '0.15', 'Position', [500, 290, 530, 320]);

% 2. Eye Closed Relational Operator (EAR < Threshold)
add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl, '/EAR < Thresh']);
set_param([mdl, '/EAR < Thresh'], 'Operator', '<', 'Position', [580, 250, 610, 280]);
% Input 1 is EAR (from Demux/3). Input 2 is Threshold
add_line(mdl, 'MediaPipe DEMUX/3', 'EAR < Thresh/1', 'autorouting', 'on');
add_line(mdl, 'EAR Threshold/1', 'EAR < Thresh/2', 'autorouting', 'on');

% 3. Logical AND with Face (EyeClosed AND FaceDetected)
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/Valid Closure']);
set_param([mdl, '/Valid Closure'], 'Operator', 'AND', 'Position', [660, 220, 690, 250]);
% Input 1 is FACE (from Demux/1). Input 2 is (EAR < Thresh)
add_line(mdl, 'MediaPipe DEMUX/1', 'Valid Closure/1', 'autorouting', 'on');
add_line(mdl, 'EAR < Thresh/1', 'Valid Closure/2', 'autorouting', 'on');

% Scope for EYE_CLOSED
add_block('simulink/Sinks/Scope', [mdl, '/EYE_CLOSED Scope']);
set_param([mdl, '/EYE_CLOSED Scope'], 'Position', [750, 180, 780, 210]);
add_line(mdl, 'Valid Closure/1', 'EYE_CLOSED Scope/1', 'autorouting', 'on');

% 4. NOT gate for Integrator Reset
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl, '/Timer Reset']);
set_param([mdl, '/Timer Reset'], 'Operator', 'NOT', 'Position', [750, 260, 780, 290]);
add_line(mdl, 'Valid Closure/1', 'Timer Reset/1', 'autorouting', 'on');

% 5. Constant 1 for Integrator
add_block('simulink/Sources/Constant', [mdl, '/Constant One']);
set_param([mdl, '/Constant One'], 'Value', '1', 'Position', [750, 320, 780, 350]);

% 6. Discrete-Time Integrator
add_block('simulink/Discrete/Discrete-Time Integrator', [mdl, '/Closure Timer']);
set_param([mdl, '/Closure Timer'], 'ExternalReset', 'level', 'InitialCondition', '0', 'Position', [840, 290, 880, 330]);
% Input 1 is Constant One. Input 2 is Reset
add_line(mdl, 'Constant One/1', 'Closure Timer/1', 'autorouting', 'on');
add_line(mdl, 'Timer Reset/1', 'Closure Timer/2', 'autorouting', 'on');

% Scope for CLOSURE_DURATION
add_block('simulink/Sinks/Scope', [mdl, '/CLOSURE_DURATION Scope']);
set_param([mdl, '/CLOSURE_DURATION Scope'], 'Position', [930, 240, 960, 270]);
add_line(mdl, 'Closure Timer/1', 'CLOSURE_DURATION Scope/1', 'autorouting', 'on');

% 7. Timer Threshold Constant
add_block('simulink/Sources/Constant', [mdl, '/Closure Threshold']);
set_param([mdl, '/Closure Threshold'], 'Value', '2.0', 'Position', [840, 370, 870, 400]);

% 8. Drowsiness Alert Relational Operator (Timer >= 2.0)
add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl, '/Drowsiness Check']);
set_param([mdl, '/Drowsiness Check'], 'Operator', '>=', 'Position', [950, 300, 980, 330]);
% Input 1 is Timer. Input 2 is Closure Threshold
add_line(mdl, 'Closure Timer/1', 'Drowsiness Check/1', 'autorouting', 'on');
add_line(mdl, 'Closure Threshold/1', 'Drowsiness Check/2', 'autorouting', 'on');

% Scope for DROWSINESS_ALERT
add_block('simulink/Sinks/Scope', [mdl, '/DROWSINESS_ALERT Scope']);
set_param([mdl, '/DROWSINESS_ALERT Scope'], 'Position', [1050, 300, 1080, 330]);
add_line(mdl, 'Drowsiness Check/1', 'DROWSINESS_ALERT Scope/1', 'autorouting', 'on');

% Add Annotations
ann1 = Simulink.Annotation([mdl, '/CANDIDATE EAR THRESHOLD = 0.15']);
ann1.Position = [500, 340];
ann2 = Simulink.Annotation([mdl, '/Temporal closure = 2 s']);
ann2.Position = [840, 420];
ann3 = Simulink.Annotation([mdl, '/Prototype — threshold not formally calibrated']);
ann3.Position = [700, 460];

% Verify compilation
set_param(mdl, 'SimulationCommand', 'update');
disp('Model updated and compiled successfully.');

save_system(mdl);
close_system(mdl);
