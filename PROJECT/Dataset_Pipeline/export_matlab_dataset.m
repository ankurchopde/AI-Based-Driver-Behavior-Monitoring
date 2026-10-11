% export_matlab_dataset.m
% Loads the generated datasets and prepares them for Simulink

function export_matlab_dataset()
    disp('--- Starting MATLAB Dataset Export ---');
    
    % Files to process
    files = {
        'Section1_Drowsiness_Results.csv', 
        'Section2_Distraction_Results.csv', 
        'results/identification/Section3_Identification_Results.csv',
        'PROJECT/Data/processed/Driver_Monitoring_All_Sections.csv'
    };

    for i = 1:length(files)
        csv_filename = files{i};
        
        if exist(csv_filename, 'file')
            try
                opts = detectImportOptions(csv_filename);
                % Treat empty/'NaN' as missing numeric data automatically
                opts = setvartype(opts, 'double'); % Force all numeric where possible except names
                opts = setvartype(opts, 'File_Name', 'char'); % Keep filename string
                
                dataset_table = readtable(csv_filename, opts);
                disp(['Loaded: ', csv_filename, ' (', num2str(height(dataset_table)), ' frames)']);
                
                % Create a mat file output name
                [~, name, ~] = fileparts(csv_filename);
                mat_filename = [name, '.mat'];
                
                % Check if Timestamp_s exists for Simulink timeseries
                if ismember('Timestamp_s', dataset_table.Properties.VariableNames)
                    time_vec = dataset_table.Timestamp_s;
                    simulink_data = struct();
                    
                    % Map numerics into timeseries
                    vars = dataset_table.Properties.VariableNames;
                    for v = 1:length(vars)
                        var_name = vars{v};
                        if isnumeric(dataset_table.(var_name)) && ~strcmp(var_name, 'Timestamp_s')
                            ts = timeseries(dataset_table.(var_name), time_vec);
                            ts.Name = var_name;
                            simulink_data.(var_name) = ts;
                        end
                    end
                    
                    save(mat_filename, 'dataset_table', 'simulink_data', 'time_vec');
                    disp(['-> Exported timeseries struct to ', mat_filename]);
                else
                    save(mat_filename, 'dataset_table');
                    disp(['-> Exported raw table to ', mat_filename]);
                end
                
            catch ME
                disp(['Error processing ', csv_filename, ': ', ME.message]);
            end
        else
            disp(['File not found: ', csv_filename]);
        end
    end
    disp('--- MATLAB Dataset Export Complete ---');
end
