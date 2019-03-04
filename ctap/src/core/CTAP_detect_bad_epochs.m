function [EEG, Cfg] = CTAP_detect_bad_epochs(EEG, Cfg)
%CTAP_detect_bad_epochs - Detect bad quality epochs (requires epoching)
%
% Description:
%   Detects bad quality epochs from epoched dataset. If the dataset is
%   continuous, this function fails
%   See also CTAP_detect_bad_segments() if your data is continuous.
%
% Syntax:
%   [EEG, Cfg] = CTAP_detect_bad_epochs(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_epochs:
%   .channels       integer array, A list of channels which should be
%                   analyzed, overrides .channelType, default: field does
%                   not exist
%   .channelType    string or cellstring, A list of channel type strings 
%                   that specify which channels are to be analyzed,
%                   default: 'EEG'
%   Other arguments as in ctapeeg_detect_bad_epochs().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_detect_bad_epochs() 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.channelType = 'EEG';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_epochs')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_epochs);  % override params
end

%% ASSIST
if ~isfield(Arg, 'channels')
    chidx = get_eeg_inds(EEG, Arg.channelType);
    Arg.channels = {EEG.chanlocs(chidx).labels};
elseif isnumeric(Arg.channels)
    chidx = Arg.channels;
    Arg.channels = {EEG.chanlocs(chidx).labels};
else
    chidx = get_eeg_inds(EEG, Arg.channels);
end

% Check that given channels are EEG channels
if isempty(Arg.channels) || ~all(ismember({EEG.chanlocs(chidx).type}, 'EEG'))
    myReport(['WARN ' mfilename ':: '...
        'EEG channel type has not been well defined,'...
        ' or given channels are not all EEG!'], Cfg.env.logFile);
end

% Don't pay attention to any bad or deliberately-excluded channels
if isfield(Arg, 'badchannels')
    Arg.channels = setdiff(Arg.channels, Arg.badchannels);
end
if isfield(EEG.CTAP, 'badchans') && isfield(EEG.CTAP.badchans, 'detect')
    Arg.channels = setdiff(Arg.channels, EEG.CTAP.badchans.detect.chans);
end


%% CORE
% Find bad epochs, from regular epoched data, for defined non-bad channels
% If not yet epoched, fail
if ~isfield(EEG, 'epoch') || isempty(EEG.epoch)
    % Note: Cannot detect epoched data from EEG.data since epoched data
    % with just one epoch looks like continuous data.
    % EEG.epoch is not much better since EEGLAB seems to drop EEG.epoch if
    % data has only two dimension. 
    % In sum: single epoch data cannot be processed!
    error('CTAP_detect_bad_epochs:noEpochs',...
          'Data is not epoched or has only one epoch: ABORT.');
else
    [~, params, result] = ctapeeg_detect_bad_epochs(EEG, Arg);
end

Arg = joinstruct(Arg, params);


%% PARSE
% Checking and fixing
if ~isfield(EEG.CTAP, 'badepochs') 
    EEG.CTAP.badepochs = struct;
end
if ~isfield(EEG.CTAP.badepochs, Arg.method) 
    EEG.CTAP.badepochs.(Arg.method) = result;
else
    EEG.CTAP.badepochs.(Arg.method)(end+1) = result;
end

% save the index of the badness for the CTAP_reject_data() function
if isfield(EEG.CTAP.badepochs, 'detect')
    EEG.CTAP.badepochs.detect.src = [EEG.CTAP.badepochs.detect.src;...
        {Arg.method, length(EEG.CTAP.badepochs.(Arg.method))}];
    [numbad, ~] = ctap_read_detections(EEG, 'badepochs');
    numbad = numel(numbad);
else
    EEG.CTAP.badepochs.detect.src =...
        {Arg.method, length(EEG.CTAP.badepochs.(Arg.method))};
    numbad = numel(result.epochs);
end

% parse and describe results
repstr1 = sprintf('Bad epochs by ''%s'' for ''%s'': '...
    , Arg.method, EEG.setname);
repstr2 = {EEG.CTAP.badepochs.(Arg.method).epochs};

prcbad = 100 * numbad / numel(EEG.epoch);
if prcbad > 10
    repstr1 = ['WARN ' repstr1];
end
repstr3 = sprintf('\nTOTAL %d/%d = %3.1f prc of epochs marked to reject\n'...
    , numbad, numel(EEG.epoch), prcbad);

EEG.CTAP.badepochs.detect.prc = prcbad;


%% ERROR/REPORT
% TODO - PLOT BAD EPOCHS, WITH RED LINES FOR CHANNELS CAUSING BADNESS?

Cfg.ctap.detect_bad_epochs = params;

msg = myReport({repstr1 repstr2 repstr3}, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, params);

end %EOF
