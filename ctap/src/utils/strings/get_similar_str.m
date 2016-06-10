function str = get_similar_str(cellstr, str)
%GET_SIMILAR_STR get closest matching string from cell string array.
%
% Description:
%   returns the string from a cell array of strings which is
%   most similar to the given string. Useful for finding, e.g. which file from a
%   directory is named similarly to a given value. E.g. find the log file for a
%   given subject-name in an experiment
%
% Syntax:
%   str = get_similar_str(cellstr, str)
%
% Inputs:
%   'cellstr'   cell string array, candidates to match
%   'str'       string, string to match to
%
%
% Outputs:
%   'str'       string, closest matching string
%
% See also:    cellstrdist
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

% parameter entry order not important
if iscell(str)
    if ischar(cellstr)
        temp = str;
        str = cellstr;
        cellstr=temp;
    else
        disp('Check inputs. Aborting get_similar_str()');
    end
end

%%
dists = cellstrdist(cellstr, str);

[smallest, idx] = min(dists);

str = cellstr{idx};

if sum(dists==smallest) > 1
    cellstr = cellstr(dists==smallest);
    dists = cellstrdist(cellstr, str) + cellfun(@length, cellstr);
    [~, idx] = min(dists);
    str = cellstr{idx};
end
