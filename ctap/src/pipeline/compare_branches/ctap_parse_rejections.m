function treeRej = ctap_parse_rejections(treeRej, grps, cnds, sbjIdx)
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
%   sbjIdx      [1 n], [start:end] indices of the subject ID in casenames
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


%% INIT
p = inputParser;
p.addRequired('treeRej', @isstruct)
p.addRequired('grps', @iscellstr)
p.addRequired('cnds', @iscellstr)
p.addRequired('sbjIdx', @isvector)

p.parse(treeRej, grps, cnds, sbjIdx);

if ~isfield(treeRej, 'pipe')
    error('ctap_parse_rejections:bad_param', 'GTFO')
end


%% PARSE REJECTION TABLE DATA
%go through each pipe, group, protocol and subject to parse the data
for p = 1:size(treeRej)
    if ~isstruct(treeRej(p).pipe)
        continue
    end
    vars = fieldnames(treeRej(p).pipe);
    bad = vars{contains(vars, 'bad')};
    pc = vars{contains(vars, 'pc')};
    % massage the rows to clean and prep the data
    for r = 1:size(treeRej(p).pipe)
        %info-gathering
        rowname = treeRej(p).pipe(r).casename;
        gidx = cellfun(@(x) contains(rowname, x, 'Ig', 1), grps);
        cidx = cellfun(@(x) contains(rowname, x, 'Ig', 1), cnds);
        bdnss = treeRej(p).pipe(r).(bad);
        if ischar(bdnss)
            bdnss = strsplit(bdnss);
            if ~any(isnan(cellfun(@str2double, bdnss)))
                bdnss = cellfun(@str2double, bdnss);
            end
        end
        %info-writing
        treeRej(p).pipe(r).subj = rowname(sbjIdx);
        treeRej(p).pipe(r).group = grps{gidx};
        treeRej(p).pipe(r).proto = cnds{cidx};
        treeRej(p).pipe(r).(pc) = str2double(treeRej(p).pipe(r).(pc));
        treeRej(p).pipe(r).(bad) = bdnss;
        treeRej(p).pipe(r).badcount = numel(treeRej(p).pipe(r).(bad));
    end
end
% %% PARSE REJECTION TABLE DATA
% %go through each pipe, group, protocol and subject to parse the data
% for r = 1:numel(sort_rejtxt)
%     vars = fieldnames(treeRej(r).pipe);
%     bad = vars{contains(vars, 'bad')};
%     for g = 1:numel(grps)
%         tmp = table2array(sbjXgrp(:, grps{g}));
%         tmp(isnan(tmp)) = [];
%         for c = 1:numel(cnds)
%             for s = 1:numel(tmp)
%                 sid = startsWith({treeRej(r).pipe.Row}, num2str(tmp(s))) &...
%                     contains({treeRej(r).pipe.Row}, cnds{c}, 'Ig', true);
%                 if ~any(sid), continue; end
%                 treeRej(r).pipe(sid).subj = tmp(s);
%                 treeRej(r).pipe(sid).group = grps{g};
%                 treeRej(r).pipe(sid).proto = cnds{c};
%                 treeRej(r).pipe(sid).badness =...
%                     str2double(strsplit(strrep(strrep(...
%                     treeRej(r).pipe(sid).(bad), 'E', ''), 'none', '0')));
%                 treeRej(r).pipe(sid).badcount =...
%                     numel(treeRej(r).pipe(sid).([bad '_nums']));
%             end
%         end
%     end
% end