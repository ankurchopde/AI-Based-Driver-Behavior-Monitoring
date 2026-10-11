try
    disp('Trying importNetworkFromONNX...');
    net = importNetworkFromONNX('fan2_68_landmark.onnx');
    disp('Imported successfully!');
    disp(net.Layers(1));
catch ME
    disp(['Error: ', ME.message]);
end
