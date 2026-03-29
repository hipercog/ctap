function [EEG, Cfg] = CTAP_select_evdata(EEG, Cfg)
%CTAP_select_evdata - Select a subset of continuous EEG data based on events
%
% Description:
%   Field Cfg.ctap.select_evdata.evtype has to be specified.
%   Select subset of data points by reference to an event type. For all events
%   'x' matching 'evtype', points from x.latency to x.latency + x.duration 
%   are selected / unselected.
%
% Syntax:
%   [EEG, Cfg] = CTAP_select_evdata(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.select_evdata:
%   .evtype     string, event type to select, 
%                default: 'all'
%   .evfield    string, choose an event field to search for 'evtype'
%                default: 'type'
%   .covertype  string, coverage of points around events, 
%                default: ''
%               'total' - select (1st evt + duration1) to (last evt + duration2)
%               'longest' - find x=longest gap between events, select 1st-x to last+x
%               'own' - use each event's own duration field, if exists
%               'next' - set evt duration = offset from next event; select by durations
%               'fixed' - use a fixed duration given by Arg.duration = [min max]
%               'pairs' - use 'evtype' to name 2 events to mark start & end of segments
%                         Event names can be in field 'type' or any other field, chosen
%                         using 'evfield'. See sbf_get_pair_lats() for pair matching 
%                         behaviour 
%   .match_fun  string, option to match evtype in 'pairs' mode, choose from
%                       startsWith, endsWith, or regexp
%                default: strcmp
%   .strict_pair logical scalar, for 'pairs' covertype, if true:
%                           take only strict pairs from the starts and ends lists;
%               if false & #starts > #ends:
%                           allow one more start to run to end of data
%                default: true
%   .duration   [1 2] numeric, Fixed millisec duration around selected events,
%                default: min, max = minus/plus zero second, i.e. -+0
%   .select     true/false, keep the data covered by designated events, or remove it
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_select_data()  
%
% Copyright(c) 2015:
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.evtype = 'all';      %Default event type to select

Arg.evfield = 'type';    %Default event field to select

Arg.covertype = 'total'; %Default coverage of points around events

Arg.strict_pair = true;

Arg.duration = [0 0];    %Default duration around selected events

Arg.select = true;

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
if isscalar(Arg.duration)
    if Arg.duration >= 0
        Arg.duration = [-Arg.duration Arg.duration];
    end
end


%% CORE
% Get matching events
if strcmpi(Arg.evtype, 'all')
    event_match = true(1, numel(EEG.event));
else
    event_match = ismember({EEG.event.(Arg.evfield)}, Arg.evtype);
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
        for evtix = 1:numel(EEG.event(event_match)) - 1
            EEG.event(evtix).duration = offsets(evtix);
        end
        EEG.event(end).duration = min(mean(offsets), EEG.pnts);
        event_lat(:,2) = event_lat(:,1) + [EEG.event(event_match).duration]';

    case 'fixed'
        event_lat = [event_lat + Arg.duration(1), event_lat + Arg.duration(2)];

    case 'pairs'
        event_lat = sbf_get_pair_lats(Arg.evtype, Arg.duration, Arg.evfield);
        Arg.evtype = catcellstr(Arg.evtype);
end

% Select
if Arg.select
    EEG = pop_select(EEG, 'point', event_lat);
else
    EEG = pop_select(EEG, 'rmpoint', event_lat);
end


%% QUALITY CONTROL
sbf_log_regions(event_lat, EEG, Arg, Cfg)


%% ERROR/REPORT
Cfg.ctap.select_evdata = Arg;

msg = myReport(sprintf('Crop data from: %s -- by event: %s -- of field: %s'...
    , EEG.setname, Arg.evtype, Arg.evfield)...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


    %% Subfunctions
    function [pair_lats, match_samps] = sbf_get_pair_lats(pairs, d_samples, fjeld)
        %% Parse input arguments and set varargin defaults
        p = inputParser;
        p.KeepUnmatched = true;
        
        p.addRequired('pairs', @iscell)
        p.addRequired('d_samples', @isnumeric)
        p.addRequired('fjeld', @ischar)
        
        p.parse(pairs, d_samples, fjeld);
        p = p.Results;

        if isfield(Arg, 'match_fun')
            switch Arg.match_fun
                case 'startsWith'
                    comp = @(c, pat) startsWith(c, pat);
                case 'endsWith'
                    comp = @(c, pat) endsWith(c, pat);
                case 'regexp'
                    comp = @(c, pat) ~cellfun('isempty', regexp(c, pat, 'once'));
            end
        else
            comp = @(c, pat) strcmp(c, pat);
        end
        
        % EEG is the EEGLAB/CTAP EEG struct
        n_samples = EEG.pnts;
        match_samps = false(1, n_samples);
        
        vals = {EEG.event.(p.fjeld)};        % cell array of strings/numbers
        start_mask = comp(vals, pairs(1));   % logical mask
        end_mask   = comp(vals, pairs(2));
        
        % Collect & sort sample indices for start,end events, adding duration trims
        starts = sort(round([EEG.event(start_mask).latency] + p.d_samples(1)));
        ends = sort(round([EEG.event(end_mask).latency] + p.d_samples(2)));

        % Greedy match: for each start, take the next end > start.
        j = 1;
        nE = numel(ends);
        nS = numel(starts);
        pair_lats = zeros(0, 2);
        aaaand_were_done = false;
        
        for i = 1:nS
            s = starts(i);
            % advance j until ends(j) > s (or j > nE)
            while j <= nE && ends(j) <= s
                j = j + 1;
            end
            if j <= nE
                e = ends(j);
                j = j + 1;   % consume this end for the next start
            elseif Arg.strict_pair
                break
            else
                e = n_samples;           % no more ends -> use end of data
                aaaand_were_done = true; % given starts are sorted, we cover all data
            end
            pair_lats(end+1,:) = [max(1,s), min(n_samples, e)]; %#ok<AGROW>
            match_samps(s:e) = true;
            if aaaand_were_done
                break
            end
        end

    end

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