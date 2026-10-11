function models = loadDriverModels()
    % loadDriverModels - Loads the pre-trained Drowsiness and Distraction models
    disp('Loading Driver Monitoring Models...');
    models = struct();
    
    try
        % Load Drowsiness Model
        d = load('PROJECT/Models/drowsiness/drowsiness_model.mat');
        models.drowsiness = d.drowsiness_model;
        c1 = load('PROJECT/Models/drowsiness/drowsiness_classes.mat');
        models.drowsiness_classes = c1.drowsiness_classes;
        
        % Load Distraction Model
        d2 = load('PROJECT/Models/distraction/distraction_model.mat');
        models.distraction = d2.distraction_model;
        c2 = load('PROJECT/Models/distraction/distraction_classes.mat');
        models.distraction_classes = c2.distraction_classes;
        
        disp('Models loaded successfully.');
    catch ME
        disp(['Error loading models: ', ME.message]);
    end
end
