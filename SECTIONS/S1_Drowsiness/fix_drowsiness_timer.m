% fix_drowsiness_timer.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
load_system(mdl);

% Delete old timer logic
try delete_line(mdl, 'Constant One/1', 'Closure Timer/1'); catch, end
try delete_line(mdl, 'Timer Reset/1', 'Closure Timer/2'); catch, end
try delete_line(mdl, 'Closure Timer/1', 'CLOSURE_DURATION Scope/1'); catch, end
try delete_line(mdl, 'Closure Timer/1', 'Drowsiness Check/1'); catch, end
try delete_block([mdl, '/Closure Timer']); catch, end
try delete_block([mdl, '/Timer Reset']); catch, end
try delete_block([mdl, '/Constant One']); catch, end
try delete_line(mdl, 'Valid Closure/1', 'Timer Reset/1'); catch, end

% Create new explicitly defined deterministic timer
% Equation: Next_Time = (Current_Time + DROWSINESS_SAMPLE_TIME) * Valid_Closure

% 1. DROWSINESS_SAMPLE_TIME constant
add_block('simulink/Sources/Constant', [mdl, '/DROWSINESS_SAMPLE_TIME']);
set_param([mdl, '/DROWSINESS_SAMPLE_TIME'], 'Value', '0.05', 'Position', [700, 310, 750, 340]);

% 2. Unit Delay (Current_Time)
add_block('simulink/Discrete/Unit Delay', [mdl, '/Time Memory']);
set_param([mdl, '/Time Memory'], 'SampleTime', '0.05', 'InitialCondition', '0', 'Position', [820, 240, 860, 280]);
% We need to flip the Unit Delay or route it back
set_param([mdl, '/Time Memory'], 'Orientation', 'left');

% 3. Sum block (Current_Time + Sample_Time)
add_block('simulink/Math Operations/Add', [mdl, '/Time Adder']);
set_param([mdl, '/Time Adder'], 'Inputs', '++', 'Position', [780, 300, 810, 330]);

% 4. Product block (multiply by Valid_Closure)
add_block('simulink/Math Operations/Product', [mdl, '/Reset Multiplier']);
set_param([mdl, '/Reset Multiplier'], 'Inputs', '**', 'Position', [850, 310, 880, 340]);

% 5. Connect the explicit loop
% The memory output (previous time) feeds into the Adder
add_line(mdl, 'Time Memory/1', 'Time Adder/1', 'autorouting', 'on');
% The sample time feeds into the Adder
add_line(mdl, 'DROWSINESS_SAMPLE_TIME/1', 'Time Adder/2', 'autorouting', 'on');

% The Adder output feeds into the Multiplier
add_line(mdl, 'Time Adder/1', 'Reset Multiplier/2', 'autorouting', 'on');
% The Valid Closure feeds into the Multiplier (if 0, time resets to 0 instantly)
add_line(mdl, 'Valid Closure/1', 'Reset Multiplier/1', 'autorouting', 'on');

% The Multiplier output is the CURRENT CLOSURE TIME.
% It feeds into the Memory for the next step, the Scope, and the Threshold check.
add_line(mdl, 'Reset Multiplier/1', 'Time Memory/1', 'autorouting', 'on');
add_line(mdl, 'Reset Multiplier/1', 'CLOSURE_DURATION Scope/1', 'autorouting', 'on');
add_line(mdl, 'Reset Multiplier/1', 'Drowsiness Check/1', 'autorouting', 'on');

% Clean up Scope Names per requested diagnostics
% Ensure Scopes are well labelled
try set_param([mdl, '/EYE_CLOSED Scope'], 'Name', 'VALID_CLOSURE Scope'); catch, end
try set_param([mdl, '/CLOSURE_DURATION Scope'], 'Name', 'CLOSURE_TIMER Scope'); catch, end

% Verify logic using Simulink verification command
set_param(mdl, 'SolverType', 'Fixed-step');
set_param(mdl, 'FixedStep', '0.05');
set_param(mdl, 'SimulationCommand', 'update');
disp('Explicit deterministic timer compiled successfully.');

save_system(mdl);
close_system(mdl);
