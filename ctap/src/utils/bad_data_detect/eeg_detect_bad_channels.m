function [bad_chan_match, th, scores] = ...
    eeg_detect_bad_channels(EEG, refChannel, varargin)
%EEG_DETECT_BAD_CHANNELS - Detect bad channels using FASTER + multivariate
%outlier detection
%
% Description:
%
% Syntax:
%   bad_chan_match = eeg_detect_bad_channels(EEG, varargin)
%
% Inputs:
%   EEG         struct, EEGLAB struct
%   refChannel  string, Channel name of the reference channel
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'channels'      [1:k] integer, Channel indices of the channels to analyze,
%                   default: 1:size(EEG.data,1)
%   'factorVal'     int, factor by which to multiply mad of scores
%                   default:3
%
% Outputs:
%   bad_chan_match      [k,1] logical, A logical vector indicating the indices
%                       of the bad channels
%   th                  [1,2] numeric, An outlier score interval for good 
%                       channel outlier scores
%   scores              [k,1] numeric, Outlier scores for the channels
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also: mvoutlier
%
% Version History:
% 25.6.2014 Created (Jussi Korpela, FIOH)
%
% Copyright 2014- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('refChannel', @isstr);
p.addParameter('channels', 1:size(EEG.data,1), @isnumeric);
p.addParameter('factorVal', 3, @isnumeric);
p.parse(EEG, refChannel, varargin{:});
Arg = p.Results;

%% Compute channel properties (using FASTER)
disp('Computing channel properties (using FASTER) ...')
refChanInd = find(ismember({EEG.chanlocs.labels},Arg.refChannel));
if isempty(refChanInd)
   error(); 
end
cp = channel_properties(EEG, Arg.channels, refChanInd);
cp_header = {'corr','var','Hexp'}; %#ok<NASGU>

%% z-normalize
cp = nanzscore(cp,0,1); %normalization N-1

%% Define mvoutliers
disp('Detecting bad channels ...')
[bad_chan_match, th, scores] = mvoutlier(cp,'factorVal',Arg.factorVal);
