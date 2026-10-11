% add_mar_to_simulink.m
mdl = 'driver_monitor_sim_mediapipe';

if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(mdl);

% 1. Delete all TEST scopes to clean up the model
try delete_line(mdl, 'MediaPipe DEMUX/1', 'TEST SCOPE Face/1'); catch, end
try delete_line(mdl, 'MediaPipe DEMUX/2', 'TEST SCOPE Eye/1'); catch, end
try delete_line(mdl, 'EAR < Thresh/1', 'TEST SCOPE EAR<Thresh/1'); catch, end
try delete_line(mdl, 'Valid Closure/1', 'TEST SCOPE Valid Closure/1'); catch, end

try delete_block([mdl, '/TEST SCOPE Face']); catch, end
try delete_block([mdl, '/TEST SCOPE Eye']); catch, end
try delete_block([mdl, '/TEST SCOPE EAR<Thresh']); catch, end
try delete_block([mdl, '/TEST SCOPE Valid Closure']); catch, end

% 2. Delete EYES Scope (it's now obsolete since packet changed)
try delete_line(mdl, 'MediaPipe DEMUX/2', 'EYES Scope/1'); catch, end
try delete_block([mdl, '/EYES Scope']); catch, end

% 3. The Demux now outputs [Face, EAR, MAR].
% We need to route Demux/2 (EAR) to the EAR Scope AND the EAR logic.
% Let's delete the old lines from Demux to EAR Scope and EAR Logic
try delete_line(mdl, 'MediaPipe DEMUX/3', 'EAR Scope/1'); catch, end
try delete_line(mdl, 'MediaPipe DEMUX/3', 'EAR < Thresh/1'); catch, end

% Reconnect Demux/2 to EAR Scope and EAR Logic
add_line(mdl, 'MediaPipe DEMUX/2', 'EAR Scope/1', 'autorouting', 'on');
add_line(mdl, 'MediaPipe DEMUX/2', 'EAR < Thresh/1', 'autorouting', 'on');

% 4. Add MAR Scope and connect to Demux/3
try add_block('simulink/Sinks/Scope', [mdl, '/MAR Scope']); catch, end
set_param([mdl, '/MAR Scope'], 'Position', [420, 275, 450, 305]);
add_line(mdl, 'MediaPipe DEMUX/3', 'MAR Scope/1', 'autorouting', 'on');

% Adjust EAR Scope position to keep it clean
set_param([mdl, '/EAR Scope'], 'Position', [420, 215, 450, 245]);

% Ensure pacing is still ON just in case
set_param(mdl, 'EnablePacing', 'on');
set_param(mdl, 'PacingRate', '1');

% 5. Verify compilation
set_param(mdl, 'SimulationCommand', 'update');
disp('Model updated with MAR signal successfully!');

save_system(mdl);
close_system(mdl);
