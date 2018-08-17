function file_arr = path2filearr(filepath, filepattern)
%PATH2FILEARR - converts a given path and matching pattern to an array of files
%
% Example:
%   file_arr = path2filearr('<some dir with *.set files>', '*.set');
%
% Authors: Benjamin Cowley (HY, 2018)
% -------------------------------------------------------------------------
if ~isempty(filepattern)
    filepattern = strrep(filepattern, '*..', '*.');
end
files = dir(fullfile(filepath, filepattern));
file_arr = {files.name};
file_arr = cellfun(@(x) fullfile(filepath, x), file_arr, 'Unif', false);

end