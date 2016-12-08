
function Dirs = cfg_create_paths(ctapRoot, id, srcid)
% Determine source and savepaths for a pipe

Dirs.ctapRoot = ctapRoot;
    
    
if isempty(srcid)
    % First pipe, raw data file from MC as source
    Dirs.branchSource = ''; 
    Dirs.analysisRoot = fullfile(Dirs.ctapRoot, id, 'this');
    
else
    % Subsequent pipe, previous pipes as source 
    parts = strsplit(srcid,'#');
    
    srcStep = parts{end};
    parts = parts(1:(end-1));

    Dirs.branchSource = fullfile(Dirs.ctapRoot, parts{:}, 'this', srcStep); 
    Dirs.analysisRoot = fullfile(Dirs.ctapRoot, parts{:}, id, 'this');
end