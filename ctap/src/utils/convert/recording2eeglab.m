function EEG = recording2eeglab(recording, varargin)
%RECORDING2EEGLAB - Convert FIOH_BWRC data (by Andreas Henelius) to EEGLAB
%
% Description:
%   A generic converter from FIOH_BWRC dataset to EEGLAB dataset.
%   FIOH_BWRC data format is a format developed by Andreas Henelius 
%   at FIOH (ask him for documentation).
%
% Syntax:
%   EEG = recording2eeglab(recording, varargin);
%
% Inputs:
%   recording   BWRC recording structure as returned by read_data_gen.m
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   keepChannels    [1,n] cell of strings, Channel labels of channels to
%                   convert into EEGLAB format. Other channels are
%                   discarded. Defaults to 'all' which translates to 
%                   'recording.signalTypes'.
%   channelLocationsFile    A file that contains the spatial locations of 
%                           the electrodes. Default: ''.  
%
% Outputs:
%   EEG     struct, EEGLAB compatible dataset
%           EEG.event is not created. Use recordingev2eeglabev.m to create
%           an event table.
%
% Assumptions:
%
% References:
%
% Example: 
%
% Notes:
%   NeurOne files have a custom converter that integrates better with
%   NeurOne data.
%
% See also: read_data_gen, recordingev2eeglabev,
% recording_neurone_to_eeglab
%
% Version History:
% 25.3.2010 Created (Jussi Korpela, TTL)
%
% Copyright 2010- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('recording', @isstruct);
    
p.addParamValue('keepChannels', {'all'}, @iscellstr);
p.addParamValue('channelLocationsFile', '', @isstr);

p.parse(recording, varargin{:});
Arg = p.Results;


%% Update Arg values
if strcmp(Arg.keepChannels{1},'all')
    %Keep all channels
    Arg.keepChannels = recording.signalTypes;
end


%% Check inputs
if numel(unique(Arg.keepChannels)) < numel(Arg.keepChannels)
    msg = 'Cannot add same channel twice.';
    error('recording2eeglab:inputError',msg); 
end

%% Collect data from 'recording'
ind = 1; %i and ind might grow differently due to missing channels
for i = 1:length(Arg.keepChannels)
    % Test channel existence
    if isfield(recording.signal, Arg.keepChannels{i})
        % Test data existence
        if isfield(recording.signal.(Arg.keepChannels{i}), 'data')
            fs(ind) = recording.signal.(Arg.keepChannels{i}).samplingRate;
            eegdata(ind,:) = recording.signal.(Arg.keepChannels{i}).data;
            channels(ind) = Arg.keepChannels(i);
            recording.signal.(Arg.keepChannels{i}) = rmfield(recording.signal.(Arg.keepChannels{i}), 'data');
            ind = ind + 1;
        else
            msg = ['Channel ',Arg.keepChannels{i},' is missing data. Excluded.'];
            warning('recording2eeglab:dataMissing', msg); 
        end
    else
        msg = ['Channel ',Arg.keepChannels{i},' is missing. Excluded.'];
        warning('recording2eeglab:signalMissing', msg); 
    end
end

% Consistency check
if length(unique(fs)) > 1
   error(); 
end


%% Create EEGLAB dataset
EEG = create_eeg(eegdata, 'channel_labels', channels,...
                    'fs', unique(fs) ,...
                    'setname', ''); 

                
EEG = eeg_checkset(EEG);


%% Add channel locations
% Adds channel locations from e.g. 'chanedit' format channel locations file
if ~isempty(Arg.channelLocationsFile)
    EEG = set_channel_locations(EEG, Arg.channelLocationsFile);
end


%% Add additional information
% These help e.g. in debugging block selection and events
EEG.ttl.recording.properties = recording.properties;
EEG.ttl.recording.device = recording.device;
EEG.ttl.recording.identifier = recording.identifier;

% .ttl.filet0 and .ttl.datat0
% These are needed to add timestamps into results
% Matlab format: 0:'dd-mmm-yyyy HH:MM:SS' e.g. '06-Nov-2009 10:30:00'
% Read from: EEG.ttl.recording.properties.start.time

EEG.ttl.filet0 = datestr(datenum(EEG.ttl.recording.properties.start.time,'yyyymmddTHHMMSS'),0);
EEG.ttl.datat0 = EEG.ttl.filet0;

