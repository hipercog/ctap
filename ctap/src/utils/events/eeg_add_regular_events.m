function EEG = eeg_add_regular_events(EEG, evType, varargin)
%EEG_ADD_REGULAR_EVENTS - Add events to EEG
%
% Description:
%   Add regularly spaced events to EEG.event to enable computations.
%
% Syntax:
%   EEG = eeg_add_regular_events(EEG, evLength, evOverlap, evType, varargin)
%
% Inputs:
%   EEG         struct, EEGLAB struct, non-epoched data
%   evType      string, Event type string for the new events
%
% Varargin      Keyword-value pairs
% 
%   evLength    [1,1] numeric, Event length in seconds, default = 5
%   evOverlap   [1,1] numeric, Event overlap percentage [0..1], default = 0
%   startAt     str, Event type string for an event that is to be
%               considered time zero when adding the events
%   stopAt      str, Event type string for an event that is to be
%               considered end of generation range       
%
% Outputs:
%   EEG         struct, EEGLAB struct with new events of evLength at
%               with possible overlap.
% 
% Notes:
%   Assumes continuous time. Checks for boundary events within the generated 
%   segments and removes those segments.
%
% See also:
%
% Version History:
% 2015 Jussi Korpla, FIOH, jussi.korpela@ttl.fi
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('EEG', @isstruct)
p.addRequired('evType', @ischar)

p.addParameter('evLength', 5, @isnumeric)
p.addParameter('evOverlap', 0, @isnumeric)
p.addParameter('startAt', '', @ischar)
p.addParameter('stopAt', '', @ischar)

p.parse(EEG, evType, varargin{:})
Arg = p.Results;


%% Find a range to add events to
if ~isempty(EEG.event)
    
    startEventInd = find(ismember({EEG.event.type}, Arg.startAt));
    if isempty(startEventInd)
        disp('Starting from first sample.');
        startsample = 1;    
    else
        if length(startEventInd) > 1
            warning('eeg_add_regular_events:eventInconsistency'...
                , 'Several range start events found. Taking the first one.'); 
            startEventInd = startEventInd(1);
        end
        startsample = EEG.event(startEventInd).latency;
    end

    stopEventInd = find(ismember({EEG.event.type}, Arg.stopAt));
    if isempty(stopEventInd)
        disp('Stopping at last sample.');
        stopsample = EEG.pnts;

    else
        if length(stopEventInd) > 1
            warning('eeg_add_regular_events:eventInconsistency'...
                , 'Several range stop events found. Taking last one.');
            stopEventInd = stopEventInd(end); 
        end
        stopsample = EEG.event(stopEventInd).latency;
    end

else
    startsample = 1;
    stopsample = EEG.pnts;
end


%% Generate segments
csegArr = startsample - 1 + ...
          generate_segments(stopsample - startsample,...
                            floor(Arg.evLength * EEG.srate),...
                            Arg.evOverlap);


%% Prune out csegs which would contain a boundary event
if ~isempty(EEG.event)
    bound_match = ismember({EEG.event.type}, 'boundary');
    boundary_lat = [EEG.event(bound_match).latency];

    cs_keep_match = ~range_has_point(csegArr, boundary_lat);
    csegArr = csegArr(cs_keep_match,:);
end

        
%% Add segments as 'cseg' events
fprintf('eeg_add_regular_events: adding events of type ''%s''.', evType);

event = eeglab_create_event(csegArr(:,1),...
                            evType,...
                            'duration', num2cell(csegArr(:,2) - csegArr(:,1)) );
%EEG.event latency and duration are passed and stored in samples.


if isempty(EEG.event)
    % no existing events -> add directly
    EEG.event = event;
   
else
    % Merge new events with existing data
    EEG.event = eeglab_merge_event_tables(event, EEG.event,...
                                          'ignoreDiscontinuousTime');
    % Note: ignoring boundary events since they have been taken care of.
end
                              
EEG = eeg_checkset(EEG, 'eventconsistency');

end %EOF
