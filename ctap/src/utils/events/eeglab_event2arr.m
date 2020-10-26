function segs = eeglab_event2arr(EEG, type)
%EEGSEG2ARR - Convert EEG event table events into matrix
%
% Description:
%   Convert EEG event table segment information into matrix.
%   Assumes that
%       1) EEG is continuous i.e. EEG.data is a normal matrix
%       2) EEG.event has the optional field .duration.
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

if (numel(size(EEG.data)) > 2)
   error('Only continuous EEG data supported.'); 
end


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


%% Construct segment array
segs(:,1) = [EEG.event(typelog).latency];
segs(:,2) = segs(:,1) + [EEG.event(typelog).duration]' - 1;


%% Check that segments do not extend over data length
%todo: refuse to compute if it does
datsz = size(EEG.data);
if (datsz(2) < segs(end,2))
    warning('eeglab_event2arr:eventsExceedData',...
        'Some events end after data end - removing them. Output has fewer segments than there are events!');
    segs = segs(segs(:,2) <= datsz(2), :); %exclude rows
end

%% Check that segments do not contain boundary events
%todo: refuse to compute if it does

