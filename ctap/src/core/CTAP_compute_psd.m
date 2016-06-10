function [EEG, Cfg] = CTAP_compute_psd(EEG, Cfg)
%CTAP_compute_psd - Estimate PSD and add it to EEG.CTAP.PSD
%
% Description:
%   Estimates PSD in calculation segments (cseg) which are defined by
%   events of type Cfg.event.csegEvent. 
%
% Syntax:
%   [EEG, Cfg] = CTAP_compute_psd(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Make sure Cfg.event.csegEvent is set and events exist.
%   Cfg.ctap.compute_psd:
%   m           [1,1] numeric, Welch segment length in seconds, 
%               default: 1/4 of the calculation segment length
%   nfft        [1,1] integer, FFT length in [samples], [2^n],
%               value should be a power of two, default: next power
%               of two higher than Arg.m*EEG.srate
%   overlap     [1,1] numeric, Welch segment overlap, "percentage" value 
%               [0...1], default: 0.5 
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: eeglab_psd()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg = struct;
% Defaults are set in eeglab_psd()

% Override defaults with user parameters
if isfield(Cfg.ctap, 'compute_psd')
    Arg = joinstruct(Arg, Cfg.ctap.compute_psd); %override with user params
end

%% CORE
if ~isfield(Cfg.event, 'csegEvent')
    error('CTAP_compute_psd:no_cseg_event',...
        'No ''cseg'' events passed, cannot define computation segments. Abort.');
end

% Compute PSD, for all channels
EEG.CTAP.PSD = eeglab_psd(EEG, Cfg.event.csegEvent,...
    'm', Arg.m,....
    'overlap', Arg.overlap,...
    'nfft', Arg.nfft);

%% ERROR/REPORT
Cfg.ctap.compute_psd = Arg;

msg = myReport(sprintf('Estimated PSD for events of type  ''%s''.'...
    , Cfg.event.csegEvent), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
