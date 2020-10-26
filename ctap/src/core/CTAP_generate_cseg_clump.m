function [EEG, Cfg] = CTAP_generate_cseg_clump(EEG, Cfg)
%CTAP_generate_cseg_clump - Generate calculation segments "clumped" together
%
% Description:
%   Note: user has to define Cfg.ctap.generate_cseg_clump.guideEvent!
%   Creates events of type Cfg.event.csegEvent into EEG.event to guide PSD
%   estimation.
%   Adds the calculation segments into "clumps" so that they are added only
%   to time ranges defined by some external guiding event. 
%
% Syntax:
%   [EEG, Cfg] = CTAP_generate_cseg_clump(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.generate_cseg_clump:
%   .guideEvent     string, Event type string of events specifying time
%                   ranges to which the cseg events are to be added 
%   .segmentLength  [1,1] numeric, cseg length in sec, default: 5
%   .segmentOverlap [1,1] numeric, cseg overlap in precentage, value range
%                   [0...1], default: 0
%   .csegEvent      string, Event type string for the events, 
%                   default: 'cseg'
%   Other arguments should match the varargin of
%   eeg_add_regular_events().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: eeglab_create_event()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
%Arg.guideEvent = user must specify this event
Arg.segmentLength = 2;%in sec
Arg.segmentOverlap = 0; %in percentage [0,1]
Arg.csegEvent = 'cseg'; %event type string

% Override defaults with user parameters
if isfield(Cfg.ctap, 'generate_cseg_clump')
    Arg = joinstruct(Arg, Cfg.ctap.generate_cseg_clump);
end


%% ASSIST
%   Find guiding events
match = ismember({EEG.event.type}, Arg.guideEvent);
idx = find(match);
guideEv.start = [EEG.event(match).latency];
guideEv.stop = guideEv.start + [EEG.event(match).duration]; %#ok<*STRNU>


%% CORE
%   Generate segments for each guiding event
csegArr = []; % to be [?,2] integer, [start, stop]
ruleArr = {};
for i=1:numel(idx)
    tmp = generate_segments(...
                EEG.event(idx(i)).duration,...
                floor(Arg.segmentLength*EEG.srate),...
                Arg.segmentOverlap);
    tmp = tmp + EEG.event(idx(i)).latency;
    csegArr = vertcat(csegArr, tmp);  %#ok<*AGROW>
    ruleArr = vertcat(ruleArr, repmat({EEG.event(idx(i)).rule},size(tmp,1),1));
    clear('tmp');
end

        
% Add segments as 'cseg' events
event = eeglab_create_event(csegArr(:,1),...
                            Arg.csegEvent,...
                            'duration', num2cell(csegArr(:,2)-csegArr(:,1)),...
                            'rule', ruleArr);
%EEG.event latency and duration are passed and stored in samples.


% Merge new events with existing data
EEG.event = eeglab_merge_event_tables(event, EEG.event,...
                                      'ignoreDiscontinuousTime');

EEG = eeg_checkset(EEG,'eventconsistency');


%% ERROR/REOPRT
Cfg.ctap.generate_cseg = Arg;

msg = myReport(sprintf('%d ''%s'' events addded to EEG.event.',...
    size(csegArr,1),Arg.csegEvent), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
