% create_udp_simulink_test.m
mdl = 'udp_simulink_test';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end

if exist([mdl, '.slx'], 'file')
    delete([mdl, '.slx']);
end

new_system(mdl);

% 1. Add UDP MATLAB System
add_block('simulink/User-Defined Functions/MATLAB System', [mdl, '/UDP Receiver']);
set_param([mdl, '/UDP Receiver'], 'System', 'UDPReceiverSystem');
set_param([mdl, '/UDP Receiver'], 'Position', [100, 100, 250, 160]);

% 2. Add Demux
add_block('simulink/Signal Routing/Demux', [mdl, '/Demux']);
set_param([mdl, '/Demux'], 'Outputs', '3');
set_param([mdl, '/Demux'], 'Position', [320, 90, 325, 170]);
set_param([mdl, '/Demux'], 'DisplayOption', 'bar');

% 3. Add Scopes
add_block('simulink/Sinks/Scope', [mdl, '/FACE Scope']);
set_param([mdl, '/FACE Scope'], 'Position', [420, 70, 450, 100]);

add_block('simulink/Sinks/Scope', [mdl, '/EYES Scope']);
set_param([mdl, '/EYES Scope'], 'Position', [420, 115, 450, 145]);

add_block('simulink/Sinks/Scope', [mdl, '/EAR Scope']);
set_param([mdl, '/EAR Scope'], 'Position', [420, 160, 450, 190]);

% 4. Connect Block Ports
add_line(mdl, 'UDP Receiver/1', 'Demux/1');
add_line(mdl, 'Demux/1', 'FACE Scope/1');
add_line(mdl, 'Demux/2', 'EYES Scope/1');
add_line(mdl, 'Demux/3', 'EAR Scope/1');

% 5. Configure Model Settings
set_param(mdl, 'SolverType', 'Fixed-step');
set_param(mdl, 'FixedStep', '0.05'); % 20 Hz updates
set_param(mdl, 'StopTime', 'inf');

% Save
save_system(mdl);
disp('Isolated udp_simulink_test.slx generated successfully.');
