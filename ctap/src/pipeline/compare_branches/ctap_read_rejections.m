function rejtab = ctap_read_rejections(fIn, varargin)
% CTAP_READ_REJECTIONS read the contents of 'all_rejections.txt' bad data logs
% 
% Description: 
%   'all_rejections.txt' log files (built up at the end of each pipe from all
%   'badX_rejections.mat' files in quality_control dir) are formatted as Matlab
%   tables, and can have data (list of bad chans/epochs/ICs) with whitespace. 
%   Matlab's readtable() does not deal well with autoformatting when data has 
%   whitespace. This function fixes this - it also will aggregate consecutive
%   columns of badness data, separated by bad-percentage columns, into single
%   column.
% 
% Syntax:
%   rejtab = ctap_read_rejections(iIn)
% 
% Inputs:
%   fIn     string, path to the all_rejections.txt file to parse
% 
% Varargin:
%   filt    cell string array, terms required to be in row names of input
%                              all_rejections.txt file, e.g. condition or group
%           default = {''}
% 
% Outputs:
%   rejtab  table, badness read from file
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
p.addRequired('fIn', @ischar)

p.addParameter('filt', {''}, @iscellstr)

p.parse(fIn, varargin{:});
Arg = p.Results;


%% READ data
hdr = textscan(fopen(fIn), '%s', 1);

cols = strsplit(hdr{:}{:}, ',');

data = textscan(fopen(fIn), repmat('%s', 1, numel(cols))...
                    , 'Delimiter', ',', 'Headerlines', 1);

%% Check/prep data
if strcmp(cols{1}, 'Row')
    cols(1) = [];
else
    error('ctap_read_rejections:failure', 'Sthg has gone terribly wrong!')
end
bdix = contains(cols, '_bad');
least = find(bdix, 1);
pcix = contains(cols, '_pc');

rnms = data{1};
data(1) = [];
data = horzcat(data{:});
if ~all(cellfun(@isempty, Arg.filt))
    flti = ~contains(rnms, Arg.filt);
    rnms(flti) = [];
    data(flti, :) = [];
end

vars = cell(1, sum(pcix) * 2);
nudat = cell(numel(rnms), sum(pcix) * 2);
nui = 1;


%% Parse/reformat data
for ix = find(pcix)
    if ~all(bdix(least:ix - 1))
        error('ctap_read_rejections:failure', 'Sthg has gone terribly wrong!')
    end
    bads = cols(least:ix - 1);
    prts = cellfun(@(x) strsplit(x, '_'), bads, 'Un', 0);
    stfn = unique(cellfun(@(x) x{1}, prts, 'Un', 0));
    tmp = unique(cellfun(@(x) x{2}, prts, 'Un', 0));
    if numel(tmp) > 1
        error('ctap_read_rejections:failure', 'Sthg has gone terribly wrong!')
    end
    if numel(bads) > 1
        vars{nui} = sprintf('%s_%s_%d_%d', stfn{:}, tmp{:}, 1, numel(bads));
    else
        vars{nui} = sprintf('%s_%s_%d', stfn{:}, tmp{:}, 1);
    end
    tmp = data(:, least:ix - 1);
    vars{nui + 1} = cols{ix};
    for i = 1:numel(rnms)
        nudat{i, nui} = strjoin(tmp(i, :));
        nudat{i, nui + 1} = data{i, ix};
    end
    
    least = ix + 1;
    nui = nui + 2;
end


%% Output data
rejtab = cell2table(nudat...
    , 'RowNames', rnms...
    , 'VariableNames', vars);

end %ctap_read_rejections()