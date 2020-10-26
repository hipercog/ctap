function CsegMeta = gather_cseg_metadata(EEG, csegEvent)
%GATHER_CSEG_METADATA - Collects calculation segment metadata from EEG.event
%
% Description:
%   * collect calculation segment (cseg) related data from EEG.event
%   * output all in a standardised struct format
%
% Syntax:
%   CsegMeta = gather_cseg_metadata(EEG, csegEvent);
%   
% Inputs:
%   EEG             struct, EEGLAB struct
%   csegEvent       string, Event type for the event that specifies
%                   calculation segments
%
% Outputs:
%   CsegMeta    struct, CTAP internal result struct with fields "data",
%               "labels", "units"
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%   Used by CTAP_extract_*.m to add metadata to extracted features.
%
%   It might be helpful to include a field in EEG.event that tracks the
%   index of the calculation segment. This makes the detection of e.g.
%   rejected segment easier when analyzing features.
%
%   This code assumes that events that specify calculation segments have 
%   their latencies correct. Ideally they are added to the data when the 
%   data is still continuous to avoid any mistakes due to discontinuities
%   in time (boundary events). cseg time stamps are computed based on 
%   EEG.CTAP.time.dataStart.
%
%   This function returns almost all fields from EEG.event. Use arguments
%   to export_features_CTAP.m to limit the number of fields that are
%   actually written to the feature database.
%
% See also: CTAP_extract_*, export_features_CTAP
%
% Created 2015- Jussi Korpela
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
p.addRequired('EEG', @isstruct);
p.addRequired('csegEvent', @ischar);
p.parse(EEG, csegEvent);
Arg = p.Results;


%% 1: Create calculation segment timestamps and durations
[csdata, cslabels, csunits] = cseg_times(EEG, csegEvent, '',...
                                    'outputType','cell');
% Dataset start used as time zero.

data = {};
labels = {};
units = {};


% Store segment start times as 'timestamp'
start_time_dn = datenum(EEG.CTAP.time.dataStart, 'yyyymmddTHHMMSS');
data(:,1) = cellstr(datestr(start_time_dn + [csdata{:,1}] / (24*60*60), 30));
labels{1} = 'timestamp';
units{1} = 'yyyymmddTHHMMSS';

% Durations
%{
csdata = cell2mat(csdata);
csdur = csdata(:,2)-csdata(:,1);
data = horzcat(data, num2cell(csdur));
labels = horzcat(labels, 'csdur');
units = horzcat(units, 's');
%}


%% 2: Convert EEG.event into format required used in CsegMeta

% Leave out some unnecessary fields
% 'type' is not needed as all events are of type Setup.eeg.calc.segTypeStr
% 'urevent' is not used by CTAP
remove_fields = intersect({'type','urevent'},...
                          fieldnames(EEG.event));
eventstruct = rmfield(EEG.event, remove_fields);
% export_features_CTAP.m can be used to select what is actually exported to
% the result database. At this point all possibly relevant information is
% retained.

% extract event data
cseg_match = ismember({EEG.event.type}, csegEvent);
[data2, labels2] = struct_to_cell(eventstruct(cseg_match));
units2 = cell(1, length(labels2));
units2(:) = {'N/A'};

% convert latencies to continuous time latency values
idx = find(ismember(labels2, 'latency'));
data2(:,idx) = num2cell(eeg_urlatency_arr(EEG.event, cell2mat(data2(:,idx))));


%% Combine all three together
CsegMeta.data = horzcat(data, data2);
CsegMeta.labels = horzcat(labels, labels2);
CsegMeta.units = horzcat(units, units2);                                 
    
end %EOF
