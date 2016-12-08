function EEG = eeg_checkevent(EEG)
%EEG_CHECKEVENT - Check EEG event table structure (EEGLAB compatible)
% 
% Description:
%   Does the following:
%   1. Checks that EEG.event has all required fields. 
%   2. Adds field 'duration' to EEG.event if it doesn't exist
%   (3. Adds EEG.urevent and EEG.event.urevent if they are missing)
%   4. Converts EEG.event.type to string
%
%   The EEGLAB event table structure EEG.event is more comprehensively 
%   checked by eeg_checkset.m.
%
% Syntax:
%   EEG = eeg_checkevent(EEG);
%
% Inputs:
%   EEG struct, EEGLAB EEG structure
%
% Outputs:
%   EEG struct, EEGLAB EEG structure
%
% References:
%
% Example:
%
% Notes: Used by oarcalc_v2.m
% If field EEG.event.type contains at least one string value,
% pop_editeventfield converts all values to string.
%
% See also: eeg_checkset.m
%
% Version History:
% 23.11.2007 EEG.urevent now added as well (jkor, TTL) 
% 1.8.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
%% Default parameter values
% Field names of 'Arg' can be used as keywords.

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end
%}

%% Check field existence
if ~isfield(EEG.event, 'type')
    error('eeg_checkevent:fieldMissingError','Event table does not have field ''type''. Cannot fix.');
end

if ~isfield(EEG.event, 'latency')
    error('eeg_checkevent:fieldMissingError','Event table does not have field ''latency''. Cannot fix.');
end

if ~isfield(EEG.event, 'duration')
    EEG = pop_editeventfield(EEG, 'duration', NaN);
end

%{
% why do we need this?
if ~isfield(EEG.event, 'urevent')
    EEG = pop_editeventfield(EEG, 'urevent', NaN);
end
%}


%% Add EEG.urevent
% .urevent adding removed because the use of urevents is unclear and
% EEG.event.urevent seems to clear e.g.
% when calling pop_select(). Tested with a dataset with just one sample,
% maybe behavior more consistent with other datasets.
%{
add_urevent = 0;
if ~isfield(EEG, 'urevent')
    add_urevent = 1;
elseif isempty(EEG.urevent)
    add_urevent = 1;
end

if add_urevent == 1
    EEG.urevent = EEG.event;
    
    % Link EEG.urevent and EEG.event
    n_events = length(EEG.event);
    EEG.event = structconv(EEG.event);
    EEG.event.urevent = [1:1:n_events];
    EEG.event = structconv(EEG.event);
end
%}


%% Convert all event(:).type entries to string

% Store event types in a separate cell array
N_events = length(EEG.event);
events_cell = {EEG.event.type};
nummatch = cellfun(@isnumeric, events_cell);

% Remove field type and convert to plane organized structure
EEG.event = rmfield(EEG.event, 'type');
EEG.event = structconv(EEG.event);

if sum(nummatch) == N_events
    % All events have numeric .type -> convert all to string
    events_cell = cellfun(@num2str, events_cell,...
                              'UniformOutput', false);  
else
    % At least one event type is string, convert only numeric ones
    events_cell(nummatch) = cellfun(@num2str, events_cell(nummatch),...
                              'UniformOutput', false); 
end

%% Recreate field 'type'
%EEG.event fields should extend along dimension 2
%If for some reason EEG.event contains column vectors at this point, find 
%out why and correct elsewhere.
EEG.event.type = events_cell(:)'; 

EEG.event = structconv(EEG.event); %Convert back to element organization