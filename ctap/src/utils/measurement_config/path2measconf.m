function MC = path2measconf(filepath, filepattern)
%PATH2MEASCONF - A wrapper for quick usage of filearr2measconf()
%
% Example:
%   MC = path2measconf('<some dir with *.set files>', '*.set');
%
% Authors: Jussi Korpela (FIOH, 2015)
% -------------------------------------------------------------------------
filepattern = strrep(filepattern, '*..', '*.');
files = dir(fullfile(filepath, filepattern));
file_arr = {files.name};
file_arr = cellfun(@(x) fullfile(filepath,x), file_arr, 'UniformOutput', false);

MC = filearr2measconf(file_arr);

end