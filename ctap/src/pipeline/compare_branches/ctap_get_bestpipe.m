function [bestpipe, bestpipeTab] =...
                ctap_get_bestpipe(treeStats, treeRej, oud, plvls, varargin)
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
%       [bestpipe, bestpipeTab] = ctap_get_bestpipe(treeStats, treeRej, oud, plvls, ...)
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
%   bestpipe    struct,
%   bestpipeTab table, 
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
    bestpipe = struct;
    %Set up pipe names
    plvlcombo = allcomb(plvls{:});
    pn = size(plvlcombo);
    lvl_nms = cell(1, pn(1));
    for pidx = 1:pn(1)
        lvl_nms{pidx} = ['p1_p' [plvlcombo{pidx, :}]];
    end
    %Find where rejections matches stats
    [r_in_s, fRinSd] = sbf_match_rs(treeRej(end).pipe, treeStats(end).pipe);
    [s_in_r, fSinRd] = sbf_match_rs(treeStats(end).pipe, treeRej(end).pipe);
    
    %Step through all subjects one at a time
    for idx = 1:numel(fRinSd)
%         if treeRej(end).pipe(idx).subj ~= treeStats(end).pipe(idx).subj
%             error('ctap_get_bestpipe:rej_stats_differ'...
%                 , 'Something has gone terribly wrong!')
%         else
        bestpipe(idx).subj = treeStats(end).pipe(fSinRd(idx)).subj;
        bestpipe(idx).group = treeStats(end).pipe(fSinRd(idx)).group;
        bestpipe(idx).proto = treeStats(end).pipe(fSinRd(idx)).proto;
%         end
        rej = treeRej(end).pipe(idx).best;
        sta = treeStats(end).pipe(fSinRd(idx)).best;
        bestpipe(idx).rejbest = rej;
        bestpipe(idx).statbst = sta;
        rejn = treeRej(end).pipe(idx).bestn;
        stan = treeStats(end).pipe(fSinRd(idx)).bestn;
        bestpipe(idx).rejbestn = rejn;
        bestpipe(idx).statbstn = stan;
        
        [rejrank, rjix] = sort(treeRej(end).pipe(idx).badness);
        [srank, stix] = sort(treeStats(end).pipe(fSinRd(idx)).mean_stats...
                                                                , 'descend');
        for p = 1:numel(lvl_nms)
            tmp = find(rjix == p) + find(stix == p);
            if ~isempty(tmp)
                piperank(p) = tmp;
            end
        end
        bestix = find(piperank == min(piperank));
        if numel(bestix) > 1 && all(ismember(bestix, 1:numel(rejrank)))
            [~, bestix] = min(rejrank(bestix));
        end
        bestpipe(idx).bestpipeix = bestix;

        if any(ismember(rejn, stan))
            bestpipe(idx).bestn = rejn(ismember(rejn, stan));
            bestpipe(idx).best = rej;
        else
            bestpipe(idx).best = sta;
            bestpipe(idx).bestn = stan;
        end
% TODO - THIS IS RESTRICTED TO FIRST TWO LEVELS OF BADNESS: EXTEND!?
%         bestpipe(idx).badness1 = treeRej(end).pipe(idx).badness(bestix);
%         bestpipe(idx).badness2 =...
%                        treeRej(end).pipe(idx).badness(bestpipe(idx).bestn);
%         bestpipe(idx).stat1 = treeStats(end).pipe(idx).mean_stats(bestix);
%         bestpipe(idx).stat2 =...
%                   treeStats(end).pipe(idx).mean_stats(bestpipe(idx).bestn);
    end
    clear idx
    if any(~r_in_s)
        fRinRd = find(~r_in_s);
        for idx = 1:numel(fRinRd)
            bestpipe(idx).subj = treeRej(end).pipe(idx).subj;
            bestpipe(idx).group = treeRej(end).pipe(idx).group;
            bestpipe(idx).proto = treeRej(end).pipe(idx).proto;
            
            bestpipe(idx).rejbest = treeRej(end).pipe(idx).best;
            bestpipe(idx).rejbestn = treeRej(end).pipe(idx).bestn;
            
            bestpipe(idx).statbst = 'Stats not found';
            bestpipe(idx).statbstn = NaN;

            [rejrank, rjix] = sort(treeRej(end).pipe(idx).badness);
            [~, bestpipe(idx).bestpipeix] = min(rejrank);

            bestpipe(idx).bestn = bestpipe(idx).rejbestn;
            bestpipe(idx).best = bestpipe(idx).rejbest;

        end
    end
    if any(~s_in_r)
        fSinSd = find(~s_in_r);
        for idx = 1:numel(fSinSd)
            bestpipe(idx).subj = treeStats(end).pipe(idx).subj;
            bestpipe(idx).group = treeStats(end).pipe(idx).group;
            bestpipe(idx).proto = treeStats(end).pipe(idx).proto;

            bestpipe(idx).rejbest = 'Rej not found';
            bestpipe(idx).rejbestn = NaN;
            
            bestpipe(idx).statbst = treeStats(end).pipe(idx).best;
            bestpipe(idx).statbstn = treeStats(end).pipe(idx).bestn;

            [srank, stix] = sort(treeStats(end).pipe(idx).mean_stats, 'descend');
            [~, bestpipe(idx).bestpipeix] = min(srank);

            bestpipe(idx).best = bestpipe(idx).statbst;
            bestpipe(idx).bestn = bestpipe(idx).statbstn;
        end
    end
    bestpipeTab = struct2table(bestpipe);
    save(fullfile(oud, 'best_pipe.mat'), 'bestpipe', 'bestpipeTab')
end

end

function [ixB, findB] = sbf_match_rs(strA, strB)

    ixB = zeros(numel(strB), 1);
    findB = NaN(numel(strB), 1);
    
    for i = 1:numel(strA)
        idx = ( ismember({strB.subj}', strA(i).subj)...
              & ismember({strB.group}', strA(i).group)...
              & ismember({strB.proto}', strA(i).proto) );
        if any(idx)
            if sum(idx) == 1
                findB(i) = find(idx);
            else
                tmp = find(idx);
                findB(i) = tmp(1);
                warning('sbf_match_rs:multi', 'Multiple matches for %s-%s-%s'...
                    , strA(i).subj, strA(i).group, strA(i).proto)
            end
        end
        ixB = ixB | idx;
    end
    findB(isnan(findB)) = [];
end