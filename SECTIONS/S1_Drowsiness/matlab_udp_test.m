% matlab_udp_test.m
% Connects to the Python MediaPipe UDP Stream and prints the telemetry

disp('Starting MATLAB UDP Receiver Test...');
disp('Make sure mediapipe_udp_sender.py is running in a separate terminal!');

try
    udpReceiver = dsp.UDPReceiver('LocalIPPort', 5000, ...
                                  'ReceiveBufferSize', 8192, ...
                                  'MaximumMessageLength', 24, ... % 3 doubles * 8 bytes = 24 bytes
                                  'MessageDataType', 'double', ...
                                  'IsMessageComplex', false);
catch ME
    error('dsp.UDPReceiver failed. Please ensure DSP System Toolbox is installed. Error: %s', ME.message);
end

disp('Listening on Port 5000...');
disp('Receiving 50 frames... (Press Ctrl+C to abort)');

framesReceived = 0;

while framesReceived < 50
    data = udpReceiver();
    
    if ~isempty(data)
        face = data(1);
        eye = data(2);
        ear = data(3);
        
        fprintf('Received from Python -> FACE: %.0f | EYE: %.0f | EAR: %.3f\n', face, eye, ear);
        framesReceived = framesReceived + 1;
    else
        pause(0.01); % Wait for data
    end
end

release(udpReceiver);
disp('Test completed successfully. UDP Bridge is confirmed!');
