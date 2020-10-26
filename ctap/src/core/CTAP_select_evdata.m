function [EEG, Cfg] = CTAP_select_evdata(EEG, Cfg)
%CTAP_select_evdata - Select a subset of continuous EEG data based on events
%
% Description:
%   Field Cfg.ctap.select_evdata.evtype has to be specified.
%   Select subset of data points by reference to an event type. For all events
%   'x' matching 'evtype', points from x.latency to x.latency + x.duration 
%   are selected.
%
% Syntax:
%   [EEG, Cfg] = CTAP_select_evdata(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.select_evdata:
%   .evtype     string, event type to select, default: 'all'
%   .covertype  string, coverage of points around events, default: ''
%               'total' - select (1st evt + duration1) to (last evt + duration2)
%               'longest' - find x=longest gap between events, select 1st-x to last+x
%               'own' - use each event's own duration field, if exists
%               'next' - set evt duration = offset from next event; select by durations
%               'fixed' - use a fixed duration given by Arg.duration = [min max]
%   .duration   [1 2] numeric, Fixed millisec duration around selected events,
%                default: min, max = minus/plus one second, i.e. -+1000
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_select_data()  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.evtype = 'all';     %Default event type to select: all

Arg.covertype = 'total';  %Default coverage of points around events

Arg.duration = [-1000 1000]; %Fixed duration around selected events

% Override defaults with user parameters
if isfield(Cfg.ctap, 'select_evdata')
    Arg = joinstruct(Arg, Cfg.ctap.select_evdata);
end


%% ASSIST
if ~isfield(Arg, 'evtype')
    error(  'CTAP_select_evdata:inputError',...
            'Field Cfg.ctap.select_evdata.evtype has to be specified.');
end
%convert duration milliseconds to latencies
Arg.duration = Arg.duration .* (EEG.srate / 1000);


%% CORE
% Get matching events
if strcmpi(Arg.evtype, 'all')
    event_match = true(1, numel(EEG.event));
else
    event_match = ismember({EEG.event.type}, Arg.evtype);
end
if isempty(event_match)
    error(  'CTAP_select_evdata:selectedEventError',...
            'Event %s was not found.', Arg.evtype);
end

% Extract latencies of events
event_lat = [EEG.event(event_match).latency];
event_lat = event_lat(:);
switch Arg.covertype
    case 'total'
        event_lat = [event_lat(1) + Arg.duration(1)...
                   , event_lat(end) + Arg.duration(2)];

    case 'longest'
        mxgp = max(diff([EEG.event(event_match).latency]));
        event_lat = [event_lat(1) - mxgp, event_lat(end) + mxgp];

    case 'own'
        if isfield(EEG.event, 'duration')
            evdur = [EEG.event(event_match).duration];
            if any(isnan(evdur))
                error('CTAP_select_evdata:durationError',...
                    'Some event durations are NaN.');
            else
                event_lat = [event_lat event_lat + evdur(:)];
            end
        else
            error('CTAP_select_evdata:durationError',...
                    'Events have no ''duration'' field.');
        end

    case 'next'
        offsets = diff([EEG.event(event_match).latency]);
        for i = 1:numel(EEG.event(event_match)) - 1
            EEG.event(i).duration = offsets(i);
        end
        EEG.event(end).duration = min(mean(offsets), EEG.pnts);
        event_lat(:,2) = event_lat(:,1) + [EEG.event(event_match).duration]';

    case 'fixed'
        event_lat = [event_lat + Arg.duration(1), event_lat + Arg.duration(2)];

end

% Select
EEG = pop_select(EEG, 'point', event_lat);


%% QUALITY CONTROL
sbf_log_regions(event_lat, EEG, Arg, Cfg)


%% ERROR/REPORT
Cfg.ctap.select_evdata = Arg;

msg = myReport({'Crop data from: ' EEG.setname ' -- by event: ' Arg.evtype}...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


    %% Subfunctions
    function sbf_log_regions(evlats, eeg, args, conf)
        %Write regions found
        evdata = NaN(size(evlats,1), 5);
        header = {'#   ', 'start (s)   ', 'stop (s)    '...
                        , 'duration (s)', 'duration (min)'};

        evdata(:,2:3) = evlats;
        evdata(:,4) = evlats(:,2) - evlats(:,1); %duration in samp
        evdata = evdata / eeg.srate; %all values to sec
        evdata(:,5) = evdata(:,4)/60; %duration in minutes
        evdata = sortrows(evdata, 2); %just to make sure
        evdata(:,1) = 1:size(evdata,1);

        qcf = fullfile(conf.env.paths.logRoot...
                        , sprintf('%s_times.txt', mfilename));
        myReport(sprintf('Selected (subject,event) : %s,%s'...
                        , eeg.CTAP.measurement.casename, args.evtype), qcf);
        cell2txtfile(qcf, header, num2cell(evdata)...
                        , horzcat('%-4.0d', repmat({'%-12.1f'},1,4))...
                        , 'delimiter', ';', 'writemode', 'at');        
    end


end
