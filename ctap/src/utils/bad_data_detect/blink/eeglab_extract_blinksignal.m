function veog_signal = eeglab_extract_blinksignal(EEG, varargin)
%EEGLAB_EXTRACT_BLINKSIGNAL - Extract and preprocess blink signal from EEG struct
%
% Description:
%   Implements a single canonical way of extracting blink signal from EEG
%   struct.
%
% Algorithm:
%   * search veogUp and veogDown (see varargins veogUp/DownChannelNames)
%   * (substract)
%   * (invert)
%   * (filter)
%
% Syntax:
%   veog_signal = eeglab_extract_blinksignal(EEG, varargin);
%
% Inputs:
%   EEG     struct, EEGLAB EEG struct
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   See code below.
%
% Outputs:
%   veog_signal     [1,EEG.pnts] numeric, Ready to use blink signal
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also:
%
%
% Copyright 2015- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addParameter('veogUpChannelNames',...
                {'VEOGU','VeogU','veogu','VeogY','EOG_Up','RightUp','LeftUp'},...
                @iscellstr);
p.addParameter('veogDownChannelNames',...
                {'VEOGD','VeogD','veogd','VeogA','EOG_Down','RightDown','LeftDown'},...
                @iscellstr);
p.addParameter('blinkSignalType', 'channel-difference', @ischar);
p.addParameter('invertVeog', false, @islogical);
p.addParameter('filter', false, @islogical);
p.parse(EEG, varargin{:});
Arg = p.Results;


%% Define blink signal 'veog_signal'
switch lower(Arg.blinkSignalType)
    case 'single-channel'
        veogu_ind = find(ismember({EEG.chanlocs.labels},Arg.veogUpChannelNames));

        if isempty(veogu_ind)
            error('eeg_detect_blinks:EOGChannelNotFound','Cannot find EOG channel. Cannot compute.'); 
        end
        
        veog_signal = double(EEG.data(veogu_ind(1),:));
        
        if Arg.invertVeog
            blinkSigStr = ['-', EEG.chanlocs(veogu_ind).labels];
        else
            blinkSigStr = EEG.chanlocs(veogu_ind).labels;
        end
        disp(['Using ',blinkSigStr,' as blink signal...']);

    case 'channel-difference'
        veogu_match = ismember({EEG.chanlocs.labels},Arg.veogUpChannelNames);
        veogd_match = ismember({EEG.chanlocs.labels},Arg.veogDownChannelNames);
        
        if sum(veogu_match)~=1
            error('eeg_detect_blinks:veogUpChannelNotFound','Cannot find veogUp channel. Cannot compute.'); 
        end
        if sum(veogd_match)~=1
            error('eeg_detect_blinks:veogDownChannelNotFound','Cannot find veogDown channel. Cannot compute.'); 
        end
        
        veog_signal = double(EEG.data(veogu_match,:)-EEG.data(veogd_match,:));
        
        if Arg.invertVeog
            blinkSigStr = [EEG.chanlocs(veogd_match).labels,' - ',...
                           EEG.chanlocs(veogu_match).labels];
        else
            blinkSigStr = [EEG.chanlocs(veogu_match).labels,' - ',...
                           EEG.chanlocs(veogd_match).labels];
        end
        disp(['Using ',blinkSigStr,' as blink signal...']);
        
    otherwise
        error('eeg_detect_blinks:unknownBlinkSignalType',['Unknown Arg.blinkSignalType ',Arg.blinkSignalType,'''.'])
end


%% Modify blink signal for better performance

% Invert veog signal if requested
if Arg.invertVeog
    veog_signal = -veog_signal;
end

% Filter to remove baseline wander
if Arg.filter
    veog_signal = eegfilt(veog_signal, EEG.srate, 1, 0);
end
