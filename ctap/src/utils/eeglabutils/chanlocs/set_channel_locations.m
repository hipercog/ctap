function [EEG, missidx] = set_channel_locations(EEG, chanlocsfile, varargin)
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
% Varargin
%   'writelabel'    optional, true|false, overwrite label. Default = false
%   'writeblank'    optional, true|false, if an eloc field is blank, should it 
%                   overwrite the corresponding field? Default = false
%   'partial_match' optional, true|false, if a channel has no exact-label match,
%                   find partial label match instead. Default = true
%   'dist_match'    optional, true|false, if channel has no exact-/partial-label
%                   match, find unique closest label instead. Default = true
%   'index_match'   optional, true|false, if any channels are not matched
%                   by label, match by index instead. Default = true
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

p = inputParser;
p.KeepUnmatched = true;
p.addRequired('EEG', @isstruct);
p.addRequired('chanlocsfile', @isstruct);
p.addParameter('writelabel', false, @islogical);
p.addParameter('writeblank', false, @islogical);
p.addParameter('partial_match', true, @islogical);
p.addParameter('dist_match', true, @islogical);
p.addParameter('index_match', true, @islogical);
p.parse(EEG, chanlocsfile, varargin{:});
Arg = p.Results;


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
    chlocs = {eloc.labels};
else
    chlocs = struct2cell(eloc(:));
    chlocs = chlocs(1,:);
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
    chlocs = strrep(chlocs, '-', sep);
end
% chlocs_orig = chlocs;

% Make a temporary copy of the EEG structure without the data
EEGtmp = rmfield(EEG, 'data');

missidx = [];


%% Now loop over the channel locations in the data and perform the matching
% of channel location information based on the name of the channel
for i = 1:numel(EEG.chanlocs)
    % Get the channel name
    chname = EEG.chanlocs(i).labels;
    
    % Try to find a matching index in chlocs for this channel name
    %%%% - BY DIRECT MATCH
    index = find(strcmpi(chname, chlocs));
    %%%% - BY PARTIAL MATCH
    if ~any(index) && Arg.partial_match
        % try to find partial matches for labels - either chan_name
        % contained in one of chlocs, or one of chlocs contained in chan_name
        x = cellfun(@(x) contains(chname, x, 'IgnoreCase', true), chlocs, 'Uni', 0);
        index = contains(chlocs, chname, 'IgnoreCase', true) | [x{:}];

        % if multiple partial matches found, take one with closest strdist
        if sum(index) > 1
            dst = cell2mat(cellfun(@(x)...
                            strdist(x, chname), chlocs(index), 'Uni', 0));
            if isscalar(find(dst == min(dst)))
                [~, flip] = min(dst);
                index(setdiff(1:numel(index), flip)) = 0;
            else
                %if we can't find a single closest match, give up
                index(index) = 0;
            end
        end
    end
    %%%% - BY SHORTEST STRING DISTANCE MATCH
    if ~any(index) && Arg.dist_match
        % try to find label that's uniquely closest by strdist
        dst = cell2mat(cellfun(@(x) strdist(x, chname), chlocs, 'Uni', 0));
        if isscalar(find(dst == min(dst)))
            [~, flip] = min(dst);
            index(flip) = 1;
        else
            %if we can't find a single closest match, give up
            index(index) = 0;
        end
    end
    
    % If an index was found, assign it. Otherwise mark as missing index
    if any(index)
        EEGtmp = assign_chlocs(i, eloc(index), EEGtmp...
                                , 'writelabel', Arg.writelabel...
                                , 'writeblank', Arg.writeblank);
        chlocs{index} = 'loc_picked';
    else
        warning off backtrace
        warning(['SET_CHANNEL_LOCATIONS:'...
            ' No channel location data found for channel ' chname '.']);
        warning on backtrace
        missidx = [missidx i]; %#ok<AGROW>
    end
end


%% if requested, write any mis-matched channels from eloc to EEG
if ~isempty(missidx) && Arg.index_match
    warning off backtrace
    warning('OVERWRITING BY MATCHING INDEXES...')
    warning on backtrace
    owidx = intersect(missidx...
        , setdiff(1:numel(eloc), setdiff(1:numel(EEG.chanlocs), missidx)));
    for i = 1:numel(owidx)
        EEGtmp = assign_chlocs(owidx(i), eloc(owidx(i)), EEGtmp...
            , 'writelabel', Arg.writelabel);
    end
end


%% Finish
% Put the channel locations back into the original EEG structure
EEG.chanlocs = EEGtmp.chanlocs;

% Check the consistency of the EEG dataset
EEG = eeg_checkset(EEG);

end

