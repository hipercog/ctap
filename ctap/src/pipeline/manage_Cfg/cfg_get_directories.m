function Dirs = cfg_get_directories(Cfg, ctap, srcid)
% todo: remove this file once not needed anymore, see cfg_create_paths.m

% Determine source and savepaths for a pipe

Dirs.projectRoot = Basecfg.env.paths.projectRoot;
Dirs.baseRoot = Basecfg.env.paths.baseRoot;
    
    
if isempty(srcid)
    % First pipe, raw data file from MC as source
    Dirs.branchSource = ''; 
    Dirs.analysisRoot = fullfile(Dirs.baseRoot, Cfg.id, 'this');
    
else
    parts = strsplit(srcid,'#');
    
    % Subsequent pipe, previous pipes as source
    srcStep = parts{end};
    parts = parts(1:(end-1));

    Dirs.branchSource = fullfile(Dirs.baseRoot, parts{:}, 'this', srcStep); 
    Dirs.analysisRoot = fullfile(Dirs.baseRoot, parts{:}, Cfg.id, 'this');
end