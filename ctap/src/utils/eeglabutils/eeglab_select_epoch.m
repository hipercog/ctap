function epoch_match = eeglab_select_epoch(EEG, selection, eventfield)
% Helper function for the task of selecting EEG epochs.
% Epochselection is based on trigger events (see eeg_trigger_events.m) and
% factor-like grouping variables present in EEG.event.
%
% Description:
%   * Intended purpose
%   * What it does, preferably in list form
%   * Side effects (e.g. produces a plot)
%
% Algorithm:
%   * How the function achieves its results?
%
% Syntax:
%   [] = name();
%
% Inputs:
%   EEG     struct, EEGLAB epoched dataset
%   selection   [1,m] cell of strings, Values that define the epochs to 
%               select. Values in 'selection' are compared to values in 
%               EEG.event.(eventfield) for epoch trigger events.
%   eventfield  string, Name of the field in EEG.event that contains
%               class/selection information
%
% Outputs:
%   epoch_match     [1,n_epochs] logical, logical vector that can be used
%                   for selecting epochs. n_epochs = number of epochs in
%                   EEG dataset.
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also: eeg_trigger_events
%
% Version History:
% 12.10.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check inputs
if isempty(selection)
   selection = {'all'}; 
end


%% Select epochs
if (length(selection)==1) && strcmp(selection{1}, 'all')
    % Select all epochs
    epoch_match = true(1,size(EEG.data, 3));

else 
    % Select a subset of epochs
    trigevents = eeg_trigger_events(EEG); %length(trigevents)==length(EEG.epoch)
    epoch_match = ismember({trigevents(:).(eventfield)}, selection);
end