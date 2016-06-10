function [pathstr, fname, ext, file] = get_file_parts(filename)
%GET_FILE_PARTS
%
% Description:
%    This is an extended version of fileparts(). Useful to retrieve the
%    complete platform-specific path string for a file, especially for 
%    which only the relative path is known. 
%    Also returns the Matlab file struct if file exists. For over-matched
%    filenames (i.e. wildcards), returns the first matching file. If no
%    matching file is found, returns a struct with null fields
%
% Syntax:
%   [pathstr,filename,ext,file]=get_file_parts(filename)
%
% Inputs:
%   filename    string containing one of the following options:
%               - the complete file path
%               - the file name with extension
%               - file name without extension
%               - one of the above with wildcards
%
% Outputs:
%   pathstr     complete path, output of fileparts()
%   fname       bare file name, no path, no extension, output of fileparts()
%   ext         extension, output of fileparts()
%   file        Matlab-style file struct, assuming file actually exists
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also:  
%
% Copyright 2014- Benjamin Cowley, FIOH, benjamin.cowley@ttl.fi
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isdir(filename)
    filename = fullfile(filename, filesep);
end
[pathstr, fname, ext] = fileparts(filename);
pathstr = strrep(pathstr, '\', filesep);
% file's details from matlab 'file' struct
file = dir(fullfile(pathstr, [fname ext]));
if numel(file) == 0
    warning('zero actual files resolved with filename: %s', filename);
    file = struct('name', '', 'date', datestr(now), 'bytes', 0, 'isdir', 0,...
        'datenum', now, 'path', '', 'ext', '', 'load', 0);
    return;
elseif numel(file) > 1
    file = file(1);
    warning('Filename %s resolved to multiple files - using first: %s'...
        , filename, file.name);
end

% if pathstr is empty, but we get this far, the file must really exist
% so path should be retrieved using which()
if isempty(pathstr)
    [pathstr,~,~] = fileparts(which(file(1).name));
end

file.path = pathstr;
file.ext = ext;

end
