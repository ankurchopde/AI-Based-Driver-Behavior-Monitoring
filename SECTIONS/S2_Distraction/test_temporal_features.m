% test_temporal_features.m
dt = 0.05;
time_array = 0:dt:10;
N = length(time_array);

face = ones(1,N);
ear_raw = 0.3 * ones(1,N);
mar_raw = 0.1 * ones(1,N);

% Test 1 & 2 & 3: Blink and Microsleep
% 1s to 2.5s: EAR drops to 0.10 (Blink trigger and Microsleep trigger)
ear_raw(time_array >= 1 & time_array < 2.5) = 0.10;

% Test 4: Yawn
% 4s to 6s: MAR rises to 0.5
mar_raw(time_array >= 4 & time_array < 6) = 0.50;

% Test 5: Face loss
% 8s to 9s: Face = 0, even though EAR is low and MAR is high
ear_raw(time_array >= 8 & time_array < 9) = 0.10;
mar_raw(time_array >= 8 & time_array < 9) = 0.50;
face(time_array >= 8 & time_array < 9) = 0;


% Emulate 10-sample Moving Average
ear_ma = filter(ones(1,10)/10, 1, ear_raw);
% Initial condition for EAR was 0.3, filter logic needs to handle padding, 
% but practically it smooths to the target. Let's assume perfectly smoothed for logic validation.
mar_ma = filter(ones(1,10)/10, 1, mar_raw);

% We will just use the simulated inputs to test logic bounds
blink_active = (ear_ma < 0.173) & face;
blink_event = [0, diff(blink_active)] < 0; % Falling edge of blink_active
blink_event = blink_event & face;

microsleep_active = (ear_ma < 0.138) & face;
ms_timer = zeros(1,N);
for k=2:N
    ms_timer(k) = (ms_timer(k-1) + dt) * microsleep_active(k);
end

yawn_active = (mar_ma > 0.247) & face;

disp('--- RUNNING FEATURE VERIFICATION ---');

disp('Test 1 & 2 & 3: Blink and Microsleep (1s to 2.5s)');
if sum(blink_event(time_array >= 1 & time_array <= 3)) == 1
    disp('  Blink Event Count: PASS');
else
    disp('  Blink Event Count: FAIL');
end

if max(ms_timer(time_array >= 1 & time_array <= 2.5)) > 1.0
    disp('  Microsleep Timer Accumulation: PASS');
else
    disp('  Microsleep Timer Accumulation: FAIL');
end

if max(ms_timer(time_array >= 2.6 & time_array <= 3.0)) == 0
    disp('  Microsleep Timer Reset: PASS');
else
    disp('  Microsleep Timer Reset: FAIL');
end

disp('Test 4: Yawn (4s to 6s)');
if any(yawn_active(time_array >= 4.5 & time_array <= 5.5) == 1)
    disp('  Yawn Active: PASS');
else
    disp('  Yawn Active: FAIL');
end

disp('Test 5: Face Validity (8s to 9s)');
if max(blink_event(time_array >= 8 & time_array < 9)) == 0 && ...
   max(ms_timer(time_array >= 8 & time_array < 9)) == 0 && ...
   max(yawn_active(time_array >= 8 & time_array < 9)) == 0
    disp('  Safe Reset on Face=0: PASS');
else
    disp('  Safe Reset on Face=0: FAIL');
end

disp('Verification complete.');
