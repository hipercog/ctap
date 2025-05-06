function [bad_comp_match, scores] = ctapeeg_dtw_detect_eog_ics(EEG, varargin)
%CTAPEEG_DTW_DETECT_EOG_ICS measures each IC against the EOG signal by 
% dynamic time warping, to find blink-like ICs
% 
% Description: Similarity of each IC to the combined vertical EOG channel
% is measured by dtw() and ICs are ordered by this metric. 
% Then the top Arg.test_pc of ICs are tested in turn:
%  - IF ...
%  - THEN the IC is labelled as bad
% 
% Syntax:
%   [bad_comp_match, scores] = ctapeeg_dtw_detect_eog_ics(EEG, varargin)
% 
% Input:
%   EEG             struct, eeg data to test
%
% Varargin:
%   veog            string, channel name for VEOG, default = ''
%   test_pc         scalar, percentage of ICs to test, default = 25
% 
% Output:
%   bad_comp_match  logical, vector of logicals indexing bad ICs
%   scores          numeric, vector of veog dtw similarity of each IC
%
% See also: 
%   ctapeeg_recudetect_blink_ICs()
%
%
% Version History:
% 07.01.2025 Created (Benjamin Cowley, UH)
%
% Copyright(c) 2025 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched
p.addRequired('EEG', @isstruct)
p.addParameter('veog', '', @(x) iscellstr(x) || isstring(x) || ischar(x))
p.addParameter('test_pc', 25, @isscalar)
p.addParameter('invert_polarity', false, @islogical)
p.addParameter('blinkEventType', 'blink', @ischar)

p.parse(EEG, varargin{:})
Arg = p.Results;

if isempty(Arg.veog)
   error('ctapeeg_dtw_detect_eog_ics:veog_missing',...
     'Vertical EOG channel names needed for EOG extraction. Cannot proceed.');
end


%% CORE
% eog = eeglab_extract_eog(EEG, Arg.veog, Arg.veog...
%                        , 'invert_polarity', Arg.invert_polarity);

if ~any(ismember({EEG.event.type}, Arg.blinkEventType))
    error('ctapeeg_dtw_detect_eog_ics:blink_event_error'...
        , 'Could not find blink events. Did you run CTAP_blink2event?'); 
else
    EEGbl = pop_epoch( EEG, {'blink'}, [-0.05, 0.05]);
    EEGbl.icaact = eeg_getica(EEGbl);
    nics = numel(EEGbl.icachansind);
    b_ic_amps = zscore(reshape(permute(EEGbl.icaact, [1 2 3])...
                       , nics, EEGbl.pnts * EEGbl.trials));
    eog = eeglab_extract_eog(EEGbl, Arg.veog, Arg.veog...
                       , 'invert_polarity', Arg.invert_polarity);
    b_veog = zscore(eog.veog);
end

% blink_match = ismember({EEG.event.type}, Arg.blinkEventType);
% if sum(blink_match)>0
%     blink_inds = int64([EEG.event(blink_match).latency]);
%     b_ic_amps = zscore(EEG.icaact(:, blink_inds));
%     b_veog = zscore(eog.veog(blink_inds));
% else
%     error('ctapeeg_dtw_detect_eog_ics:blink_event_error'...
%         , 'Could not find blink events. Did you run CTAP_blink2event?'); 
% end

scores = NaN(nics, 1);
for i = 1:nics
    scores(i) = dtw(b_veog, b_ic_amps(i, :));
end

end%ctapeeg_dtw_detect_eog_ics