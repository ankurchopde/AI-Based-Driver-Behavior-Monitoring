function img = camera_source(~)

persistent cam

if isempty(cam)
    cam = webcam(1);
end

img = snapshot(cam);

end