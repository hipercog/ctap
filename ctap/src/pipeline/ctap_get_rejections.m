function [treeRej, rej_files] = ctap_get_rejections(ind, oud)
%CTAP_GET_REJECTIONS performs recurvise search of a CTAP output tree to
%find all_rejections.txt files produced by CTAP
% 
% Description: takes an input path (presumably the root of a CTAP tree),
% and an output path to save the found rejection file locations and contents
% 
% Syntax:
%       [treeRej, rej_files] = ctap_get_rejections(ind, oud)
% 
% Input:
%   ind     string, path to root of CTAP tree
%   oud     string, path to directory where to save findings
% 
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


%% FIND REJECTION TEXT FILES
if exist(fullfile(oud, 'rej_files.mat'), 'file') == 2
    tmp = load(fullfile(oud, 'rej_files.mat'));
    rej_files = tmp.rej_files;
else
    % WARNING: This can take a long time!!!
    rej_files = subdir(fullfile(ind, 'all_rejections.txt'));
    save(fullfile(oud, 'rej_files.mat'), 'rej_files')
end


%% READ REJECTION TEXT FILES TO TABLES
if exist(fullfile(oud, 'rej_stats.mat'), 'file') == 2
    tmp = load(fullfile(oud, 'rej_stats.mat'));
    treeRej = tmp.treeRej;
else
    %get pipenames from sbudir structure
    treeRej = subdir_parse(rej_files, ind, 'this/logs/all_rejections.txt', 'pipename');
    %load rejection data text files to structure
    %TODO : currently defines format as three columns, i.e. 1 type of rejection 
    %       per pipe. Generalise this somehow when readtable() does not
    %       deal well with autoformatting when data has whitespace
    for tidx = 1:numel(treeRej)
        for stix = 1:numel(treeRej(tidx).name)
            treeRej(tidx).pipe = table2struct(readtable(...
                fullfile(treeRej(tidx).path, treeRej(tidx).name{stix})...
                , 'Delimiter', ',', 'Format', '%s%s%s'));
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
end