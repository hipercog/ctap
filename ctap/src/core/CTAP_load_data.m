function [EEG, Cfg] = CTAP_load_data(~, Cfg)
%CTAP_load_data -  Load data into CTAP
%
% Description:
%   Uses ctapeeg_load_data() to check and load a file.
%   Information in Cfg.measurement (created by looper) defines which raw data
%   file is loaded.
%   See ctapeeg_load_data() for a list of supported file types.
%
% Syntax:
%   [EEG, Cfg] = CTAP_load_data(~, Cfg)
%
% Inputs:
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_data:
%   .type   string, Data type, default: '' which uses filename extension as
%           the data type. Use .type='neurone' if MC.physiodata contains
%           NeurOne data folders instead of traditional files. 
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_load_data() 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
if isfield(Cfg, 'measurement')
    Arg = Cfg.measurement;
    Arg.type = ''; %by default guesses file type from MC.physiodata file extension
else
    error('CTAP_load_data:no_measurement', 'Cfg.measurement MUST exist!');
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_data')
    Arg = joinstruct(Arg, Cfg.ctap.load_data);
end


%% CORE
[EEG, params, result] = ctapeeg_load_data(Arg.physiodata, Arg);


%% MISC
try result.meta; catch, result.meta = 'No meta data'; end
try result.time; catch, result.time = {now()}; end
%time_specs: { file start time string,
%              measurement start time string,
%              measurement start offset from file start in samples, default = 0}
time_specs = { datestr(result.time{1}, 30),...
               datestr(result.time{1}, 30),...
               0};


%% HANDLE EVENTS
if (isempty(EEG.event))
    % Add dummy event to avoid problems with functions that assume events exist
    EEG.event(1).type = 'dummy_event';
    EEG.event(1).latency = 1;
    EEG.event(1).duration = 0;
else
    %set EEG event type field to be char, to avoid mixing data format and
    %crashing, e.g. pop_epoch()
    for idx = 1:numel(EEG.event) 
        if isnumeric(EEG.event(idx).type) 
            EEG.event(idx).type = num2str(EEG.event(idx).type);
        end 
    end
end


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.load_data = Arg;

msg = myReport({'Load data, add CTAP, for ' Arg.physiodata}, Cfg.env.logFile);

EEG = add_CTAP(EEG, Cfg,...
    'time', time_specs,...
    'meta', result);


%% HANDLE CHANLOCS
if strcmp(EEG.CTAP.files.channelLocationsFile, '-UNSPECIFIED-')

    %define default types
    if ~isfield(EEG.chanlocs, 'type')
        EEG.chanlocs.type = 'EEG';
    else
        for idx = 1:numel(EEG.chanlocs)
            if isempty(EEG.chanlocs(idx).type)
                EEG.chanlocs(idx).type = 'EEG';
            end
        end
    end

end


EEG.CTAP.history = create_CTAP_history_entry(msg, mfilename, Arg);
