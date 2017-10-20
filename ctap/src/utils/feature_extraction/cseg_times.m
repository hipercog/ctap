function [data, labels, units] = cseg_times(EEG, cs_eventstr, start_eventstr, varargin)
%CSEG_TIMES - Collect calculation segment start/stop times for pretty saving 
%
% Description:
%   Collects calculation segment start/stop times in a data array that can
%   be easily catenated with other arrays to form a FACTORS table.
%   Takes into account possible boundary events.
%
% Algorithm:
%   1. Searches positions of calculation segments
%   2. Adjusts the time zero to match either measurement start event or
%      EEG.CTAP.time.dataStartOffsetSamp 
%   3. Reports cseg positions in seconds from the position defined in
%      step 2
%   
%
% Syntax:
%   [data, labels, units] = cseg_times(EEG, cs_eventstr, start_eventstr, varargin);
%
% Inputs:
%   EEG             struct, EEGLAB data struct, with calculation segments 
%                   coded into EEG.event.type
%   cs_eventstr     string, Calculation segment string in EEG.event.type
%   start_eventstr  string, Calculation start string in EEG.event.type or
%                   empty. If empty, EEG.CTAP.time.dataStartOffsetSamp
%                   will be regarded as cseg time zero.
%   varargin    Keyword-value pairs
%   Keyword         Type, description, value
%   'outputType'    str, Data type of output 'data'
%                   Values: 'matrix' (default), 'cell'
%
% Outputs:
%   data        [M, 2] numeric or cell, Calculation segment start/stop
%               times in sec
%   labels      [1,2] cell of strings, Data labels
%   units       [1,2] cell of strings, Data units
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also:  eegbatch, eegbatch/create_resstruct_segment, eeg_urlatency
%
% Version History:
% 16.3.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.outputType = 'matrix'; %'matrix','cell' also possible

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Initialize variables
cseg_match = strcmp({EEG.event(:).type}, cs_eventstr);
cseg_inds = find(cseg_match);
nrow = sum(cseg_match);

if ~isempty(start_eventstr)
    calcstart_inds = strmatch(start_eventstr, {EEG.event(:).type});
    if ~isempty( calcstart_inds )
        calcstart_latency = EEG.event(calcstart_inds(1)).latency;
    end
    calcstart_urlat = eeg_urlatency(EEG.event, calcstart_latency); %in samples
else
    % using EEG.CTAP.time.dataStartOffsetSamp as cseg time zero
    calcstart_urlat = EEG.CTAP.time.dataStartOffsetSamp;
end


%% Create continuous time latency values for calculation segment events
% latency unit [samples]

cseg_start_urlat = NaN(nrow, 1);
cseg_end_urlat = NaN(nrow, 1);

for p = 1:nrow
    cseg_start_urlat(p) = ...
        eeg_urlatency(EEG.event, EEG.event(cseg_inds(p)).latency)...
        - calcstart_urlat;
    cseg_end_urlat(p) = cseg_start_urlat(p) + EEG.event(cseg_inds(p)).duration;
end

%% Create output
%cseg start in [s] from cnt file beginning
data = NaN(nrow, 2);
labels(1) = {'cs_start'};
units(1) = {'s'};
data(:,1) = cseg_start_urlat / EEG.srate; %convert to sec

%cseg end in [s] from cnt file beginning
labels(2) = {'cs_end'};
units(2) = {'s'};
data(:,2) = cseg_end_urlat / EEG.srate; %in sec


%% Format output
if strcmp(Arg.outputType, 'cell')
    data = mat2cell(data, ones(nrow,1), ones(size(data,2),1));
end

end
    



