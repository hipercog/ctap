function [file_arr, files] = path2filearr(filepath, ext, filepattern, varargin)
%PATH2FILEARR - converts a given path and matching pattern to an array of files
%
% Example:
%   file_arr = path2filearr('<some dir with *.set files>', '*.set', 'control');
%
% Copyright(c) 2018 :
% Benjamin Cowley (ben.cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('filepath', @ischar)
p.addRequired('ext', @ischar)
p.addRequired('filepattern', @ischar)

p.addParameter('recurse', true, @islogical)

p.parse(filepath, ext, filepattern, varargin{:})
Arg = p.Results;


%% Check all is well
filepath = abspath(filepath);
if ~isfolder(filepath)
    error('path2filearr:bad_path', 'Path ''%s'' does NOT exist!', filepath)
end
if ~isempty(ext)
    ext = regexprep(ext, {'\*' '\.'}, '');
end


%% Find files:
% in one place
if ~Arg.recurse
    files = dir(fullfile(filepath, ext));
    file_arr = {files.name};
    file_arr = cellfun(@(x) fullfile(filepath, x), file_arr, 'Unif', false);
else
    % Recursively
    [files, file_arr] = subdirflt(filepath...
                        , 'patt_ext', ['*.' ext], 'filefilt', filepattern);
end

end