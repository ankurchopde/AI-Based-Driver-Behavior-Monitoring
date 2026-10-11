function [state, confidence] = predictDistraction(model, headYaw, headPitch, headRoll)
    % predictDistraction - Predicts distraction state based on Head Pose
    % Inputs:
    %   model     - The trained Distraction Classification Tree model
    %   headYaw   - Head Pose Yaw
    %   headPitch - Head Pose Pitch
    %   headRoll  - Head Pose Roll
    % Outputs:
    %   state      - Predicted state ('SAFE_DRIVING' or 'DISTRACTED')
    %   confidence - Prediction confidence
    
    if isnan(headYaw) || isnan(headPitch) || isnan(headRoll) || isempty(headYaw)
        state = 'UNKNOWN';
        confidence = 0;
        return;
    end
    
    X = [headYaw, headPitch, headRoll];
    
    [Y_pred, scores] = predict(model, X);
    
    state = char(Y_pred(1));
    confidence = max(scores(1, :));
end
