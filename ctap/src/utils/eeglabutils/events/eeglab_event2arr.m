function segs = eeglab_event2arr(EEG, type)
%EEGSEG2ARR - Convert EEG event table events into matrix
%
% Description:
%   Convert EEG event table segment information into matrix. Assumes that
%   EEG.event has the optional field .duration.
%
% Syntax:
%   segs = eeglab_event2arr(EEG, type);
%
% Inputs:
%   EEG     sturct, EEGLAB EEG struct
%   type    string, ".type" of the segments to convert 
%
% Outputs:
%   segs    [m,2] numeric, Segment start and stop in [samples].
%
% References:
%
% Example:
%
% Notes: 
%
% See also: 
%
% Version History:
% 12.10.2007 Created as eegseg2arr.m (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Convert entries of .type into cell array of strings
typearr = {EEG.event(:).type};
typearr = cellfun(@num2str, typearr, 'UniformOutput', false);


%% Find locations that match 'type'
typelog = strcmp(typearr, type);

if sum(typelog)==0
    segs = [];
    msg=['No events of type ''',type,''' found. Returning empty array.']; 
    error('eegseg2arr:eventsMissing', msg);
    return
end


%% Construct segment array & ensure segs do not exceed data size
segs(:,1) = [EEG.event(typelog).latency];
segs(:,2) = segs(:,1) + [EEG.event(typelog).duration]' - 1;
datsz = size(EEG.data);
datsz = prod(datsz(2:end));
segs(segs(:,2)>datsz) = [];
