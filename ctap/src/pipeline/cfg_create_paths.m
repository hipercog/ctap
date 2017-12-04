
function Dirs = cfg_create_paths(ctapRoot, id, srcid, has_multiple_src)
%CFG_CREATE_PATHS() determine source and savepaths for a branched pipe
%
% Syntax: 
%   Dirs = cfg_create_paths(ctapRoot, id, srcid, has_multiple_src)
%
% Inputs:
%   ctapRoot          string, Root directory of CTAP results
%   id                string, Analysis branch id
%   srcid             string, special definition of a relative source
%   has_multiple_src  boolean, true if pipe has specified multiple sources,
%                     default = false
%                     N.B. pipe that was initially called with multiple sources
%                     cannnot be later rerun with a single source, due to
%                     the way this function creates paths. To rerun a pipe
%                     for only a single source, give it a second dummy source,
%                     i.e. '' (CTAP_pipeline_brancher skips empty sources)

if nargin < 4
   has_multiple_src = false; 
end

Dirs.ctapRoot = ctapRoot;
    
    
if isempty(srcid)
    % First pipe, raw data file from MC as source
    Dirs.branchSource = ''; 
    Dirs.analysisRoot = fullfile(Dirs.ctapRoot, id, 'this');
    
else
    % Subsequent pipe, previous pipes as source 
    parts = strsplit(srcid, '#');
    
    srcStep = parts{end};
    parts = parts(1:(end-1));

    Dirs.branchSource = fullfile(Dirs.ctapRoot, parts{:}, 'this', srcStep);
    if has_multiple_src
        Dirs.analysisRoot = fullfile(Dirs.ctapRoot, parts{:}, id, 'this'...
            , ['src-' srcStep]);
    else
        Dirs.analysisRoot = fullfile(Dirs.ctapRoot, parts{:}, id, 'this');
    end
end