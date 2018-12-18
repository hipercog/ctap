function repstr = myReport( repstr, logfile, delim )
%MYREPORT displays a string and write to a given log file. 
%
% Description:
%       Will call disp() to write a simple string input to command, and
%       (optionally) calls fprintf() to write to given log file.
%       Will also attempt to parse a cell string array, and display its
%       components delimited by a given delimter string. In theory it does
%       this recursively, so multi-level cell arrays can be passed. 
%
% Syntax:
%   repstr = myReport( repstr, logfile, delim )
%
% Inputs:
%   'repstr'    unknown, string or cell string array to output
%   'logfile'   string, complete path to a log file
%               default = emtpy
%   'delim'     string, optional delimiter string
%               default = double space '  '
%
% Outputs:
%   'repstr'    string, formatted version of input
%
% See also:    unpackCellStr, myToString
%
% Version History:
% 12.11.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 3,  delim = '  '; end
    if nargin < 2,  logfile = []; end
    
    % Parse input
    if iscell(repstr)
        str = '';
        if any(cellfun(@iscell, repstr))
            repstr = unpackCellStr(repstr);
        end
        for i = 1:numel(repstr)
            str = [str myToString(repstr{i}) delim]; %#ok<*AGROW>
        end
        repstr = str;
    end
    
    flag = upper(repstr(1:min(numel(repstr),4)));
    switch flag
        case 'SHSH'
            repstr = strrep(repstr, 'SHSH', '');
        case 'FAIL'
            error(repstr(5:end))
        case 'WARN'
            warning off backtrace
            warning(repstr(5:end));
            warning on backtrace
        otherwise
            disp( repstr );
    end
    % add to log file if output directory is given
    if ~isempty(logfile)% && exist(logfile,'file')
        fid = fopen(logfile, 'a');
        fprintf(fid, '%s\n', repstr);
        fclose(fid);
    end
end
