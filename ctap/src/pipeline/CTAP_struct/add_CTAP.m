function EEG = add_CTAP(EEG, Cfg, varargin)
%ADD_CTAP - Adds CTAP struct to an EEG struct
%
% Description:
%   Use this function to create the CTAP struct when importing your data.
%   Also sets some metadata fields of the EEG struct.
%   Modify this function to add/remove/rename fields in EEG.CTAP.
%   Using one central place for creating the CTAP simplifies maintenance.
%
% Syntax:
%   EEG = add_CTAP(EEG, Cfg, reference, varargin);
%
% Inputs:
%   EEG         struct, EEGLAB EEG struct
%   Cfg         struct, CTAP configuration struct
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   'meta'      struct, data about the EEG recording, e.g. device, id
%   'time'      struct, three fields, all copied to CTAP.time:
%               fileStart, file start data string
%               dataStart, data start data string
%               dataStartOffsetSamp, data start offset in samples
%               These are needed to add timestamps into results. Use Matlab 
%               format: 30 = ISO 8601: 'yyyymmddTHHMMSS' e.g. 20240101T123045
%               Default = now
%
% Outputs:
%   EEG         struct, EEGLAB EEG struct with field 'CTAP'
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also:  is_valid_CTAP
%
% Version History:
% 1.06.2014 Created (Jussi Korpela, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('Cfg', @isstruct);

p.addParameter('time', struct, @isstruct);
p.addParameter('meta', struct, @isstruct);

p.parse(EEG, Cfg, varargin{:});
Arg = p.Results;


%% Add EEG metadata
EEG.setname = Cfg.measurement.casename;
EEG.subject = Cfg.measurement.subject;
EEG.session = Cfg.measurement.session;
EEG.condition = Cfg.measurement.measurement;
EEG.group = '';


%% Add CTAP required fields
EEG.CTAP.subject = Cfg.subject;
EEG.CTAP.measurement = Cfg.measurement;

EEG.CTAP.files.eegFile = Cfg.measurement.physiodata;
EEG.CTAP.files.channelLocationsFile = ctap_eeg_find_chlocs(Cfg);
EEG.CTAP.reference = Cfg.eeg.reference;


% Convert MC datetime to datetime
if isfield(EEG.CTAP.measurement, 'datetime') 
    if isstring(EEG.CTAP.measurement.datetime)
        MC_datetime = datetime(EEG.CTAP.measurement.datetime, 'I', 'yyyyMMddHHmmss');
    elseif isnumeric(EEG.CTAP.measurement.datetime)
        if isscalar(EEG.CTAP.measurement.datetime)
            MC_datetime = datetime(EEG.CTAP.measurement.datetime, 'C', 'yyyyMMddHHmmss');
        else
            MC_datetime = datetime(EEG.CTAP.measurement.datetime);
        end
    end
end
% Convert MC date to datetime
if isfield(EEG.CTAP.measurement, 'date') 
    if isstring(EEG.CTAP.measurement.date)
        MC_date = datetime(EEG.CTAP.measurement.date);
    elseif isnumeric(EEG.CTAP.measurement.date)
        if isscalar(EEG.CTAP.measurement.date)
            MC_date = datetime(EEG.CTAP.measurement.date, 'ConvertFrom', 'yyyyMMdd');
        else
            MC_date = datetime(EEG.CTAP.measurement.date);
        end
    end
end
% Convert MC time to duration
if isfield(EEG.CTAP.measurement, 'time')
    if isstring(EEG.CTAP.measurement.time)
        MC_time = datetime(EEG.CTAP.measurement.time, 'I', 'HHmmss');
    elseif isnumeric(EEG.CTAP.measurement.time)
        if isscalar(EEG.CTAP.measurement.time)
            MC_time = datetime(num2str(EEG.CTAP.measurement.time), 'I', 'HHmmss');
        else
            MC_time = datetime(EEG.CTAP.measurement.time);
        end
    end
    MC_time = duration(MC_time.Hour, MC_time.Minute, MC_time.Second);
end
if exist("MC_date", "var") && exist("MC_time", "var") && ~exist("MC_datetime", "var")
    MC_datetime = MC_date + MC_time;
end

% populate CTAP time field depending on info available: prioritise parameters,
% then measurement config, then now
if isfield(Arg.time, 'fileStart')
    EEG.CTAP.time.fileStart = Arg.time.fileStart;
elseif exist("MC_datetime", "var")
    EEG.CTAP.time.fileStart = MC_datetime;
else
    EEG.CTAP.time.fileStart = datetime;
end

if isfield(Arg.time, 'dataStart')
    EEG.CTAP.time.dataStart = Arg.time.dataStart;
else
    EEG.CTAP.time.dataStart = EEG.CTAP.time.fileStart;
end

if isfield(Arg.time, 'dataStartOffsetSamp')
    EEG.CTAP.time.dataStartOffsetSamp = Arg.time.dataStartOffsetSamp;
else
    EEG.CTAP.time.dataStartOffsetSamp = NaN;
end


EEG.CTAP.history = create_CTAP_history_entry(...
        sprintf('CTAP struct created: %s', datetime), 'add_CTAP');
% This needs to be set up like this for the (end+1) appending to work
EEG.CTAP.err = struct;
if ~isempty(fieldnames(Arg.meta))
    EEG.CTAP.meta = Arg.meta;
end
