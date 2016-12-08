function file = file_loadable(filename, extns)
%FILE_LOADABLE - checks that a given filename can be loaded
%
% Description:
%   Tries to discover if the file that is named actually exists, and has
%   an extension where ismember(extns)==True, such that the calling 
%   function can actually load or otherwise handle the file. 
%   To find a file that does exist, the filename must be either a
%   complete path or the file must be on the Matlab path or relative to
%   the current working directory.
%
% Syntax:
%   file = file_loadable(filename, extns);
%
% Inputs:
%   filename    string containing one of the following options:
%               - the complete file path
%               - the file name with extension
%               - file name without extension
%   
%   extns       a cell array of strings with extensions that the caller can
%               handle/load.
%
% Outputs:
%   file        Matlab-type struct with fields:
%       name        bare file name, no path, no extension
%       date        see dir()
%       bytes       see dir()
%       isdir       see dir()
%       datenum     see dir()
%               Additional fields are:
%       path        complete path which is passed
%       ext         '' if the file can't be found, otherwise returns the
%                   extension of the file that was found
%       load        True if file can be handled by caller, otherwise false
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    [pathstr, filename, ext, file] = get_file_parts(filename);
catch ME,
    error(ME.message);
end
% Check format and file existence
% If no extension given, check if a file exists with any supported ext
if isempty(ext)
    if isempty(filename), filename = '*'; end
    for i = 1:numel(extns)
        tst_ext = fullfile(pathstr, [filename extns{i}]);
        tmp = dir(tst_ext);
        if numel(tmp) > 0
            file = tmp(1);
            warning('Extension %s matches multiple files - using first: %s'...
                , tst_ext, file.name);
            file.ext = extns{i};
            file.path = pathstr;
            file.load = 1;
            break;
        end
    end
% else check if the given file exists
elseif sum(strcmpi(ext, extns)) > 0 && ~isempty(file)
    file.load = 1;
end

end % file_loadable
