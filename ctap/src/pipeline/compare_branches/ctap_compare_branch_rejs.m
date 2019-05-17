function treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls)
%CTAP_COMPARE_BRANCH_REJS analyses CTAP branches by their rejections
% 
% Description: takes a structure formed from all_rejections.txt files produced 
% by CTAP (i.e. aggregated output of CTAP_reject_data), and adds new struct
% rows which calculate the difference between tree root (peek at first step)
% and leaves (peeks at last steps)
% 
% Syntax:
%       treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls)
% 
% Input:
%   treeRej     struct, output of ctap_get_rejections()
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


%% INIT
p = inputParser;
p.addRequired('treeRej', @isstruct)
p.addRequired('grps', @(x) iscellstr(x) || ischar(x))
p.addRequired('cnds', @(x) iscellstr(x) || ischar(x))
p.addRequired('plvls', @iscell)

p.parse(treeRej, grps, cnds, plvls);


%% SET UP PIPE NAMING
lvl = [];
lvl_nms = {};
plvlcombo = allcomb(plvls{:});
bases = [];
for pidx = 1:size(plvlcombo)
    pli = plvlcombo(pidx, :);
    branchidx = true(1, numel(treeRej));
    for i = 1:numel(pli)
        branchidx = branchidx & contains({treeRej.pipename}, pli{i});
    end
    if any(branchidx)
        lvl(end + 1) = find(branchidx, 1);
        lvl_nms{end + 1} = ['rej_p' [pli{:}]];  %#ok<*AGROW,*SAGROW>
        bases(end + 1) = find(contains({treeRej.pipename}...
                , fileparts(treeRej(lvl(end)).pipename(1:end - 1))), 1);
    end
end


%% COMPARING
for ix = 1:numel(lvl)
    lix = lvl(ix);
    root = bases(ix);
    vars = fieldnames(treeRej(lix).pipe);
    badpc = vars{contains(vars, '_pc')};
    vars = fieldnames(treeRej(root).pipe);
    rootpc = vars{contains(vars, '_pc')};
    for s = {treeRej(lix).pipe.subj}
%TODO: INDEXING HERE BY SUBJ-FIELD AND PROTO-FIELD IS SUITABLE FOR THE
%NEURO-ENHANCE PROJECT, BUT NOT NECESSARILY GENERAL. 
%FIND A WAY TO INCLUDE grps PARAMETER IN THE INDEXING...
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
treeRej(end + 1).pipename = 'rank_pipes';
%for each row, find lowest-scoring of given node pipes, and copy
for idx = 1:numel(treeRej(lvl(1)).pipe)
    rowname = treeRej(lvl(1)).pipe(idx).casename;
    clear testvec
    for ldx = lvl
        rni = contains({treeRej(ldx).pipe.casename}, rowname);
        if ~any(rni)
            warning('Subject %s not found in level %d: skipping', rowname, ldx)
            continue; 
        elseif sum(rni) > 2
            error('ctap_compare_branch_rejs:xs_rows', ...
                'Too many matching rows for %s in pipe %s - clean old outputs?', ...
                rowname, treeRej(ldx).pipename)
        end
        if isfield(treeRej(ldx).pipe(rni), 'total_badpc') &&...
                   ~isempty([treeRej(ldx).pipe(rni).total_badpc])
            testvec(lvl == ldx) = [treeRej(ldx).pipe(rni).total_badpc];
        end
    end
    if exist('testvec', 'var') == 1
        low_lvl = lvl(testvec ==  min(testvec));
        bestn = find(ismember(lvl, low_lvl));
        treeRej(end).pipe(idx).subj = treeRej(lvl(1)).pipe(idx).subj;
        treeRej(end).pipe(idx).group = treeRej(lvl(1)).pipe(idx).group;
        treeRej(end).pipe(idx).proto = treeRej(lvl(1)).pipe(idx).proto;
        treeRej(end).pipe(idx).badness = testvec;
        treeRej(end).pipe(idx).bestn = bestn;
        treeRej(end).pipe(idx).best = lvl_nms{bestn};
    end
end