% train_models.m
disp('--- Starting Model Training ---');

% Create directories
if ~exist('models', 'dir')
    mkdir('models');
end
if ~exist('PROJECT/Models/drowsiness', 'dir')
    mkdir('PROJECT/Models/drowsiness');
end
if ~exist('PROJECT/Models/distraction', 'dir')
    mkdir('PROJECT/Models/distraction');
end
if ~exist('PROJECT/Models/identification', 'dir')
    mkdir('PROJECT/Models/identification');
end

% 1. Load the dataset
disp('Loading dataset...');
opts = detectImportOptions('PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv');
opts = setvartype(opts, {'EAR', 'MAR', 'Head_Pose_Yaw', 'Head_Pose_Pitch', 'Head_Pose_Roll', 'Gaze_Direction_X', 'Gaze_Direction_Y'}, 'double');
% Treat others as char
data = readtable('PROJECT/Data/master/Driver_Monitoring_Master_Dataset.csv', opts);

% 2. Drowsiness Model
disp('--- Training Drowsiness Model ---');
% Features: EAR, MAR
drowsiness_idx = ~isnan(data.EAR) & ~isnan(data.MAR) & ...
    (strcmp(data.Drowsiness_Prediction, 'AWAKE') | strcmp(data.Drowsiness_Prediction, 'DROWSY'));
drowsiness_data = data(drowsiness_idx, :);

X_drowsiness = [drowsiness_data.EAR, drowsiness_data.MAR];
drowsiness_classes_str = cellstr(drowsiness_data.Drowsiness_Prediction);
Y_drowsiness = categorical(drowsiness_classes_str);

cv = cvpartition(Y_drowsiness, 'HoldOut', 0.2);
X_train = X_drowsiness(training(cv), :);
Y_train = Y_drowsiness(training(cv));
X_test = X_drowsiness(test(cv), :);
Y_test = Y_drowsiness(test(cv));

% Train decision tree (lightweight)
drowsiness_model = fitctree(X_train, Y_train, 'MinLeafSize', 10);
Y_pred = predict(drowsiness_model, X_test);

% Metrics
conf_mat = confusionmat(Y_test, Y_pred);
acc = sum(Y_pred == Y_test) / length(Y_test);
fprintf('Drowsiness Model Test Accuracy: %.2f%%\n', acc * 100);
disp('Confusion Matrix:');
disp(conf_mat);

% Save model & metadata
drowsiness_classes = categories(Y_drowsiness);
drowsiness_preprocessing = struct('features', {'EAR', 'MAR'}, 'normalization', 'none', 'input_size', 2);
save('PROJECT/Models/drowsiness/drowsiness_model.mat', 'drowsiness_model');
save('PROJECT/Models/drowsiness/drowsiness_classes.mat', 'drowsiness_classes');
save('PROJECT/Models/drowsiness/drowsiness_preprocessing.mat', 'drowsiness_preprocessing');


% 3. Distraction Model
disp('--- Training Distraction Model ---');
% Features: Head_Pose_Yaw, Head_Pose_Pitch, Head_Pose_Roll
distraction_idx = ~isnan(data.Head_Pose_Yaw) & ~isnan(data.Head_Pose_Pitch) & ~isnan(data.Head_Pose_Roll) & ...
    (strcmp(data.Distraction_Prediction, 'SAFE_DRIVING') | strcmp(data.Distraction_Prediction, 'DISTRACTED'));
distraction_data = data(distraction_idx, :);

X_distraction = [distraction_data.Head_Pose_Yaw, distraction_data.Head_Pose_Pitch, distraction_data.Head_Pose_Roll];
distraction_classes_str = cellstr(distraction_data.Distraction_Prediction);
Y_distraction = categorical(distraction_classes_str);

cv_dist = cvpartition(Y_distraction, 'HoldOut', 0.2);
X_train_d = X_distraction(training(cv_dist), :);
Y_train_d = Y_distraction(training(cv_dist));
X_test_d = X_distraction(test(cv_dist), :);
Y_test_d = Y_distraction(test(cv_dist));

distraction_model = fitctree(X_train_d, Y_train_d, 'MinLeafSize', 10);
Y_pred_d = predict(distraction_model, X_test_d);

acc_d = sum(Y_pred_d == Y_test_d) / length(Y_test_d);
fprintf('Distraction Model Test Accuracy: %.2f%%\n', acc_d * 100);
conf_mat_d = confusionmat(Y_test_d, Y_pred_d);
disp('Confusion Matrix:');
disp(conf_mat_d);

% Save model & metadata
distraction_classes = categories(Y_distraction);
distraction_preprocessing = struct('features', {'Head_Pose_Yaw', 'Head_Pose_Pitch', 'Head_Pose_Roll'}, 'normalization', 'none', 'input_size', 3);
save('PROJECT/Models/distraction/distraction_model.mat', 'distraction_model');
save('PROJECT/Models/distraction/distraction_classes.mat', 'distraction_classes');
save('PROJECT/Models/distraction/distraction_preprocessing.mat', 'distraction_preprocessing');

% 4. Identification Model
% For identification, the existing ONNX model should be copied to the models/identification folder
disp('--- Setting up Identification Model ---');
if exist('SECTIONS/S3_Driver_Identification/models/face_recognizer_fast.onnx', 'file')
    copyfile('SECTIONS/S3_Driver_Identification/models/face_recognizer_fast.onnx', 'PROJECT/Models/identification/');
    disp('Copied existing face_recognizer_fast.onnx to models/identification/');
    identification_classes = {'Known', 'Unknown'};
    identification_preprocessing = struct('input_size', [112, 112, 3], 'normalization', 'standard_sface');
    save('PROJECT/Models/identification/identification_classes.mat', 'identification_classes');
    save('PROJECT/Models/identification/identification_preprocessing.mat', 'identification_preprocessing');
else
    disp('Could not find face_recognizer_fast.onnx in SECTIONS/S3_Driver_Identification/models/');
end

disp('--- All Models Processed ---');
exit;
