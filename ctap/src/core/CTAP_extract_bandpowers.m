function [EEG, Cfg] = CTAP_extract_bandpowers(EEG, Cfg)
%CTAP_extract_bandpowers  - Extract PSD band powers from EEG.CTAP.PSD
%
% Description:
%   Saves results into Cfg.env.paths.featuresRoot/bandpowers.
%
% Syntax:
%   [EEG, Cfg] = CTAP_extract_bandpowers(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.extract_bandpowers:'
%   .fmin   [1,m] numeric, Frequency band starting frequencies in Hz
%   .fmax   [1,m] numeric, Frequency band ending frequencies in Hz
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: psd_bandpowers()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.names ={'delta'...
            'theta'...
            'alpha1'...
            'iapf'...
            'alpha2'...
            'mu'...
            'beta1'...
            'smr'...
            'beta2'...
            'gamma1'...
            'gamma2'...
            'gamma3'};
% band powers = delta, theta, alpha, low beta, high beta, low-, mid-, high-gamma
Arg.fmin = [1 4 8  13 20 35 55  100]; %in Hz
Arg.fmax = [4 8 13 20 30 45 100 round(EEG.srate / 2)];
%TODO (BEN) - WORK OUT HIGHER BANDS BASED ON EEG.srate, in case srate <= 200Hz

% Override defaults with user parameters
if isfield(Cfg.ctap, 'extract_bandpowers')
    Arg = joinstruct(Arg, Cfg.ctap.extract_bandpowers); %override w user params
end


%% Gather measurement metadata (subject and measurement specific information)
INFO = gather_measurement_metadata(Cfg.subject, Cfg.measurement); %#ok<*NASGU>


%% Gather cseg metadata (calculation segment specific information)
SEGMENT = gather_cseg_metadata(EEG, Cfg.event.csegEvent);


%% Calculate RELATIVE bandpowers
[ResBPrel, infoBPrel] = psd_bandpowers(EEG.CTAP.PSD,...
    'fmin', Arg.fmin,...
    'fmax', Arg.fmax,...
    'valueType','relative'); %#ok<*ASGLU>


%% Calculate ABSOLUTE bandpowers
[ResBPabs, infoBPabs] = psd_bandpowers(EEG.CTAP.PSD,...
    'fmin', Arg.fmin,...
    'fmax', Arg.fmax,...
    'valueType','absolute');


%% Save
savepath = fullfile(Cfg.env.paths.featuresRoot,'bandpowers');
if ~isdir(savepath), mkdir(savepath); end
savename = sprintf('%s_bandpowers.mat', Cfg.measurement.casename);
save(fullfile(savepath,savename), 'INFO', 'SEGMENT', 'ResBPrel', 'ResBPabs');


%% ERROR/REPORT
Cfg.ctap.extract_bandpowers = Arg;

msg = myReport(sprintf('Extracted bandpowers from PSD.'), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
