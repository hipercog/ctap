function [ephits, lock_evname] = get_event_epochIdx(EEG, event)
%GET_EVENT_EPOCHIDX: find epochs with wanted event
% 
% Description:
%   Index epochs by requesting events within them. Pass the 'event' struct,
%   with fieldnames from the EEG's event structure and values to match events.
%   The logical AND of matches from all passed fields provides an event index;
%   these events occur inside a subset of epochs, and this set is returned.
% 
% Inputs:
%   EEG     struct, EEG structure to search
%   event   struct, 'name', 'value' pairs; names must match fieldnames in
%                   EEG.event; values must match some that occur in events
%                   E.g. 'type', 'target'
% 
%
% Copyright(c) 2019:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and check them
p = inputParser;

p.addRequired('EEG', @(x) isstruct(x) && all(isfield(EEG, {'epoch' 'event'})))
p.addRequired('event', @(x) isstruct(x) && numel(x) == 1)

p.parse(EEG, event)

if isempty(EEG.epoch)
    error('get_event_epochIdx:bad_EEG', 'EEG must be epoched!')
end

event_fnames = fieldnames(event);
% define 'match_fields' to index matched fields in request struct
match_fields = ismember(event_fnames, fieldnames(EEG.event));
if ~all(match_fields)
    error('get_event_epochIdx:bad_event'...
        , 'EEG.event does not have the requested fields: %s'...
        , strjoin(event_fnames(~match_fields), ', '))
end


%% Extract each field to be matched and test it
evhits = ones(1, numel(EEG.event));
for i = 1:numel(event_fnames)
    % HANDLE NON-CHAR FIELD TYPES
    if isnumeric(event.(event_fnames{i}))
        if ~all(cellfun(@isnumeric, {EEG.event.(event_fnames{i})}))
            error('get_event_epochIdx:mixed_data'...
                , 'EEG.event.%s has mixed numeric & non-numeric data'...
                , event_fnames{i})
        end
        evx = [EEG.event.(event_fnames{i})] == event.(event_fnames{i});
    else
        evx = ismember({EEG.event.(event_fnames{i})}, event.(event_fnames{i}));
    end
    evhits = evhits & evx;
end
ephits = false(1, EEG.trials);
ephits(unique([EEG.event(evhits).epoch])) = 1;

lock_evname = strjoin(struct2cell(event), '-');

end