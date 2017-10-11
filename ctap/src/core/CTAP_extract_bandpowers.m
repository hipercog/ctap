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
%   .fmin       [1,m] numeric, Frequency band starting frequencies in Hz
%   .fmax       [1,m] numeric, Frequency band ending frequencies in Hz
%   .extra_path string, another directory level to allow multiple calls in
%   one pipe
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
Arg.names ={'delta'...%1-4
            'theta'...%4-8
            'alpha1'...%8-10
            'iapf'...
            'alpha2'...%10-13
            'mu'...
            'beta1'...%13-18
            'beta2'...%18-30
            'gamma1'...%30-40
            'gamma2'...%40-50
            'gamma3'}; %50-sr/2
% canonical band powers = delta, theta, lo/hi-alpha, lo/hi-beta, low-gamma
fmx = round(EEG.srate / 2);
Arg.fmin = [1 4 8  10 13 18 30:10:min(49,fmx) 60:fmx:fmx]; %in Hz
Arg.fmax = [4 8 10 13 18 30 40:10:min(50,fmx) min(125,fmx):fmx:fmx];
%check and clean bandpowers
if numel(Arg.fmin) ~= numel(Arg.fmax)
    Arg.fmin = Arg.fmin(1:6);
    Arg.fmax = Arg.fmax(1:6);
end
for i = 1:numel(Arg.fmin)
    if Arg.fmin(i) == Arg.fmax(i)
        Arg.fmin(i) = [];
        Arg.fmax(i) = [];
    end
end
Arg.extra_path = '';

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
savepath = fullfile(Cfg.env.paths.featuresRoot, 'bandpowers', Arg.extra_path);
if isfield(Cfg, 'export'), Cfg.export.featureSavePoints{end + 1} = savepath; end
if ~isdir(savepath), mkdir(savepath); end
savename = sprintf('%s_bandpowers.mat', Cfg.measurement.casename);
save(fullfile(savepath,savename), 'INFO', 'SEGMENT', 'ResBPrel', 'ResBPabs');


%% ERROR/REPORT
Cfg.ctap.extract_bandpowers = Arg;

msg = myReport(sprintf('Extracted bandpowers from PSD.'), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
