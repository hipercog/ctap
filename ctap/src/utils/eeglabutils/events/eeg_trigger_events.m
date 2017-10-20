function trigger_event = eeg_trigger_events(EEG)
%EEG_TRIGGER_EVENTS - Return trigger events of an epoched EEG dataset
%
% Description:
%   Searches those events of an epoched EEG dataset that have been used as
%   epoch triggers. Returns a subset of EEG.event with only trigger events
%   present.
%
% Syntax:
%   trigger_event = eeg_trigger_events(EEG);
%
% Inputs:
%   EEG     struct, EEGLAB eeg dataset, must contain epoched data!
%
% Outputs:
%   trigger_event   struct, EEGLAB event struct with only events that have
%                   been used as epoching triggers. A subset of EEG.event.
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%   You can use e.g. 
%   trigev_str = cellstr2str(unique({trigger_event.type}),'sep','-');
%   to construct a neat string for example for documentation purposes.
%
% See also: pop_epoch
%
% Version History:
% 12.3.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check inputs
if isempty(EEG.epoch)
    msg = 'Dataset does not contain epochs.';
    error('eeg_trigger_events:badInput', msg);
end

if ismember('dummy_event',{EEG.event(:).type})
    % Dataset is probably dummy epoched
    is_dummy_data = true; 
else
    % Normal data
    is_dummy_data = false;
end
    
%% Initialize variables
n_epochs = numel(EEG.epoch);
trigger_events = cell(1, n_epochs);
trigger_event_inds = NaN(1, n_epochs);

%% Determine indices of triggerin events
% A triggering event has latency 0
for n = 1:n_epochs
    
    % Note: EEGLAB is inconsistent. If there is only one value in
    % .eventtype, the value is not wrapped into a cell. Otherwise
    % .eventtype is of type cell. Might be true for other fields as well...
    
    %% Store round data to temporary variables (to circumvent EEGLAB
    %% inconsistency)
    % This section might contain bugs, as it is not known how inconsistent
    % EEGLAB really is ...
    if iscell(EEG.epoch(n).eventtype)
        n_trgev_types = EEG.epoch(n).eventtype;
        n_trgev_latencies = [EEG.epoch(n).eventlatency{:}]; 
    else
        n_trgev_types = {EEG.epoch(n).eventtype};
        n_trgev_latencies = [EEG.epoch(n).eventlatency];   
    end

    %% Select epochs first event with latency 0 
    if is_dummy_data
        % Dummy dataset, return EEG.event as is
        trigger_event_inds(n) = n;
    
    else
        % Normal data
        
        % Find event with latency 0
        n_trgev_epochind = find(n_trgev_latencies==0, 1, 'first');
        % Assign event indices
        trigger_event_inds(n) = EEG.epoch(n).event(n_trgev_epochind);
    end
 
    clear('n_*');
end

%% Return only trigger events
trigger_event = EEG.event(trigger_event_inds);

end           