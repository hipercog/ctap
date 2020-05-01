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
%   excludeBoundaries    boolean, sets whether to exclude csegs with boundaries
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
Arg = struct(...
    'm', NaN,...% in sec
    'overlap', 0.5,...% in percentage [0,1]
    'nfft', NaN,... % in samples (int), should be 2^x, nfft > m*srate
    'bandlimit', false,...
    'excludeBoundaries', true);
% Defaults are set in eeglab_psd()

% Override defaults with user parameters
if isfield(Cfg.ctap, 'compute_psd')
    Arg = joinstruct(Arg, Cfg.ctap.compute_psd); %override with user params
end


%% Sanity checks

if ~isfield(Cfg.event, 'csegEvent')
    error('CTAP_compute_psd:no_cseg_event',...
       'No ''cseg'' events passed, cannot define computation segments. Abort.');
end

cseg_match = ismember({EEG.event.type}, Cfg.event.csegEvent);
cseg_start = [EEG.event(cseg_match).latency]';
cseg_end = cseg_start + [EEG.event(cseg_match).duration]' - 1;
cseg_arr = horzcat(cseg_start, cseg_end);

% Check if any of the csegs contains a boundary event
if Arg.excludeBoundaries
    bound_match = ismember({EEG.event.type}, 'boundary');
    boundary_lat = [EEG.event(bound_match).latency];

    split_cseg = range_has_point(cseg_arr, boundary_lat);
    if sum(split_cseg) > 0
        warning('CTAP_compute_psd:csegError',...
             ['Some cseg events of type: ''%s'' overlap with boundary events.'...
             ' These cseg events will be removed.'], Cfg.event.csegEvent);
        idx = find(cseg_match);
        EEG.event(idx(split_cseg)) = [];
    end
end

% Check that last cseg remains within data
excess_cseg = cseg_end > size(EEG.data, 2);
if any(excess_cseg)
   warning('CTAP_compute_psd:csegError',...
         ['Some of the cseg events of type: ''%s'' exceed duration of data.'...
         ' These cseg events will be removed.'], Cfg.event.csegEvent);
    idx = find(cseg_match);
    EEG.event(idx(excess_cseg)) = [];
end


%% CORE

% Compute PSD, for all 'safe' channels
refchans = get_refchan_inds(EEG, EEG.CTAP.reference);
chans = setdiff(get_eeg_inds(EEG, 'EEG'), refchans);
if isempty(chans)
    chans = refchans; 
end
EEG.CTAP.PSD = eeglab_psd(EEG, Cfg.event.csegEvent,...
    'm', Arg.m,...
    'overlap', Arg.overlap,...
    'nfft', Arg.nfft,...
    'chansToAnalyze', {EEG.chanlocs(chans).labels});


%restrict output to previously filtered frequencies to save space
if Arg.bandlimit && any(ismember({EEG.CTAP.history.fun}, 'CTAP_filter_data'))
    idx = ismember({EEG.CTAP.history.fun}, 'CTAP_filter_data');
    lo = EEG.CTAP.history(idx).args.locutoff;
    hi = EEG.CTAP.history(idx).args.hicutoff;
    idx = EEG.CTAP.PSD.fvec >= floor(lo) ...
        & EEG.CTAP.PSD.fvec <= ceil(hi + EEG.CTAP.PSD.freqRes * 2);
    EEG.CTAP.PSD.data(:, :, ~idx) = [];
    EEG.CTAP.PSD.fvec(~idx) = [];
end


%% ERROR/REPORT
Cfg.ctap.compute_psd = Arg;

msg = myReport(sprintf('Estimated PSD for events of type  ''%s''.'...
    , Cfg.event.csegEvent), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
