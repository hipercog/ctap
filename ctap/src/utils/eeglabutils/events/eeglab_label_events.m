function EEG = eeglab_label_events(EEG, lablerEvArr)
%EEG_LABEL_EVENTS - Mark events in EEGLAB event table based on other events
%
% Description:
%   Can be used to mark events in EEGLAB event table as coexisting with
%   some other event table events. Typically long duration events
%   describing artefacts are used to mark shorter events as belonging to a
%   signal segment with artefacts.
%
% Syntax:
%   EEG = eeg_label_events(EEG, lablerEvArr);
%
% Inputs:
%   EEG             struct, EEGLAB data struct
%   lablerEvArr     [1,m] cell of strings, Events that define which time
%                   ranges are labelled/marked.
%
% Outputs:
%   EEG         struct, EEGLAB data struct. Contains new fields in 
%               'EEG.event', one field per element in 'lablerEvArr'. Data
%               consists of integers 0 and 1. 0 corresponds to "event
%               does not coexist with labler event' and 1 corresponds to
%               "event appears within the duration of labler event". 
%               Events in 'lablerEvArr' as well as 'boundary' events are 
%               not marked.  
%
% Assumptions:
%
% References:
%
% Example: EEG = eeg_label_events(EEG, {'artefact_manual'});
%
% Notes:
%   To convert labels into a logical vector use:
%   logical({EEG.event.<your labler event>})
%
% See also: event_overlap.m
%
% Version History:
% 6.2.2012 Created (Jussi Korpela, TTL)
%
% Copyright 2012- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert event table to array for easy editing
[eventArray, eventLabels] = struct_to_cell(EEG.event);
nEvents = size(eventArray,1);
%nEvFields = numel(eventLabels);

% Find out events to label
labelledEvArr = setdiff(unique({EEG.event.type}),...
                        horzcat(lablerEvArr, {'boundary'}));


for i = 1:numel(lablerEvArr)
    
    % Search for overlaps of 'labelledEvArr' with i:th labler event 
    i_inds = [];
    for k = 1:numel(labelledEvArr)
        k_inds = eeglab_event_overlap(EEG.event, labelledEvArr{k}, lablerEvArr{i},...
                        'searchDirections', {'forward','backward'},...
                        'throwWarnings', false);
        i_inds = vertcat(i_inds, k_inds);
        clear('k_*');
    end

    % Create labeling data for i:th labler event
    i_ev = num2cell(zeros(nEvents, 1));
    i_ev(i_inds, 1) = {1};
    
    % Append labelings to event table
    eventArray = horzcat(eventArray, i_ev);
    eventLabels = horzcat(eventLabels, lablerEvArr{i});
    
    clear('i_*');
end

% Convert back (note that EEG.event has to be of size 1 x large)
EEG.event = cell2struct(eventArray, eventLabels, 2)';