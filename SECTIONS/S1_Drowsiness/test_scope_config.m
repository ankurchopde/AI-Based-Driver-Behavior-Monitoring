try
    new_system('test_scope');
    add_block('simulink/Sinks/Scope', 'test_scope/DualScope');
    set_param('test_scope/DualScope', 'NumInputPorts', '2');
    
    % Let's see what parameters are available
    params = get_param('test_scope/DualScope', 'DialogParameters');
    disp('Scope DialogParameters:');
    disp(fieldnames(params)');
    
    % Try setting ScopeConfiguration
    scopeConfig = get_param('test_scope/DualScope', 'ScopeConfiguration');
    if ~isempty(scopeConfig)
        scopeConfig.NumInputPorts = '2';
        scopeConfig.LayoutDimensions = [2 1];
        disp('ScopeConfiguration layout set.');
    else
        disp('ScopeConfiguration is empty.');
    end
    
    save_system('test_scope');
    close_system('test_scope');
catch ME
    disp(ME.message);
end
