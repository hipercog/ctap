function [treeStats, peek_stat_files] = ctap_get_peek_stats(ind, oud, varargin)
%CTAP_GET_PEEK_STATS performs recurvise search of a CTAP output tree to
%find *_stats.dat files produced by CTAP_peek_data
% 
% Description: takes an input path (presumably the root of a CTAP tree),
% and an output path to save the gathered stats file locations and contents
% 
% Syntax:
%       [peek_stat_files, treeStats] = ctap_get_peek_stats(ind, oud, Arg.filt, anew)
% 
% Input:
%   ind     string, path to root of CTAP tree, ideally the parent dir of the
%                   first named pipe
%   oud     string, path to directory where to save findings
% Varargin:
%   filt    string, terms required to be in filenames, e.g. conditions or
%                   groups, which can be separated by * wildcards, 
%                   default = ''
%   anew    logical, if true then perform search from scratch and ignore
%                   existing saved results files, 
%                   default = false
% 
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

p = inputParser;
p.addRequired('ind', @ischar)
p.addRequired('oud', @ischar)
p.addParameter('filt', '', @ischar)
p.addParameter('anew', false, @islogical)

p.parse(ind, oud, varargin{:});
Arg = p.Results;

if ~isempty(Arg.filt)
    Arg.filt = ['*' Arg.filt];
end
pkfiles = ['peek_stat_files' strrep(Arg.filt, '*', '_') '.mat'];
pkstats = ['peek_stats' strrep(Arg.filt, '*', '_') '.mat'];
if ~isfolder(oud), mkdir(oud); end


%% FIND PEEK STAT FILES 
if ~Arg.anew && exist(fullfile(oud, pkfiles), 'file') == 2
    tmp = load(fullfile(oud, pkfiles));
    peek_stat_files = tmp.peek_stat_files;
else
    % WARNING: This can take a long time!!!
    peek_stat_files = subdir(fullfile(ind, [Arg.filt '*_stats.dat']));
    save(fullfile(oud, pkfiles), 'peek_stat_files')
end


%% READ IN PEEK STAT FILES 
if ~Arg.anew && exist(fullfile(oud, pkstats), 'file') == 2
    tmp = load(fullfile(oud, pkstats));
    treeStats = tmp.treeStats;
else
    % This can take a long time! because 'readtable()' takes a LONG time.
    % Create & fill structure of peek stat tables per participant/recording
    treeStats = subdir_parse(peek_stat_files, ind, 'peekpipe/this/', 'pipename');
    for tidx = 1:numel(treeStats)
        for stix = 1:numel(treeStats(tidx).name)
            treeStats(tidx).pipe(stix).stat = readtable(...
                fullfile(treeStats(tidx).path, treeStats(tidx).name{stix})...
                , 'ReadRowNames', true);
        end
    end
    save(fullfile(oud, pkstats), 'treeStats')
end

end %ctap_get_peek_stats()