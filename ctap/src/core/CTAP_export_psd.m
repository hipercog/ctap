function [EEG, Cfg] = CTAP_export_psd(EEG, Cfg)
%CTAP_export_psd  - Exports PSD values into a file for e.g. import into R etc.
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_export_psd(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.export_psd:
%   .timevar    string, Name of variable to use as calculation segment time
%               variable, Possible values are the field names of EEG.event
%               as reported by gather_cseg_metadata(), default: 'latency'
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.timevar = 'latency';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'export_psd')
    Arg = joinstruct(Arg, Cfg.ctap.export_psd); %override with user params
end

%% Collect PSD data into a "data.frame"

% Find out cseg latencies in continuous time
SEGMENT = gather_cseg_metadata(EEG, Cfg.event.csegEvent);

match = ismember(SEGMENT.labels, Arg.timevar);
if (strcmpi(Arg.timevar,'latency'))
    latencies =  cell2mat(SEGMENT.data(:,match)) / EEG.srate; %in sec
else 
    if isnumeric(SEGMENT.data{1,match})
        latencies = cell2mat(SEGMENT.data(:,match));
    else
        latencies = SEGMENT.data(:,match);
    end
end

% Make data structure
dimnames = {'channel', Arg.timevar,'freqband'};
dimlabels = {EEG.CTAP.PSD.chanvec,...
             latencies,...
             EEG.CTAP.PSD.fvec};
Psd = create_dataframe(EEG.CTAP.PSD.data, dimnames, dimlabels); %#ok<NASGU>


%% Save data
savepath = fullfile(Cfg.env.paths.featuresRoot, 'PSD');
if isfield(Cfg, 'export'), Cfg.export.featureSavePoints{end + 1} = savepath; end
if ~isdir(savepath), mkdir(savepath); end
savename = fullfile(savepath, sprintf('%s_PSD.mat', Cfg.measurement.casename));
save(savename, 'Psd');


%% ERROR/REPORT
Cfg.ctap.export_psd = Arg;

msg = myReport(sprintf('Exported PSD values to %s', savename), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
