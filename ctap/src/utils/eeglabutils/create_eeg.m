function EEG = create_eeg(data, varargin)
%CREATE_EEG - Creates an EEG struct of EEGLAB format (EEGLAB compatible)
%
% Description:
%   Creates an EEGLAB compatible EEG structure with user defined data. In
%   EEGLAB this is usually called a dataset.
%
% Syntax:
%   EEG = create_eeg(data, varargin);
%
% Inputs:
%   data        [m,n] numeric, EEG data, channels in rows  
%               m = number of channels, n = data length
%               (see matrix "X" in "Notes")
%                
%   varargin    keyword-value pairs
%   Keywords:
%   fs              [1,1] numeric, sample rate in [Hz], It is strongly
%                   recommended that at least this value is set!
%   channel_labels  [1,m] cell of strings, channel names
%   icaweights      [k,m] numeric, Matrix H or W (if Q = I)
%   icasphere       [m,m] numeric, BSS sphering/whitening, Matrix Q
%   icawinv         [m,k] numeric, Matrix A
%   icaact          [k,n] numeric, Source components, Matrix S
%   icalabels       [k,1] cell of strings, Source component labels
%   oaSCInds        [1,p] int, indices of source components identified 
%                         as ocular artefact related
%   oaSCLabels      [1,p] cell of strings, Labels for the previous
%   blinkStruct     struct, output of blink_detect.m
%   eventStruct     struct, event struct of EEGLAB type
%   setname         string, Descriptive name for the dataset
%   comments        string, comments about the nature of the dataset
%   ttlhistory      [1,m] cell of strings, Entries for EEG.ttl.history
%
% References:
%
% Example: EEG = create_eeg(EEG.data, 'channel_labels', channels,...
%                    'fs', EEG.srate, 'eventStruct', Event,...
%                    'setname', 'sample dataset');  
%
% Notes:
% BSS matrix operations:
% Xs = Q*X %sphere/whiten data
% S = W*X = H*Q*X %unmix sources
% X = A*S  %mix sources
% A = pinv(W) = pinv(H*Q)
% W = pinv(A)
%
% See also: eeg_emptyset.m, pop_loadcnt.m, pop_loadeeg.m
%
% Version History:
% 1.8.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.

Arg.channel_labels = strcat('ch', cellstr(num2str(transpose( 1:size(data,1) ))) ); % 1-by-m cell of strings, channel names
Arg.fs = []; %1-by-1 numeric, sample rate

Arg.icaweights = []; % [k,m] numeric, Matrix H or W (if Q = I)
Arg.icasphere = []; % [m,m] numeric, BSS sphering/whitening Matrix Q
Arg.icawinv = []; % [m,k] numeric, Matrix A
Arg.icaact = []; % [k,n] numeric, Matrix S
Arg.icalabels = {}; % [k,1] cell of strings, Source component labels
Arg.oaSCInds = [];
Arg.oaSCLabels = {};
Arg.setname = 'No name';
Arg.comments = 'Empty';

Arg.blinkStruct = [];
Arg.eventStruct = [];

Arg.ttlhistory = {};


%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Create an ampty EEG dataset
% Uses default values
EEG = eeg_emptyset();


%% Assign data related fields to 'EEG'
EEG.data = data;
EEG.srate = Arg.fs;

EEG.nbchan = size(EEG.data, 1); %number of channels
EEG.pnts = size(EEG.data, 2); %number of time points (or data frames) per trial (epoch)
EEG.trials = size(EEG.data, 3); %number of epochs (or trials), third dimension spans over trials


if ~isempty(EEG.srate)
    EEG.times = (1:1:EEG.pnts)/EEG.srate;
    EEG.xmin = 0;
    EEG.xmax = EEG.times(end);
else
    EEG.times = [];
    EEG.xmin = [];
    EEG.xmax = [];
end

EEG.setname = Arg.setname;
EEG.comments = Arg.comments;

for i = 1:length(Arg.channel_labels)
    EEG.chanlocs(i).labels = Arg.channel_labels{i}; 
end

if ~isempty(Arg.eventStruct)
    EEG.event = Arg.eventStruct;
end

%% Assign BSS related fields
if ~isempty(Arg.icaweights)
    EEG.icaweights = Arg.icaweights;
end

if ~isempty(Arg.icasphere)
    EEG.icasphere = Arg.icasphere;
end

if ~isempty(Arg.icawinv)
    EEG.icawinv = Arg.icawinv;
end

if ~isempty(Arg.icaact)
    EEG.icaact = Arg.icaact;
end

if ~isempty(Arg.icalabels)
    EEG.icalabels = Arg.icalabels;
end


%% Assign TTL specific fields

% BSS based OAR related fields
if ~isempty(Arg.oaSCInds)
    EEG.oaSCInds = Arg.oaSCInds;
end

if ~isempty(Arg.oaSCLabels)
    EEG.oaSCLabels = Arg.oaSCLabels;
end

if ~isempty(Arg.blinkStruct)
    EEG.blink = Arg.blinkStruct;
end

%% Assign TTL history data
if isempty(Arg.ttlhistory)
    EEG.ttl.history(1) = {['EEG created: ',datestr(now)]};
else
    Arg.ttlhistory = Arg.ttlhistory(:)';
    EEG.ttl.history = cat(2, Arg.ttlhistory, {['EEG updated: ',datestr(now)]});
end
%[EOF]