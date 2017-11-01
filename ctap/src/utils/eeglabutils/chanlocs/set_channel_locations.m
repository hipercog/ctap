function [EEG, missidx] = set_channel_locations(EEG, chanlocsfile, writemissing)
%SET_CHANNEL_LOCATIONS Set channel locations from channel locations file.
%
% Matching of channel location is performed on basis of the channel name in
% the EEG dataset, instead of relying on a specific order of channels. This
% means that we match a channel "Cz" to the information from the channel
% locations file, regardless of which the channel number is. This should be
% more reliable than EEGLab's default of using only channel number, since
% the channel number can vary from one recording to another.
%
% Usage:
%         EEG = set_channel_locations(EEG, chanlocsfile);
%
% Input
%	'EEG'           EEGLab EEG structure
%	'chanlocsfile'  Full path to file with channel location
%                         information in a format recognised by readlocs.
%                         Or the channel locations struct already produced
%                         by readlocs.
%   'writemissing'  optional, true|false, if any channels are not matched
%                   by name, match by index instead. Default = false
%
% Output   
%   'EEG'           EEGLab EEG structure with channel locations added
%
%
% See also: readlocs
%
%
% Author: Andreas Henelius 2012 (andreas.henelius@ttl.fi)
% Edit: Ben Cowley 2015 (benjamin.cowley@ttl.fi)
% 
% Copyright(c) 2015 FIOH:
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    writemissing = false;
end


%% Read the channel location information from the file
if ischar( chanlocsfile )
    eloc = readlocs( chanlocsfile );
elseif isstruct( chanlocsfile )
    eloc = chanlocsfile;
else
    return;
end
% Get the names of the channels in the channel locations struct
if any(ismember(fieldnames(eloc), 'labels'))
    chan_locs = {eloc.labels};
else
    chan_locs = struct2cell(eloc(:));
    chan_locs = chan_locs(1,:);
end

% Check if we are using some separator in the channel names, e.g. "C3-A2"
% or "C3_A2". The channel separator would have to be an exact match, so
if strfind(EEG.chanlocs(1).labels, '_')
    sep = '_';
elseif strfind(EEG.chanlocs(1).labels, '-')
    sep = '-';
else
    sep = '';
end

% We assume now that the channel locations file always separates parts in
% the channel name using a dash and not an underscore
if ~isempty(sep)
    chan_locs = strrep(chan_locs, '-', sep);
end

% Make a temporary copy of the EEG structure without the data
EEGtmp = rmfield(EEG, 'data');

missidx = [];


%% Now loop over the channel locations in the data and perform the matching
% of channel location information based on the name of the channel
for i = 1:numel(EEG.chanlocs)
    % Get the channel name
    chan_name = EEG.chanlocs(i).labels;
    
    % Look up info for this channel
    index = find(strcmpi(chan_name, chan_locs));
    
    if ~isempty(index)
        % Set the channel location information
        EEGtmp = assign_chlocs(i, eloc(index), EEGtmp);
        
    else
        % try to find partial matches for labels
        index = ~cellfun(@isempty, strfind(lower(chan_locs), lower(chan_name)))...
            | ~cellfun(@isempty, cellfun(@(x) strfind(lower(chan_name), x)...
                                , lower(chan_locs), 'UniformOutput', false));
        
        if sum(index) == 1
            EEGtmp = assign_chlocs(i, eloc(index), EEGtmp);
        elseif sum(index) > 1
            tmp_eloc = statop_on_struct(eloc(index), @mean, @isscalar);
            tmp_eloc.labels = chan_name;
            EEGtmp = assign_chlocs(i, tmp_eloc, EEGtmp);
        else
            warning off backtrace
            warning(['SET_CHANNEL_LOCATIONS:'...
                ' No channel location data found for channel ' chan_name '.']);
            warning on backtrace
            missidx = [missidx i]; %#ok<AGROW>
        end
    end
    
end


%% if requested, write any mis-matched channels from eloc to EEG
if ~isempty(missidx) && writemissing
    warning off backtrace
    warning('OVERWRITING BY MATCHING INDEXES...')
    warning on backtrace
    owidx = intersect(missidx...
        , setdiff(1:numel(eloc), setdiff(1:numel(EEG.chanlocs), missidx)));
    for i = 1:numel(owidx)
        EEGtmp = assign_chlocs(owidx(i), eloc(owidx(i)), EEGtmp, true);
    end
end


%% Finish
% Put the channel locations back into the original EEG structure
EEG.chanlocs = EEGtmp.chanlocs;

% Check the consistency of the EEG dataset
EEG = eeg_checkset(EEG);

end

