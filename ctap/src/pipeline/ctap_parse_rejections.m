function treeRej = ctap_parse_rejections(treeRej, grps, cnds)
%CTAP_PARSE_REJECTIONS massages CTAP rejection data
% 
% Description: takes a structure formed from all_rejections.txt files produced 
% CTAP (i.e. aggregated output of CTAP_reject_data), and adds new struct
% fields which tidy up the rejection data
% 
% Syntax:
%       treeRej = ctap_parse_rejections(treeRej, grps, cnds)
% 
% Input:
%   treeRej     struct, output of ctap_get_rejections()
%   grps        cell string array, components of recording names, e.g. groups
%   cnds        cell string array, recording name components, e.g. conditions
% 
% Usage:
%   treeRej = ctap_parse_rejections(...
%                   ctap_get_rejections('path/to/ctap/base', 'output/path')...
%                   , {'intervention_1' 'control' 'intervention_2'}...
%                   , {'nback' 'flanker' 'switching'});
%
% Version History:
% 08.12.2018 Created (Benjamin Cowley, UoH)
%
% Copyright(c) 2018:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PARSE REJECTION TABLE DATA
%go through each pipe, group, protocol and subject to parse the data
for p = 1:size(treeRej)
    vars = fieldnames(treeRej(p).pipe);
    bad = vars{contains(vars, 'bad')};
    pc = vars{contains(vars, 'pc')};
    % massage the rows to clean and prep the data
    for r = 1:size(treeRej(p).pipe)
        rowname = treeRej(p).pipe(r).Row;
        treeRej(p).pipe(r).subj = rowname(1:5);
        treeRej(p).pipe(r).group =...
            grps{cellfun(@(x) contains(rowname, x, 'Ig', 0), grps)};
        treeRej(p).pipe(r).proto =...
            cnds{cellfun(@(x) contains(rowname, x, 'Ig', 0), cnds)};
        treeRej(p).pipe(r).(pc) = str2double(treeRej(p).pipe(r).(pc));
        bdnss = strsplit(treeRej(p).pipe(r).(bad));
        if any(isnan(cellfun(@str2double, bdnss)))
            treeRej(p).pipe(r).(bad) = bdnss;
        else
            treeRej(p).pipe(r).(bad) = cellfun(@str2double, bdnss);
        end
        treeRej(p).pipe(r).badcount = numel(treeRej(p).pipe(r).(bad));
    end
end