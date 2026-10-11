models = {
    'SECTIONS/S1_Drowsiness/driver_monitor_sim_mediapipe.slx',
    'SECTIONS/S2_Distraction/driver_monitor_sim_distraction.slx',
    'SECTIONS/S3_Driver_Identification/driver_monitor_sim_identification.slx'
};

for i = 1:numel(models)
    try
        fprintf('Testing %s...\n', models{i});
        [path, name, ~] = fileparts(models{i});
        cd(path);
        load_system(name);
        set_param(name, 'SimulationCommand', 'update'); % Compile diagram
        fprintf('PASS: %s\n', name);
        close_system(name, 0);
        cd('../../');
    catch ME
        fprintf('FAIL: %s\n', models{i});
        disp(ME.message);
        try; close_system(name, 0); catch; end;
        cd('../../');
    end
end
