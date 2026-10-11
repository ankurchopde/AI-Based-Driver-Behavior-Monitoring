% clean_simulink_layout.m
mdl = 'driver_monitor_sim_mediapipe';
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Clean Obsolete Blocks
% The MATLAB Function block handles windowing internally, so the external Blink Accumulator is obsolete.
try delete_line(mdl, 'BLINK_To_Double/1', 'Blink Adder/1'); catch, end
try delete_line(mdl, 'Blink Mem/1', 'Blink Adder/2'); catch, end
try delete_line(mdl, 'Blink Adder/1', 'Blink Mem/1'); catch, end
try delete_block([mdl, '/Blink Adder']); catch, end
try delete_block([mdl, '/Blink Mem']); catch, end

% 2. Auto-route all lines for straightness first
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i=1:length(lines)
    try set_param(lines(i), 'autorouting', 'on'); catch, end
end

% 3. Set Explicit Bounding Boxes

% SECTION 1: INPUT
set_param([mdl, '/Native UDP Receiver'], 'Position', [20, 250, 140, 310]);
set_param([mdl, '/UDP Status Terminator'], 'Position', [180, 310, 200, 330]);
set_param([mdl, '/MediaPipe DEMUX'], 'Position', [200, 200, 210, 280]);

% SECTION 2: EAR PROCESSING
set_param([mdl, '/EAR MA'], 'Position', [300, 150, 360, 190]);

% Blink Logic
set_param([mdl, '/BLINK_THRESH'], 'Position', [400, 70, 450, 90]);
set_param([mdl, '/EAR < 0.173'], 'Position', [500, 80, 530, 110]);
set_param([mdl, '/BLINK_ACTIVE'], 'Position', [600, 100, 630, 130]);
set_param([mdl, '/Detect Blink End'], 'Position', [680, 110, 720, 140]);
set_param([mdl, '/BLINK_EVENT'], 'Position', [760, 110, 790, 140]);
set_param([mdl, '/BLINK_To_Double'], 'Position', [840, 110, 880, 140]);

% Microsleep Logic
set_param([mdl, '/MICROSLEEP_THRESH'], 'Position', [400, 180, 450, 200]);
set_param([mdl, '/EAR < 0.138'], 'Position', [500, 190, 530, 220]);
set_param([mdl, '/MICROSLEEP_ACTIVE'], 'Position', [600, 200, 630, 230]);
set_param([mdl, '/MS To Double'], 'Position', [680, 200, 720, 230]);

set_param([mdl, '/DT_CONSTANT'], 'Position', [700, 250, 740, 270]);
set_param([mdl, '/MS_Add'], 'Position', [780, 210, 810, 240]);
set_param([mdl, '/MS_Mult'], 'Position', [860, 220, 890, 250]);
set_param([mdl, '/MS_Mem'], 'Position', [860, 280, 890, 310], 'Orientation', 'left');

% SECTION 3: MAR PROCESSING
set_param([mdl, '/MAR MA'], 'Position', [300, 350, 360, 390]);
set_param([mdl, '/YAWN_THRESH'], 'Position', [400, 350, 450, 370]);
set_param([mdl, '/MAR > 0.247'], 'Position', [500, 360, 530, 390]);
set_param([mdl, '/YAWN_ACTIVE'], 'Position', [600, 380, 630, 410]);
set_param([mdl, '/YAWN_EVENT'], 'Position', [680, 390, 720, 420]);
set_param([mdl, '/YAWN_To_Double'], 'Position', [760, 390, 800, 420]);

% SECTION 4: FEATURE SCOPES (Aligned vertically at x=950)
set_param([mdl, '/SMOOTHED_EAR Scope'], 'Position', [950, 50, 980, 80]);
set_param([mdl, '/BLINK_EVENT Scope'], 'Position', [950, 110, 980, 140]);
set_param([mdl, '/MICROSLEEP_DURATION Scope'], 'Position', [950, 170, 980, 200]);
set_param([mdl, '/YAWN_ACTIVE Scope'], 'Position', [950, 330, 980, 360]);
set_param([mdl, '/SMOOTHED_MAR Scope'], 'Position', [950, 390, 980, 420]);

% SECTION 5: FINAL DECISION
set_param([mdl, '/Drowsiness State Machine'], 'Position', [1050, 220, 1180, 310]);
set_param([mdl, '/DROWSINESS_STATE Scope'], 'Position', [1250, 200, 1280, 230]);
set_param([mdl, '/DROWSINESS_ALERT Scope'], 'Position', [1250, 290, 1280, 320]);


% 4. Manage Annotations
anns = find_system(mdl, 'FindAll', 'on', 'Type', 'annotation');
for i=1:length(anns)
    txt = get_param(anns(i), 'Text');
    if contains(txt, 'NORMAL')
        set_param(anns(i), 'Position', [1050, 350]);
    elseif contains(txt, 'CANDIDATE EAR')
        set_param(anns(i), 'Position', [50, 50]);
    elseif contains(txt, 'Temporal closure')
        set_param(anns(i), 'Position', [50, 70]);
    elseif contains(txt, 'Prototype')
        set_param(anns(i), 'Position', [50, 90]);
    elseif contains(txt, 'timing must be verified')
        set_param(anns(i), 'Position', [1050, 400]);
    else
        % Delete unknown/duplicate annotations
        try delete(anns(i)); catch, end
    end
end

% 5. Apply Smart Auto-Routing
% This forces Simulink to draw the lines orthogonally without passing through blocks
% using Simulink's built in arrange functionality for lines only if we can, 
% but setting 'autorouting' 'smart' works well.
lines = find_system(mdl, 'FindAll', 'on', 'Type', 'line');
for i=1:length(lines)
    try set_param(lines(i), 'autorouting', 'smart'); catch, end
end

% 6. Compile Model
set_param(mdl, 'SimulationCommand', 'update');
disp('Model updated and successfully arranged!');
save_system(mdl);
close_system(mdl);
