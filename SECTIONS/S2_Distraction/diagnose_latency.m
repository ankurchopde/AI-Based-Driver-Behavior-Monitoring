% diagnose_latency.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Check Model Sample Time
fixed_step = get_param(mdl, 'FixedStep');
simulink_fps = 1 / str2double(fixed_step);
disp(['Simulink Fixed-Step: ', fixed_step, ' s (', num2str(simulink_fps), ' Hz)']);

% 2. Check UDP Receiver Parameters
try
    udp_block = [mdl, '/Native UDP Receiver'];
    sample_time = get_param(udp_block, 'sampletime');
    disp(['UDP Receive Block Sample Time: ', sample_time]);
    
    receive_buffer = get_param(udp_block, 'ReceiveBufferSize');
    disp(['UDP Receive Buffer Size: ', receive_buffer]);
    
catch ME
    disp(['Error reading UDP block: ', ME.message]);
end

% 3. Check EAR Moving Average group delay
try
    ma_block = [mdl, '/EAR MA'];
    coeffs = get_param(ma_block, 'NumCoeffs');
    disp(['Moving Average Coefficients: ', coeffs]);
catch
end

disp('Diagnosis complete. Closing model.');
close_system(mdl, 0);
