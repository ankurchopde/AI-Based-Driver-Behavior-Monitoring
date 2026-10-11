% fix_datatype.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% Delete line from BLINK_EVENT to Adder
try delete_line(mdl, 'BLINK_EVENT/1', 'Blink Adder/1'); catch, end

% Insert Data Type Conversion
add_block('simulink/Signal Attributes/Data Type Conversion', [mdl, '/To Double']);
set_param([mdl, '/To Double'], 'OutDataTypeStr', 'double', 'Position', [800, 100, 830, 130]);

add_line(mdl, 'BLINK_EVENT/1', 'To Double/1', 'autorouting', 'on');
add_line(mdl, 'To Double/1', 'Blink Adder/1', 'autorouting', 'on');

% Set Unit Delay output to double just to be absolutely sure
set_param([mdl, '/Blink Mem'], 'OutDataTypeStr', 'double');

% Compile
set_param(mdl, 'SimulationCommand', 'update');
disp('Data type mismatch fixed! Model updated successfully.');

save_system(mdl);
close_system(mdl);
