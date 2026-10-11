% create_master_scope.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. DELETE ALL INDIVIDUAL SCOPES
oldScopes = {
    '/SMOOTHED_EAR Scope', ...
    '/BLINK_EVENT Scope', ...
    '/MICROSLEEP_DURATION Scope', ...
    '/YAWN_ACTIVE Scope', ...
    '/SMOOTHED_MAR Scope', ...
    '/DROWSINESS_STATE Scope', ...
    '/DROWSINESS_ALERT Scope'
};

for i = 1:length(oldScopes)
    try delete_line(mdl, get_param([mdl, oldScopes{i}], 'LineHandles').Inport(1)); catch, end
    try delete_block([mdl, oldScopes{i}]); catch, end
end

% 2. CREATE MASTER SCOPE
scopeName = [mdl, '/FINAL DROWSINESS WAVEFORMS'];
try add_block('simulink/Sinks/Scope', scopeName); catch, end
set_param(scopeName, 'Position', [1250, 100, 1300, 450]); % Tall block on the far right
set_param(scopeName, 'NumInputPorts', '9');

% Attempt to configure layout to 9x1
try
    scopeObj = get_param(scopeName, 'ScopeConfiguration');
    scopeObj.Layout = [9 1];
    scopeObj.Title = 'Final Drowsiness Waveforms';
catch
    disp('Note: Scope Layout property could not be set programmatically. Will default to tabbed or overlay.');
end

% 3. ROUTE SIGNALS TO SCOPE PORTS & NAME THEM
% Port 1: RAW EAR
h = add_line(mdl, 'MediaPipe DEMUX/2', 'FINAL DROWSINESS WAVEFORMS/1', 'autorouting', 'on');
try set_param(h, 'Name', 'RAW EAR'); catch, end

% Port 2: SMOOTHED EAR
h = add_line(mdl, 'EAR MA/1', 'FINAL DROWSINESS WAVEFORMS/2', 'autorouting', 'on');
try set_param(h, 'Name', 'SMOOTHED EAR'); catch, end

% Port 3: RAW MAR
h = add_line(mdl, 'MediaPipe DEMUX/3', 'FINAL DROWSINESS WAVEFORMS/3', 'autorouting', 'on');
try set_param(h, 'Name', 'RAW MAR'); catch, end

% Port 4: SMOOTHED MAR
h = add_line(mdl, 'MAR MA/1', 'FINAL DROWSINESS WAVEFORMS/4', 'autorouting', 'on');
try set_param(h, 'Name', 'SMOOTHED MAR'); catch, end

% Port 5: BLINK EVENT
h = add_line(mdl, 'BLINK_EVENT/1', 'FINAL DROWSINESS WAVEFORMS/5', 'autorouting', 'on');
try set_param(h, 'Name', 'BLINK EVENT'); catch, end

% Port 6: MICROSLEEP DURATION
h = add_line(mdl, 'MS_Mult/1', 'FINAL DROWSINESS WAVEFORMS/6', 'autorouting', 'on');
try set_param(h, 'Name', 'MICROSLEEP DURATION'); catch, end

% Port 7: YAWN ACTIVE
h = add_line(mdl, 'YAWN_ACTIVE/1', 'FINAL DROWSINESS WAVEFORMS/7', 'autorouting', 'on');
try set_param(h, 'Name', 'YAWN ACTIVE'); catch, end

% Port 8: DROWSINESS STATE
h = add_line(mdl, 'Drowsiness State Machine/1', 'FINAL DROWSINESS WAVEFORMS/8', 'autorouting', 'on');
try set_param(h, 'Name', 'DROWSINESS STATE'); catch, end

% Port 9: DROWSINESS ALERT
h = add_line(mdl, 'Drowsiness State Machine/2', 'FINAL DROWSINESS WAVEFORMS/9', 'autorouting', 'on');
try set_param(h, 'Name', 'DROWSINESS ALERT'); catch, end

% 4. SMART AUTO-ROUTING
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i=1:length(lines)
    try set_param(lines(i), 'autorouting', 'smart'); catch, end
end

% 5. VERIFY COMPILATION
set_param(mdl, 'SimulationCommand', 'update');
disp('Model compiled successfully with single Master Scope!');
save_system(mdl);
close_system(mdl);
