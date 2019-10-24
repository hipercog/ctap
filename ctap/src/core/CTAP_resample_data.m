function [EEG, Cfg] = CTAP_resample_data(EEG, Cfg)
%CTAP_resample_data - Resample data
%
% Description: Wrapper for pop_resample, adds coercion for parameters.
%
% Syntax:
%   [EEG, Cfg] = CTAP_resample_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.resample_data:
%   .newsrate   scalar, value to resample towards,
%               default: EEG.srate / 2
%   .sratemul   scalar, value to multiply existing srate by
%               default: 1 / 2
%   .fc         double, anti-aliasing filter cutoff (pi rad / sample)
%               default: 0.9
%   .df         double, anti-aliasing filter transition bandwidth (pi rad/sample) 
%               default: 0.2
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: if user passes 'newsrate' parameter, it OVERRIDES 'sratemul'
%
% See also: pop_resample()
%
% Copyright(c) 2018 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.sratemul = 1 / 2;
Arg.fc = 0.9;
Arg.df = 0.2;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'resample_data')
    Arg = joinstruct(Arg, Cfg.ctap.resample_data); %override with user params
else
    Cfg.ctap.resample_data = [];
end


%% ASSIST
Arg.fc = mod(Arg.fc, 1);
if ~isfield(Cfg.ctap.resample_data, 'newsrate')
    Arg.newsrate = EEG.srate * Arg.sratemul;
end


%% CORE
% Re-reference
EEG = pop_resample(EEG, Arg.newsrate, Arg.fc, Arg.df);
EEG.setname = strrep(EEG.setname, ' resampled', '');


%% ERROR/REPORT
Cfg.ctap.resample_data = Arg;

msg = myReport(sprintf('Resampled data to: ''%d'' for %s.'...
                                , Arg.newsrate, EEG.setname), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
