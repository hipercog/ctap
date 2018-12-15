function treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls)
%CTAP_COMPARE_BRANCH_REJS analyses CTAP branches by their rejections
% 
% Description: takes a structure formed from all_rejections.txt files produced 
% CTAP (i.e. aggregated output of CTAP_reject_data), and adds new struct rows
% which calculate the difference between tree root (peek at first step) and
% leaves (peeks at last steps)
% 
% Syntax:
%       treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls)
% 
% Input:
%   treeRej     struct, output of ctap_get_peek_stats()
%   grps        cell string array, components of recording names, e.g. groups
%   cnds        cell string array, recording name components, e.g. conditions
%   plvls       [n 1] cell array of cell string arrays, each array of strings
%               are unique parts of pipe names at a CTAP tree level: these will
%               be combined to find the rejections of individual branches
% 
% Usage:
%   treeRej = ctap_compare_branch_rejs(...
%                   ctap_get_peek_stats('path/to/ctap/base', 'output/path')...
%                   , {'intervention_1' 'control' 'intervention_2'}...
%                   , {'nback' 'flanker' 'switching'}...
%                   , {{'2A' '2B' '2C'}; {'3A' '3B'}});
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


%% SET UP PIPE NAMING
lvl = [];
lvl_nms = {};
plvlcombo = allcomb(plvls{:});
for pidx = 1:size(plvlcombo)
    pli = plvlcombo(pidx, :);
    branchidx = true(1, numel(treeRej));
    for i = 1:numel(pli)
        branchidx = branchidx & contains({treeRej.pipename}, pli{i});
    end
    lvl(end + 1) = find(branchidx);
    lvl_nms{end + 1} = ['rej_p' [pli{:}]];  %#ok<*AGROW,*SAGROW>
end


%% COMPARING
bases = setdiff(1:6, lvl);
for lix = lvl
    vars = fieldnames(treeRej(lix).pipe);
    badpc = vars{contains(vars, '_pc')};
    root = bases(round(lix ./ 3));
    vars = fieldnames(treeRej(root).pipe);
    rootpc = vars{contains(vars, '_pc')};
    for s = {treeRej(lix).pipe.subj}
%TODO: INDEXING HERE BY SUBJ-FIELD AND PROTO-FIELD IS SUITABLE FOR THE
%NEURO-ENHANCE PROJECT, BUT NOT NECESSARILY GENERAL. FIND A WAY TO INCLUDE
%grps PARAMETER IN THE INDEXING...
        for p = cnds
            sidx = ismember({treeRej(lix).pipe.subj}, s) &...
                   ismember({treeRej(lix).pipe.proto}, p);
            rsdx = ismember({treeRej(root).pipe.subj}, s) &...
                   ismember({treeRej(root).pipe.proto}, p);
            if sum(sidx) ~= 1 || sum(rsdx) ~= 1, continue; end
            root_badpc = treeRej(root).pipe(rsdx).(rootpc);
            treeRej(lix).pipe(sidx).root_badpc = root_badpc;
            treeRej(lix).pipe(sidx).total_badpc = root_badpc +...
                treeRej(lix).pipe(sidx).(badpc);
        end
    end
end


%% BUILD RANK PIPE
treeRej(end +1).pipename = 'rank_pipes';
%for each row, find lowest-scoring of four node pipes and copy
for idx = 1:numel(treeRej(lvl(1)).pipe)
    clear testvec
    for lix = lvl
        if isfield(treeRej(lix).pipe(idx), 'total_badpc')
%                     ~isempty([treeRej(lix).pipe(idx).total_badpc])
            testvec(lvl == lix) = [treeRej(lix).pipe(idx).total_badpc];
        end
    end
    if exist('testvec', 'var') == 1
        low_lvl = lvl(testvec ==  min(testvec));
        treeRej(end).pipe(idx).subj = treeRej(lvl(1)).pipe(idx).subj;
        treeRej(end).pipe(idx).badness = testvec;
        treeRej(end).pipe(idx).bestn = find(ismember(lvl, low_lvl));
    end
end