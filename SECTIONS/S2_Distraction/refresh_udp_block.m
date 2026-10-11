% refresh_udp_block.m
mdl = 'driver_monitor_sim_distraction';
load_system(mdl);

udpBlock = [mdl, '/UDP Receive'];
% Refresh the MATLAB System block by re-setting its System property
set_param(udpBlock, 'System', 'UDPReceiverSystemDistraction');

disp('Compiling...');
set_param(mdl, 'SimulationCommand', 'update');
save_system(mdl);
disp('Saved successfully');
close_system(mdl, 0);
