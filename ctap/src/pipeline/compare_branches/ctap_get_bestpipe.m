function bestpipe = ctap_get_bestpipe(treeStats, treeRej, oud, plvls, varargin)
%CTAP_GET_BESTPIPE combines stats and rejections information to judge the
%                   best performing pipe from a set of competing branches
% 
% Description: takes output (structs of stats & rejections per subject) of 
%                               ctap_compare_branchstats() and
%                               ctap_compare_branch_rejs()
%              Combines their information to judge best pipe, based on:
%               a) maximise reduction of signal noise in stats data, and
%               b) minimise removal of data by artefact-rejection routines
% 
% Syntax:
%       bestpipe = ctap_get_bestpipe(treeStats, treeRej, oud, plvls, ...)
% 
% Input:
%   treeStats   struct, output of ctap_compare_branchstats()
%   treeRej     struct, output of ctap_compare_branch_rejs()
%   oud             string, path to directory where to save findings
%   plvls       [n 1] cell array of cell string arrays, each array of strings
%               are unique parts of pipe names at a CTAP tree level: these will
%               be combined to find the best among individual branches
% 
% Varargin:
%   anew            logical, if true then perform search from scratch and
%                       ignore existing saved results files, 
%                       default = false
% TODO - ADD VARARG plot logical, plot histograms of competing pipes ... 
%                       default = false
%
% Outputs:
%   treeRej     struct, 
%   rej_files   struct, output of subdir(ind)
%
% See also:
%   ctap_compare_branch_rejs(), ctap_compare_branchstats()
% 
% Version History:
% 13.05.2019 Created (Benjamin Cowley, UoH)
%
% Copyright(c) 2019:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% INIT
p = inputParser;
p.addRequired('treeStats', @isstruct)
p.addRequired('treeRej', @isstruct)
p.addRequired('oud', @ischar)
p.addRequired('plvls', @iscell)

p.addParameter('anew', false, @islogical)

p.parse(treeStats, treeRej, oud, plvls, varargin{:});
Arg = p.Results;


%% JUDGEMENT : THE COMBININING
if ~Arg.anew && exist(fullfile(oud, 'best_pipe.mat'), 'file') == 2
    tmp = load(fullfile(oud, 'best_pipe.mat'));
    bestpipe = tmp.bestpipe;
else
    %% BUILD IT
    % SET UP PIPE NAMES
    plvlcombo = allcomb(plvls{:});
    pn = size(plvlcombo);
    lvl_nms = cell(1, pn(1));
    for pidx = 1:pn(1)
        lvl_nms{pidx} = ['p1_p' [plvlcombo{pidx, :}]];
    end

    bestpipe = struct;
%     thr = 20;
    for idx = 1:numel(treeRej(end).pipe)
        if treeRej(end).pipe(idx).subj ~= treeStats(end).pipe(idx).subj
            error('ctap_get_bestpipe:rej_stats_differ'...
                , 'Something has gone terribly wrong!')
        else
            bestpipe(idx).subj = treeStats(end).pipe(idx).subj;
            bestpipe(idx).group = treeStats(end).pipe(idx).group;
            bestpipe(idx).proto = treeStats(end).pipe(idx).proto;
        end
        rejn = treeRej(end).pipe(idx).bestn;
        stan = treeStats(end).pipe(idx).bestn;
        bestpipe(idx).rejbest = rejn;
        bestpipe(idx).statbst = stan;
        
        [rejrank, rjix] = sort(treeRej(end).pipe(idx).badness);
        [srank, stix] = sort(treeStats(end).pipe(idx).mean_stats, 'descend');
        for p = 1:numel(plvls)
            tmp = find(rjix == p) + find(stix == p);
            if ~isempty(tmp)
                piperank(p) = tmp;
            end
        end
        bestix = find(piperank == min(piperank));
        if numel(bestix) > 1
            [~, bestix] = min(rejrank(bestix));
        end
        bestpipe(idx).bestpipe = bestix;

        if any(ismember(rejn, stan))
            bestpipe(idx).bestn = rejn(ismember(rejn, stan));
        else
            bestpipe(idx).bestn = stan;
        end
% TODO - THIS IS RESTRICTED TO FIRST TWO LEVELS OF BADNESS: EXTEND!?
        bestpipe(idx).badness1 = treeRej(end).pipe(idx).badness(bestix);
        bestpipe(idx).badness2 =...
                       treeRej(end).pipe(idx).badness(bestpipe(idx).bestn);
        bestpipe(idx).stat1 = treeStats(end).pipe(idx).mean_stats(bestix);
        bestpipe(idx).stat2 =...
                  treeStats(end).pipe(idx).mean_stats(bestpipe(idx).bestn);
    end
    save(fullfile(oud, 'best_pipe.mat'), 'bestpipe')
end