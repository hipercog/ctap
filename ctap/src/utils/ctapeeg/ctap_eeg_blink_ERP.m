function figh = ctap_eeg_blink_ERP(EEG1, EEG2, veogChanArr, varargin)
%CTAP_EEG_BLINK_ERP - A function to compare blink ERPs
%
% Description:
%   A short wrapper for ctap_eeg_compare_ERP.m with focus on blinks.
%
% Syntax:
%   figh = ctap_eeg_blink_ERP(EEG1, EEG2, veogChanArr, varargin)
%
% Inputs:
%   'EEG1'              struct, first EEG structure to compare
%   'EEG2'              struct, second EEG structure to compare
%   'veogChanArr'       cellstring, VEOG channel names 
%
%   varargin    Keyword-value pairs
%   Keyword             Type, description, values
%   'dataSetLabels'     [1, 2] cellstring, Data set ID strings
%
% Outputs:
%   'figh'              Figure handle
%
%
% Assumptions:
%
% References:
%
% Example: 
%
% Notes:
%
% See also: ctap_eeg_compare_ERP
%
%
% Copyright(c) 2015 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG1', @isstruct);
p.addRequired('EEG2', @isstruct);
p.addRequired('veogChanArr', @iscellstr);
p.addParameter('dataSetLabels', {'data1','data2'}, @iscellstr);

p.parse(EEG1, EEG2, veogChanArr, varargin{:});
Arg = p.Results;

%% Plot

if ( ~all(ismember(veogChanArr, {EEG1.chanlocs.labels})) )
   error('ctap_eeg_blink_ERP:veogChannelMismatch',...
         'Not all veog channels found in data.'); 
end

% EEG channels for the plot
blinkERPEEGChannels = horzcat(...
    get_channel_name_by_description(EEG1, 'frontal'),...
    get_channel_name_by_description(EEG1, 'vertex'));
chanArr = horzcat(veogChanArr, blinkERPEEGChannels);
chanMatch = ismember({EEG1.chanlocs.labels}, chanArr);


figh = ctap_eeg_compare_ERP(EEG1, EEG2, {'blink'},...
    'idArr', Arg.dataSetLabels,...
    'channels', {EEG1.chanlocs(chanMatch).labels},...
    'reverseYAxis', false,...
    'visible', 'off');
