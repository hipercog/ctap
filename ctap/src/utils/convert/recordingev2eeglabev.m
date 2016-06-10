function EeglabEvent = recordingev2eeglabev(recording, varargin)
%RECORDINGEV2EEGLABEV - Convert recording.markers into EEG.event
%
% Description:
%   Converts events in BWRC data structure 'recording' into EEGLAB format.
%   This process can be automated for only some devices and study setups.
%   Especially CognFuse measurements require special conversion. This
%   function implements only the most obvious cases.
%   Supports currently: 'Neuroscan', 'NeurOne'
%
%   Remember to create EEG.urevent and EEG.event.urevent when adding the
%   output of this function to EEGLAB dataset.
%
% Syntax:
%   EeglabEvent = recordingev2eeglabev(recording);
%
% Inputs:
%   recording   struct, BWRC dataset as returned by read_data_gen.m
%
% Outputs:
%   EeglabEvent struct, EEGLAB event table EEG.event
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also: read_data_gen, recording2eeglab, cfev2eeglabev, bwrc2eeglab
%
% Version History:
% 29.3.2010 Created (Jussi Korpela, TTL)
%
% Copyright 2010- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.samplingRate = NaN;
%must be provided for devices that support multiple sampling rates

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Selecting subfunction by device type
switch recording.device.type
    case 'Neuroscan'
        EeglabEvent = recording_event_cnt2eeglab(recording.markers);
    case 'NeurOne'
        EeglabEvent = recording_event_neurone2eeglab(recording.markers);
    otherwise
        msg = ['Device ',recording.device.type,' not currently supported.'];
        error('recordingev2eeglabev:deviceTypeUnknown', msg);
end

%% Subfunctions
    function EventEeglab = recording_event_cnt2eeglab(RecordingMarkers)
    
        % CNT files do not support multiple sampling rates:
        fs = recording.signal.(recording.signalTypes{1}).samplingRate;

        % Convert fields
        EventEeglab.type = strtrim(cellstr(num2str(RecordingMarkers.type)))';
        EventEeglab.latency = (RecordingMarkers.time*fs)';
        EventEeglab.duration = zeros(1, length(EventEeglab.type));

        % Plane organization to element-by-element organization
        EventEeglab = structconv(EventEeglab);
    end

    function EventEeglab = recording_event_neurone2eeglab(RecordingMarkers)
    
        % NeurOne does not support multiple sampling rates:
        fs = recording.signal.(recording.signalTypes{1}).samplingRate;

        % Convert fields
        EventEeglab.type = strtrim(cellstr(num2str(RecordingMarkers.type)))';
        EventEeglab.latency = (RecordingMarkers.index)';
        EventEeglab.duration = zeros(1, length(EventEeglab.type));

        % Plane organization to element-by-element organization
        EventEeglab = structconv(EventEeglab);
        
    end

end
