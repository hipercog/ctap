function [Min, Max, N] = eeglab_erp_peak(EEG, limits, epochselection, varargin)
%EEGLAB_ERP_PEAK - Detect ERP peak amplitude and latency from epoched EEG data, EEGLAB compatible
%
% Description:
%   Can be used to detect ERP peak amplitude and latency from epoched 
%   EEGLAB EEG data. Detects peaks using simple max() and min() functions
%   applied to the interval of interest. Optionally plot results for visual
%   inspection.
%
% Syntax:
%   [Min, Max] = eeglab_erp_peak(EEG, limits, epochselection, varargin);
%
% Inputs:
%   EEG             struct, EEGLAB EEG structure
%   limits          [1,2] numeric, Latency range with respect to time 
%                   locking event, unit [ms], assumes that EEG.times is
%                   also expressed in [ms].
%                   If limits(1)==limits(2) the no search is done but the
%                   value at the given latency is returned for all
%                   channels. Can be used when one channel is used as the
%                   main channel based on which the correct latency is
%                   decided.
%   epochselection  [1,k] cell of strings, Allows the selection of a subset
%                   of epochs for ERP calculation. Selects epochs by comparing 
%                   'epochselection' to values in 
%                   {EEG.event.(Arg.epoch_classifier_field)} for trigger events.
%                   If set to {} | {'all'}, all epochs will be included  
%   varargin        Keyword-value pairs,
%   Keyword                     Value
%   'epoch_classifier_field'    string, Name of the EEG.epoch.<field> that
%                               divides epochs in groups, default: 'range'
%                               Note that <field> should contain only
%                               single string values which is usually not
%                               the case in EEG.epoch.
%   'dbplot'                    'yes'/'no', Plot the ERPs, minima and 
%                                maxima in one figure for inspection
% Outputs:
%   Min     [1,1] struct, Properties of found minima
%    .amplitude  [m,1] numeric, Amplitudes for channels 1:m in same 
%                   units as EEG.data, NaN if local min/max found at search 
%                   interval boundary 
%    .latency    [m,1] numeric, Latencies for channels 1:m in ms 
%    .dataind    [m,1] numeric, Position in samples from data beginning 
%                   such that EEG.times(Min.dataind) = Min.amplitude
%   Max     struct, Properties of found maxima, see 'Min' for details
%   N       [1,1] numeric, Number of epochs averaged for the result
%
%   m = number of channels in EEG = EEG.nbchan
%
% References:
%
% Example: [Min, Max] = eeglab_erp_peak(EEG, [200 500],{'D1'});
%
% Notes:
%
% See also:
%
% Version History:
% 29.11.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse inputs
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('limits', @isnumeric);
p.addRequired('epochselection', @iscell);
p.addParameter('epoch_classifier_field', '', @isstr);

p.parse(EEG, limits, epochselection, varargin{:});
Arg = p.Results;


%% Check inputs
%%Fix EEG.times value
% EEG.times not set by pop_epoch.m, if there is only one epoch found.
% TODO: Selvit� xmin, xmax ja times k�yt�n logiikka EEGLABissa
if isempty(EEG.times)
    EEG.times = linspace(EEG.xmin*1000, EEG.xmax*1000, EEG.pnts);
    % eeg_checkset.m defines EEG.times such that it is non empty only if
    % EEG.trials > 1. Reason unknown, based on eeg_checkset.m help it seems
    % EEG.xmin, EEG.xmax and EEG.times are all defined only for epoched 
    % datasets...
    % Hence, running eeg_checkset.m on continuous data will set EEG.times
    % to empty. The same happens to epoched data with just one epoch.
end


%% Select time range
if isempty(limits)
   limit_match = true(1, size(EEG.data, 2)); 
else
   limit_match = (limits(1) <= EEG.times) & (EEG.times <= limits(2));
   % EEG.times expressed in ms (at least for epoched data) 
end


%% Select epochs to include
% Epochselection based on fields in EEG.event (only for trigger events).
epoch_match = eeglab_select_epoch(EEG, epochselection,...
                                  Arg.epoch_classifier_field);

% Warn if no epochs meet the criteria
if sum(epoch_match)==0
   msg = ['None of the epochs match your selection EEG.event.',...
       Arg.epoch_classifier_field, '=={', strjoin(epochselection,','),...
       '}. Check your selection.'];
   warning('eeglab_erp_peak:noEpochsSelected', msg);
end


%% Average ERPs
erparray = mean(EEG.data(:,:,epoch_match),3);


%% Find min and max
n_samples = sum(limit_match);
[Min.amplitude, min_pos] = min(erparray(:,limit_match),[],2);
[Max.amplitude, max_pos] = max(erparray(:,limit_match),[],2);
% Note: variables '*_pos' indicate position relative to search window


%% Create output
% Search window data latencies:
latency_arr = EEG.times(limit_match);
% Search window start offset from epoched data beginning:
offset_samples = find(limit_match, 1, 'first')-1; 

% Minimum values
if sum(limit_match==1)
    % Only one sample as the search limits, value allowed to be at boundary
    min_incorrect_match = false(1,numel(min_pos));
else
    min_incorrect_match = (min_pos == 1) | (min_pos == sum(limit_match));
end
Min.amplitude(min_incorrect_match) = NaN;
Min.latency = latency_arr(min_pos);
Min.latency(min_incorrect_match) = NaN;
Min.dataind = offset_samples + min_pos; 

% Maximum values
if sum(limit_match==1)
    % Only one sample as the search limits, value allowed to be at boundary
    max_incorrect_match = false(1,numel(max_pos));
else
    max_incorrect_match = (max_pos == 1) | (max_pos == sum(limit_match));
end
Max.amplitude(max_incorrect_match) = NaN;
Max.latency = latency_arr(max_pos);
Max.latency(max_incorrect_match) = NaN;
Max.dataind = offset_samples + max_pos; 

N = sum(epoch_match);