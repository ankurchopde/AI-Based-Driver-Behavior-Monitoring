classdef UDPReceiverSystemDistraction < matlab.System
    % UDPReceiverSystemDistraction Receives [Face, EAR, MAR, YAW, PITCH, ROLL] telemetry over UDP.
    
    properties (Access = private)
        udpObj
        lastData % Buffer to hold last known value if UDP packet hasn't arrived this step
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            % Initialize the UDP receiver on port 5000
            obj.udpObj = dsp.UDPReceiver('LocalIPPort', 5000, ...
                                         'ReceiveBufferSize', 8192, ...
                                         'MaximumMessageLength', 112, ... % 14 doubles * 8 bytes
                                         'MessageDataType', 'double', ...
                                         'IsMessageComplex', false);
            % Initialize with zero state
            obj.lastData = [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];
        end
        
        function telemetry = stepImpl(obj)
            % Receive data (non-blocking)
            data = obj.udpObj();
            if ~isempty(data) && length(data) == 14
                % Ensure it is a 14x1 column vector for Simulink DEMUX
                obj.lastData = double(data(:)); 
            end
            telemetry = obj.lastData;
        end
        
        function releaseImpl(obj)
            % Clean up port lock when Simulink stops
            release(obj.udpObj);
        end
        
        % Define output properties for Simulink
        function out = getOutputSizeImpl(~)
            out = [14 1];
        end
        
        function out = getOutputDataTypeImpl(~)
            out = 'double';
        end
        
        function out = isOutputComplexImpl(~)
            out = false;
        end
        
        function out = isOutputFixedSizeImpl(~)
            out = true;
        end
    end
end
