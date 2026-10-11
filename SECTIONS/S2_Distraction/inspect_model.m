try
    disp('Loading model...');
    load_system('driver_monitor_sim');
    
    disp('Blocks:');
    blocks = find_system('driver_monitor_sim', 'SearchDepth', 1, 'Type', 'block');
    for i=1:length(blocks)
        disp(blocks{i});
        disp(['  Type: ', get_param(blocks{i}, 'BlockType')]);
    end
    
    disp('Lines:');
    lines = find_system('driver_monitor_sim', 'FindAll', 'on', 'Type', 'line');
    for i=1:length(lines)
        src = get_param(lines(i), 'SrcBlockHandle');
        dst = get_param(lines(i), 'DstBlockHandle');
        
        if src ~= -1
            srcName = get_param(src, 'Name');
        else
            srcName = 'none';
        end
        
        if iscell(dst)
            dstNames = '';
            for j=1:length(dst)
                if dst{j} ~= -1
                    dstNames = [dstNames, ' ', get_param(dst{j}, 'Name')];
                end
            end
        else
            dstNames = '';
            for j=1:length(dst)
                if dst(j) ~= -1
                    dstNames = [dstNames, ' ', get_param(dst(j), 'Name')];
                end
            end
        end
        disp(['Line: ', srcName, ' -> ', dstNames]);
    end
    
    disp('Success inspecting model.');
catch ME
    disp(ME.message);
end
