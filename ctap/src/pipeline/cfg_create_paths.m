function Dirs = cfg_create_paths(ctapRoot, id, srcid, srcix)
%CFG_CREATE_PATHS() determine source and savepaths for a branched pipe
%
% Syntax: 
%   Dirs = cfg_create_paths(ctapRoot, id, srcid, has_multiple_src)
%
% Inputs:
%   ctapRoot          string, Root directory of CTAP results
%   id                string, Analysis branch id
%   srcid             string, special definition of a relative source
%   srcix             scalar, source to select from multiple 'srcid's, default=1
% 
% NOTE:
%   If pipe has specified multiple source steps, they are either all taken from
%   the same pipe, or from different pipes. IFF sources are all from same pipe, 
%   path creation must change to prevent overwriting, prepending the path
%   with a folder named for the stepset source. 
% 
%     N.B. pipe that was initially called with multiple sources cannnot be later 
%     rerun with a single source, due to the way this function creates paths. 
%     To rerun a pipe for only a single source, give it a second dummy source,
%     i.e. '' (CTAP_pipeline_brancher skips empty sources)


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('ctapRoot', @ischar);
p.addRequired('id', @ischar);
p.addRequired('srcid', @iscell);
p.addOptional('srcix', 1, @(x) isscalar(x) & isnumeric(x));
p.parse(ctapRoot, id, srcid, srcix);
% Arg = p.Results;


%% Parse srcid to get a single path string
has_multiple_src = false;
numsrc = numel(srcid);
% test if multiple sources
if numsrc > 1
    parts = cell(numsrc, 1);
    for s = 1:numsrc
        part = strsplit(srcid{s}, '#');
        parts{s} = cell2mat(part(1:(end-1)));
    end
    if any(ismember(parts(srcix), parts(1:numsrc ~= srcix)))
        has_multiple_src = true;
    end
    srcid = srcid{srcix};
else
    srcid = srcid{:};
end

Dirs.ctapRoot = ctapRoot;


%% Create paths
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