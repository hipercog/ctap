function [time, sample] = event_to_time(starttype, startmark, zerotime, recording)
% EVENT_TO_TIME - Get the start time and start sample of an event.
%
% Description:
%
% Syntax:
%   [time, sample] = event_to_time(starttype, startmark, zerotime, recording)
% 
% Inputs:
%         starttype  : see documentation for the function parse_blocks (starttype)
%         starttmark : see documentation for the function parse_blocks (starttime)
%         zerotime   : number of seconds from the start of the recording
%                      used to shift the events.
%         recording  : a recording structure (or just the header of the recording,
%                      including markers, sampling rates etc).
%
% Outputs:
%   time   : the time when the marker appears
%   sample : the sample when the marker appears
%
%
% See also: parse_blocks, marker_to_time
% 
% Author: Andreas Henelius (FIOH, 2014)
% -------------------------------------------------------------------------

sample = [];
if strcmpi(starttype, 'time')
   
    if (isstr(startmark))
        startmark = str2num(startmark);
    end
    
    time = startmark + zerotime;
    
elseif strcmpi(starttype, 'timestamp')
    % calculate time difference from recStart to timeStamp
    recStart = recording.properties.start.unixTime;
    time     = datenum2unixtime(datenum(startmarkraw, 'yyyymmddTHHMMSS')) - recStart;
    
elseif strcmpi(starttype, 'marker')
    if ~isfield(recording, 'markers')
        error('No markers present in recording');
    end
    
    try
        [time, sample] = marker_to_time(startmark, recording.markers);
    catch
        sample = 1;
        time = sample / recording.properties.samplingRate;
        warning('event_to_time:markerNotFound',...
            'Start marker ''%s'' was not found. Using first sample.', startmark);
    end
end

if isempty(sample)
    if isfield(recording.properties, 'samplingRate')
        sample = time * recording.properties.samplingRate;
    else
        warning('event_to_time:samplingRateNotSpecified',...
        'Field recording.properties.samplingRate not found. Returning empty for ''sample''.')
    end  
end
% -------------------------------------------------------------------------
