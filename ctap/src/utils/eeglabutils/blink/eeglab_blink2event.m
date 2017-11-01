function EEG = eeglab_blink2event(EEG, veog_signal, varargin)
%EEGLAB_BLINK2EVENT - Detect blinks and add them as events

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('veog_signal', @isnumeric);
p.addParameter('blinkDetectFun', @sbf_blinkdetector,...
                 @(x)isa(x,'function_handle'));
p.addParameter('vargs2blinkdetfun', {}, @iscell); %varargin name-value pairs for blink detection function
p.parse(EEG, veog_signal, varargin{:});
Arg = p.Results;


%% Core

% Detect blinks
QCData = NaN; %#ok<NASGU>
[blink_latency_arr, QCData] = Arg.blinkDetectFun(veog_signal, ...
                                                 Arg.vargs2blinkdetfun{:});

if (~isempty(blink_latency_arr)) %some blinks found
    
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
    error('eeglab_blink2event:noBlinksFound',...
        'Found no blinks. Check input data.');
end

if exist('QCData', 'var')
    EEG.CTAP.detected.blink.QCData = QCData;
    
%     fh = figure();
%     x = randn(1, length(QCData.criterionValue));
%     plot(x(QCData.isBlink), QCData.criterionValue(QCData.isBlink), 'ro');
%     hold on;
%     plot(x(~QCData.isBlink), QCData.criterionValue(~QCData.isBlink), 'ko');
%     hold off;
    
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