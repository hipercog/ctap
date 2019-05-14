function [treeStats, nups] = ctap_compare_branchstats(treeStats, grps, cnds, plvls, sbjIdx, snumIx)
%CTAP_COMPARE_BRANCHSTATS analyses CTAP branches by their peek stat outputs
% 
% Description: takes a structure formed from all *_stats.dat files produced by 
% CTAP_peek_data (i.e. output of ctap_get_peek_stats), and adds new struct rows
% which calculate the difference between tree root (peek at first step) and
% leaves (peeks at last steps)
% 
% Syntax:
%       treeStats = ctap_compare_branchstats(treeStats, grps, cnds, plvls)
% 
% Input:
%   treeStats   struct, output of ctap_get_peek_stats()
%   grps        cell string array, components of recording names, e.g. groups
%   cnds        cell string array, recording name components, e.g. conditions
%   plvls       [n 1] cell array of cell string arrays, each array of strings
%               are unique parts of pipe names at a CTAP tree level: these will
%               be combined to find the stats of individual branches
%   sbjIdx      [1 n], [start:end] indices of the subject ID in casenames
%   snumIx      [1 n], [start:end] indices of the subject number in casenames
% 
% Output:
%   treeStats   struct, input with pipe-comparison & best-pipe info appended
%   nups        vector, indices of new rows appended to treeStats
% 
% Usage:
%   treeStats = ctap_compare_branchstats(...
%                   ctap_get_peek_stats('path/to/ctap/base', 'output/path')...
%                   , {'intervention_1' 'control' 'intervention_2'}...
%                   , {'nback' 'flanker' 'switching'}...
%                   , {{'2A' '2B' '2C'}; {'3A' '3B'}});
%
% Version History:
% 07.12.2018 Created (Benjamin Cowley, UoH)
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
p.addRequired('treeStats', @isstruct)
p.addRequired('grps', @(x) iscellstr(x) || ischar(x))
p.addRequired('cnds', @(x) iscellstr(x) || ischar(x))
p.addRequired('plvls', @iscell)
p.addRequired('sbjIdx', @isvector)
p.addRequired('snumIx', @isvector)

p.parse(treeStats, grps, cnds, plvls, sbjIdx, snumIx);

% parse parameters
if ischar(grps)
    grps = {grps};
end
if ischar(cnds)
    cnds = {cnds};
end


%% SET UP PIPE NAMING
lvl = [];
lvl_nms = {};
plvlcombo = allcomb(plvls{:});
for pidx = 1:size(plvlcombo)
    pli = plvlcombo(pidx, :);
    branchidx = true(1, numel(treeStats));
    for i = 1:numel(pli)
        branchidx = branchidx & contains({treeStats.pipename}, pli{i});
    end
    if any(branchidx)
        lvl(end + 1) = find(branchidx, 1);
        lvl_nms{end + 1} = ['p1_p' [pli{:}]];  %#ok<*AGROW,*SAGROW>
    end
end
if isempty(lvl)
    error('ctap_compare_branchstats:bad_param'...
        , 'Check that plvls is contained in your treeStat pipenames!')
end


%% COMPARE PEEK STATS
MATS = cell(1, numel(lvl));
% vnmi = treeStats(1).pipe(1).stat.Properties.VariableNames;
stmn = zeros(1, numel(lvl));
nups = numel(treeStats) + 1:numel(treeStats) + numel(lvl) + 1;
treeStats(nups(end)).pipename = 'best_pipes';
for ldx = 1:numel(lvl)
    treeStats(nups(ldx)).pipename = lvl_nms{ldx};
end

for s = 1:numel(treeStats(1).pipe)
    rowname = treeStats(1).name{s};
    rowname(regexp(treeStats(1).name{s}, ('_set[0-9]')):end) = [];
    grpname = grps{cellfun(@(x) contains(rowname, x, 'Ig', 1), grps)};
    cndname = cnds{cellfun(@(x) contains(rowname, x, 'Ig', 1), cnds)};
    
    for ldx = 1:numel(lvl)
        rni = contains(treeStats(lvl(ldx)).name, rowname);
        if ~any(rni)
            continue; 
        elseif sum(rni) > 2
            error('ctap_compare_branchstats:xs_stats', ...
                'Too many stats files for %s in pipe %s - clean old outputs?', ...
                rowname, treeStats(lvl(ldx)))
        end
% TODO: NAME-INDEXES ARE SPECIFIC TO NEURO-ENHANCE PROJECT, GENERALISE!!
% tmp = rowname(indices_of_subjnum); str2double(tmp(regexp(tmp, '\d')))
        treeStats(lvl(ldx)).pipe(rni).subj = rowname(sbjIdx);
        treeStats(lvl(ldx)).pipe(rni).subj_num = str2double(rowname(snumIx));
        treeStats(lvl(ldx)).pipe(rni).group = grpname;
        treeStats(lvl(ldx)).pipe(rni).proto = cndname;

        treeStats(nups(ldx)).pipe(rni).subj = rowname(sbjIdx);
        treeStats(nups(ldx)).pipe(rni).subj_num = str2double(rowname(snumIx));
        treeStats(nups(ldx)).pipe(rni).group = grpname;
        treeStats(nups(ldx)).pipe(rni).proto = cndname;

        [MATS{ldx}, nrow, nvar] = ctap_compare_stat(...
                                    treeStats(1).pipe(s).stat...
                                    , treeStats(lvl(ldx)).pipe(rni).stat);
        treeStats(nups(ldx)).pipe(rni).stat = MATS{ldx};
%TODO - NANSUMEAN(NANSUMEAN(...)) ONLY WORKS FOR 2D DATA! UPDATE TO R2018b+
%         stmn(ldx) = mean((MATS{ldx}{:,:} + 1) * 50, 'all', 'omitnan') - 50;
        stmn(ldx) = nansumean(nansumean((MATS{ldx}{:,:} + 1) * 50)) - 50;
        treeStats(nups(ldx)).pipe(rni).mean_stat = stmn(ldx);

%         if plotnsave
%             fh = ctap_stat_hists(MATS{ldx}, 'xlim', [-1 1]); %#ok<*UNRCH>
%             print(fh, '-dpng', fullfile(oud, 'STAT_HISTS'...
%                 , sprintf('%s_%s_%s_%s_stats.png', grpname...
%                 , cndname, rowname(1:5), lvl_nms{ldx})))
%         end
    end
    % make entry holding best pipe info
    if any(rni)
        treeStats(nups(end)).name{rni} = rowname;
        treeStats(nups(end)).pipe(rni).subj = rowname(sbjIdx);
        treeStats(nups(end)).pipe(rni).group = grpname;
        treeStats(nups(end)).pipe(rni).proto = cndname;
        MATS = cellfun(@(x) x{:,:}, MATS, 'Un', 0);
        MAT = reshape(cell2mat(MATS), nrow, nvar, numel(MATS));
        [treeStats(nups(end)).pipe(rni).stat, I] = max(MAT, [], 3);
        [~, sortn] = sort(hist(I(:), numel(unique(I))), 'descend');
%TODO - NANSUMEAN(NANSUMEAN(...)) ONLY WORKS FOR 2D DATA! UPDATE TO R2018b+
%         bestn = mode(I, [1 2]);
        bestn = mode(mode(I));
        treeStats(nups(end)).pipe(rni).best = lvl_nms{bestn};
        treeStats(nups(end)).pipe(rni).bestn = bestn;
        treeStats(nups(end)).pipe(rni).best2wrst = sortn;
        treeStats(nups(end)).pipe(rni).mean_stats = stmn;
    end
end

end %ctap_compare_branchstats()