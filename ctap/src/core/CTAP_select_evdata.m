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
%   .evtype     string, event type to select
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
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg = struct();

% Override defaults with user parameters
if isfield(Cfg.ctap, 'select_evdata')
    Arg = joinstruct(Arg, Cfg.ctap.select_evdata);
end


%% ASSIST
if ~isfield(Arg, 'evtype')
    error(  'CTAP_select_evdata:inputError',...
            'Field Cfg.ctap.select_evdata.evtype has to be specified.');
end


%% CORE

% Extract latencies of events
event_match = ismember({EEG.event.type}, Arg.evtype);
if isempty(event_match)
    error(  'CTAP_select_evdata:selectedEventError',...
            'Event %s was not found.', Arg.evtype);
end
event_lat = [EEG.event(event_match).latency]';
event_lat = [event_lat, event_lat];
event_lat(:,2) = event_lat(:,1) + [EEG.event(event_match).duration]';

% Select
EEG = pop_select(EEG, 'point', event_lat);


%% QUALITY CONTROL
sbf_log_regions()


%% ERROR/REPORT
Cfg.ctap.select_evdata = Arg;

msg = myReport({'Crop data from: ' EEG.setname ' -- by event: ' Arg.evtype}...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


    %% Subfunctions
    function sbf_log_regions()
        %Write regions found
        evdata = NaN(size(event_lat,1), 5);
        header = {'#   ', 'start (s)   ', 'stop (s)    ',...
            'duration (s)', 'duration (min)'};

        evdata(:,2:3) = event_lat;
        evdata(:,4) = event_lat(:,2)-event_lat(:,1); %duration in samp
        evdata = evdata / EEG.srate; %all values to sec
        evdata(:,5) = evdata(:,4)/60; %duration in minutes
        evdata = sortrows(evdata, 2); %just to make sure
        evdata(:,1) = 1:size(evdata,1);

        qcf = fullfile(Cfg.env.paths.logRoot, sprintf('%s_times.txt', mfilename));
        myReport(sprintf('Selected (subject,event) : %s,%s'...
            , EEG.CTAP.measurement.casename, Arg.evtype), qcf);
        cell2txtfile(qcf, header, num2cell(evdata)...
            , horzcat('%-4.0d', repmat({'%-12.1f'},1,4))...
            , 'delimiter', ';', 'writemode', 'at');        
    end


end
