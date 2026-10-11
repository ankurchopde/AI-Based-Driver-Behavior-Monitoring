try
    new_system('test_model');
    add_block('simulink/User-Defined Functions/MATLAB System', 'test_model/MSB');
    params = get_param('test_model/MSB', 'DialogParameters');
    disp(fieldnames(params));
    % Check what SimulateUsing parameter is called
    disp('SimulateUsing parameter name:');
    if isfield(params, 'SimulateUsing')
        disp('SimulateUsing exists');
    end
catch ME
    disp(ME.message);
end
