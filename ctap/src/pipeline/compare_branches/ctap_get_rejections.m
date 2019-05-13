function [treeRej, rej_files] = ctap_get_rejections(ind, oud, varargin)
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
%   ind             string, path to root of CTAP tree, ideally the parent dir
%                       of the first named pipe
%   oud             string, path to directory where to save findings
% Varargin:
%   filt            cell string array, terms required to be in row names of 
%                       all_rejections.txt files, e.g. condition or group
%                       default = {''}, i.e. filter nothing
%   anew            logical, if true then perform search from scratch and
%                       ignore existing saved results files, 
%                       default = false
%   post_pipe_part  string, invariant part of path immediately following the
%                       pipename, used to isolate pipenames from path strings:
%                       Example: 'this/logs/all_rejections.txt'
%                       default = ''
%
% Outputs:
%   treeRej     struct, 
%   rej_files   struct, output of subdir(ind)
%
% See also:
%   ctap_read_rejections()
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


p = inputParser;
p.addRequired('ind', @ischar)
p.addRequired('oud', @ischar)
p.addParameter('filt', {''}, @iscellstr)
p.addParameter('anew', false, @islogical)
p.addParameter('post_pipe_part', '', @ischar)

p.parse(ind, oud, varargin{:});
Arg = p.Results;

if ~isfolder(oud), mkdir(oud); end

    
%% FIND REJECTION TEXT FILES
if ~Arg.anew && exist(fullfile(oud, 'rej_files.mat'), 'file') == 2
    tmp = load(fullfile(oud, 'rej_files.mat'));
    rej_files = tmp.rej_files;
else
    % WARNING: This can take a long time!!!
    rej_files = subdir(fullfile(ind, 'all_rejections.txt'));
    save(fullfile(oud, 'rej_files.mat'), 'rej_files')
end


%% READ REJECTION TEXT FILES TO TABLES
if ~Arg.anew && exist(fullfile(oud, 'rej_stats.mat'), 'file') == 2
    tmp = load(fullfile(oud, 'rej_stats.mat'));
    treeRej = tmp.treeRej;
else
    %get pipenames from sbudir structure
    treeRej = subdir_parse(rej_files, ind, Arg.post_pipe_part, 'pipename');
    %load rejection data text files to structure
    for tidx = 1:numel(treeRej)
        for stix = 1:numel(treeRej(tidx).name)
            T = ctap_read_rejections(...
                fullfile(treeRej(tidx).path, treeRej(tidx).name{stix})...
                , Arg.filt);
            treeRej(tidx).pipe = table2struct(T);
            [treeRej(tidx).pipe.casename] = T.Properties.RowNames{:};
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
end

end %ctap_get_rejections()