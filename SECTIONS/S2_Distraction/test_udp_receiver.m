% test_udp_receiver.m
udp = dsp.UDPReceiver('LocalIPPort', 5001, 'ReceiveBufferSize', 8192, ...
    'MaximumMessageLength', 64, 'MessageDataType', 'double', 'IsMessageComplex', false);
sender = dsp.UDPSender('RemoteIPPort', 5001, 'RemoteIPAddress', '127.0.0.1');

test_data = double([1 2 3 4 5 6 7 8]');
sender(test_data);

for i=1:10
    pause(0.1);
    data = udp();
    if ~isempty(data)
        fprintf('Iter %d: Data received. Class: %s, Size: %dx%d\n', i, class(data), size(data, 1), size(data, 2));
        disp(data);
        break;
    end
end
if isempty(data)
    fprintf('Data is empty!\n');
end

release(udp);
release(sender);
