function [state, confidence] = predictDrowsiness(model, EAR, MAR)
    % predictDrowsiness - Predicts driver drowsiness state based on EAR and MAR
    % Inputs:
    %   model - The trained Drowsiness Classification Tree model
    %   EAR   - Eye Aspect Ratio
    %   MAR   - Mouth Aspect Ratio
    % Outputs:
    %   state      - Predicted state ('AWAKE' or 'DROWSY')
    %   confidence - Prediction confidence (if supported, else 1.0)
    
    if isnan(EAR) || isnan(MAR) || isempty(EAR) || isempty(MAR)
        state = 'UNKNOWN';
        confidence = 0;
        return;
    end
    
    X = [EAR, MAR];
    
    % Use predict to get state
    [Y_pred, scores] = predict(model, X);
    
    % Y_pred is categorical
    state = char(Y_pred(1));
    confidence = max(scores(1, :));
end
