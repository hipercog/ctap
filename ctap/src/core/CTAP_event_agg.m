function [EEG, Cfg] = CTAP_event_agg(EEG, Cfg)
%CTAP_EVENT_AGG create new events based on groups of old events, for epoch/export
%
% Description:
%   Events which match any on a given list can be used to form new events: this
%   can be extended to list of lists.
%   New events can be made by relabelling existing events (relabel event list)
%   or adding new events with same latency/duration but new type labels (add to 
%   event list). Relabel option can be complete, prepend, or append.
%   
%
% SYNTAX
%   [EEG, Cfg] = CTAP_event_agg(EEG, Cfg)
%
% INPUT
%   EEG         eeglab data struct
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.event_agg:
%   .evtype     cell array, [n 1] list of lists describing groups of event types
%                       that will be aggregated to values in .newevs
%   .newevs     cell str arr, [n 1] list of strings to use as new labels
%   .match      string, controls how to match 'evtype' strings to EEG events:
%                       'exact' (default) match complete string
%                       'starts' match if evtype begins the event label
%                       'contains' match if evtype occurs anywhere in event
%                       'ends' match if evtype ends the event label
%   .make       string, controls how to make new events from 'newevs':
%                       'add' (default) add new events with same latency
%                       'relabel' change existing event-type labels
%   .relabel    string, controls how to change existing event labels:
%                       'complete' (default) replace existing type labels
%                       'prepend' prepend existing event labels
%                       'append' append existing event labels
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2018:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.match = 'exact';
Arg.make = 'add';
Arg.relabel = 'complete';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'event_agg')
    Arg = joinstruct(Arg, Cfg.ctap.event_agg); %override w user params
end


%% ASSIST
if numel(Arg.evtype) ~= numel(Arg.newevs)
    myReport({'FAIL list of old events different size to list of new events: '...
                numel(Arg.evtype) numel(Arg.newevs)}, Cfg.env.logFile, newline);
end


%% CORE
evix = cell(numel(Arg.evtype), 1);
for ix = 1:numel(Arg.evtype)
    evlist = eeglab_validate_evlist(EEG, Arg.evtype{ix}, Arg.match);
    if isempty(evlist)
        myReport(['FAIL evtype not found: ' Arg.evtype{ix}], Cfg.env.logFile);
    end
    evix{ix} = ismember({EEG.event.type}, evlist);
end
switch Arg.make
    case 'add'
        allevs = cell(numel(Arg.evtype), 1);
        for ix = 1:numel(Arg.evtype)
            allevs{ix} = eeglab_create_event([EEG.event(evix{ix}).latency]...
                                                            , Arg.newevs{ix});
        end
        for ix = 1:numel(Arg.evtype)
            EEG.event = eeglab_merge_event_tables(EEG.event, allevs{ix},...
                                                'ignoreDiscontinuousTime');
        end

    case 'relabel'
        switch Arg.relabel
            case 'complete'
                [EEG.event(evix{ix}).type] = deal(Arg.newevs{ix});

            case 'prepend'
                [EEG.event(evix{ix}).type] = deal(cellfun(@(x) ...
                    [Arg.newevs{ix} x], {EEG.event(evix{ix}).type}, 'Un', 0));

            case 'append'
                [EEG.event(evix{ix}).type] = deal(cellfun(@(x) ...
                    [x Arg.newevs{ix}], {EEG.event(evix{ix}).type}, 'Un', 0));
        end
end



%% ERROR/REPORT
Cfg.ctap.event_agg = Arg;

switch Arg.match
    case 'starts'
        desc = 'start with';
    case 'ends'
        desc = 'end with';
    case 'contains'
        desc = 'contain anywhere';
    otherwise %'exact'
        desc = 'exactly match';
end
msg = repmat('SHSH', 1, numel(Arg.evtype));
for ix = 1:numel(Arg.evtype)
    msg = myReport({msg...
        newline ['Events which ' desc ' strings:'] Arg.evtype(ix)...
            newline 'Were aggregated under new label:' Arg.newevs(ix)});
end
myReport(msg, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


end % ctapeeg_export()
