function EEG = eeglab_blink2event(EEG, veog_signal, varargin)
%EEGLAB_BLINK2EVENT - Detect blinks and add them as events
% 
% Description:
%   Uses a dynamic function to detect blinks
%   Dynamic function should return blink latencies and, optionally, quality 
%   control data which can be used to make a plot in CTAP_blink2event()
% 
% Syntax:
%   EEG = eeglab_blink2event(EEG, veog_signal, varargin);
%
% Inputs:
%   EEG             struct, EEGLAB structure
%   veog_signal     vector, signal amplitude of the VEOG channel
% Varargin:
%   blinkDetectFun  function handle, name of a blink detection function
%                   default : eeg_detect_blink()
%                   Two outputs are expected:
%                   1. blink latency array, numeric [1 n], time in samples of blink events
%                   2. quality control, struct, with (at least) the fields:
%                      - isBlink, logical [1 n], 0 if not and 1 if blink
%                      - criterion name, char, metric used to separate out blinks
%                      - criterion value, numeric [1 n], value of metric
%
% Outputs:
%   EEG         struct, EEGLAB structure with added blink events
%
% Notes: 
%   User can pass in any parameters to be forwarded to the dynamic function 
%   'blinkDetectFun', because the inputParser field KeepUnmatched = true
%
% See also: eeglab_extract_eog()
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
%varargin name-value pairs for blink detection function stored in p.Unmatched
p.KeepUnmatched = true;
p.addRequired('EEG', @isstruct);
p.addRequired('veog_signal', @isnumeric);
p.addParameter('blinkDetectFun', @sbf_blinkdetector,...
                 @(x)isa(x,'function_handle'));
p.parse(EEG, veog_signal, varargin{:});
Arg = p.Results;


%% Core
% Detect blinks
QCData = NaN; %#ok<NASGU>
[blink_latency_arr, QCData] = Arg.blinkDetectFun(veog_signal, p.Unmatched);
EEG.CTAP.detected.blink.QCData = QCData;

if (~isempty(blink_latency_arr)) %were blinks found?
    % Make events
    event = eeglab_create_event(blink_latency_arr, 'blink'); 

    % Add to EEG
    EEG.event = eeglab_merge_event_tables(EEG.event, event,...
                                   'ignoreDiscontinuousTime'); 
    % debug:
    %{
    figure;
    plot(veog_signal);
    hold on;
    plot(blink_latency_arr, veog_signal(blink_latency_arr), '*r');
    hold off;
    %}
else
    warning('eeglab_blink2event:noBlinksFound',...
        'Found no blinks. Check input data.')
end


%% Subfunctions
    function [blinkLatencyArr, QCData] = sbf_blinkdetector(veog, varargin)
        [blinkLatencyArr, BD] = eeg_detect_blink(veog, EEG.srate, varargin{:});
        
        QCData.criterionValue = BD.Dv;
        QCData.criterionName = 'eogert Dv';
        QCData.isBlink = BD.clusters == 2;
        QCData.methodData = BD;
    end

end