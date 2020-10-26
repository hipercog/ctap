function [newevent, rejevent] = eeglab_merge_event_tables(event1, event2, timeSyncMode)
%EEGLAB_MERGE_EVENT_TABLES - Merges two event table structures (EEGLAB compatible)
%
% Description:
%   Merges two event table structures (EEG.event).
%   Events of type "boundary" can be present in one of the event tables but 
%   not in both. 
%   If the event table structures have different fields, missing
%   fields are appended to each structure. Missing values appear as NaN or
%   'NA' depending on the field type. 
%   BE CAREFUL WHEN MERGING EVENT TABLES. EVENT TABLES CAN REPRESENT EITHER
%   CONTINUOUS TIME OR DISCONTINUOUS TIME. USUALLY EVENT TABLES WITH
%   DISCONTINUOUS TIME CONTAIN "boundary" EVENTS BUT SOMETIMES THEY ARE
%   MISSING BECAUSE OF SOME MODIFICATIONS. USE THE ARGUMENT 'timeSyncMode'
%   TO CONTROL THE WAY IN WHICH LATENCY VALUES ARE MODIFIED DURING MERGE.
%   SEE THE "Algorithm" SECTION FOR DETAILS.
%
% Algorithm:
%   Case I - boundary events present
%       Let's assume "boundary" events are present in 'event1' but not in
%       'event2'. Now latencies after the first "boundary" event in 
%       'event1' represent DISCONTINUOUS time and all latencies in 'event2' 
%       represent CONTINUOUS time. If now'timeSyncMode' is set to 
%       'adjustDiscontinuousTime', latency values in 'event2' are adjusted 
%       to match the time discontinuities in 'event1'. Events in 'event2'
%       that overlap with "boundary" events in 'event1' are removed and not
%       included in the merge process.
%       But if 'timeSyncMode' is set to 'ignoreDiscontinuousTime', event
%       tables are merged "as-is" i.e. adjustments to latencies are not
%       made and events are not rejected.
%   Case II - boundary events not present
%       Since "boundary" events are not present, event tables can be merged
%       without modifications. In this case argument 'timeSyncMode' has no 
%       effect. 
%
%
% Syntax:
%   [newevent, rejevent] = eeglab_merge_event_tables(event1, event2, timeSyncMode);
%
% Inputs:
%   event#      struct, EEGLAB event table structure as in EEG.event
%               One of the inputs may contain 'boundary' events but not
%               both!
%   timeSyncMode string, values: {'adjustDiscontinuousTime',
%                                 'ignoreDiscontinuousTime'}
%               Use 'adjustDiscontinuousTime' if you want adjust the 
%               latency values of the continuous time event table to match 
%               those in the discontinuous one. This also rejects events 
%               that overlap with boundary events. 
%               Use 'ignoreDiscontinuousTime' if you want to merge the event
%               tables without any modifications to latency values.
%               The leading part of each string will also work.
%
% Outputs:
%   newevent    struct, EEGLAB event table structure that contains the 
%               merged data of event1 and event2. Field names changed into
%               lowercase, events sorted by latency.
%   rejevent    struct, EEGLAB event table structure that contains rejected
%               events. Events become rejected if their urlatency falls 
%               inside a boundary event. HOWEVER, events that start before
%               a boundary event but extend (.duration) into it
%               ARE NOT REJECTED.
%
% References:
%
% Example: 
%
% Notes:
%   pop_editeventfield.m should also be capable of adding events to an 
%   event structure. However, this feature doesn't seem to work properly...
%
% See also: pop_editeventfield, eeg_latency, eeg_urlatency,
% eeg_urlatency_arr
%
% Version History:
% 31.7.2009 Added required argument 'timeSyncMode' to draw user's attention
%           to the important issue of "boundary" events and discontinuous
%           event table time. (Jussi Korpela, TTL)
% 8.10.2007 Handling of differing fieldnames added (Jussi Korpela, TTL)
% 1.8.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check and ensure type field datatype is uniform
for idx = 1:numel(event1) 
    if isnumeric(event1(idx).type) 
        event1(idx).type = num2str(event1(idx).type);
    end
end
for idx = 1:numel(event2) 
    if isnumeric(event2(idx).type) 
        event2(idx).type = num2str(event2(idx).type);
    end
end


%% Detect discontinuous data (boundary events)
boundmatch1 = strcmp({event1.type},'boundary');
if sum(boundmatch1) == 0
    boundpresent1 = false; 
else
    boundpresent1 = true;
end

boundmatch2 = strcmp({event2.type},'boundary');
if sum(boundmatch2) == 0
    boundpresent2 = false; 
else
    boundpresent2 = true;
end

if (boundpresent1 && boundpresent2)
   msg = 'Boundary events present in both event tables. Cannot merge.';
   error('merge_event_tables:boundaryPrecenseError',msg);
    %MAYBEDO: Try to think if it is possible to merge two event tables that
    %both contain boundary events.
end


%% Convert event tables to cell arrays
event1 = orderfields(event1); %sort fields
[event1_cell, origlabels1] = struct_to_cell(event1); %convert, struct dim2 extended along cell dim1
origlabels1 = cellfun(@lower, origlabels1, 'UniformOutput', 0); % to lowercase
nummatch1 = cellfun(@isnumeric, event1_cell(1,:));
strmatch1 = cellfun(@isstr, event1_cell(1,:));

event2 = orderfields(event2);
[event2_cell, origlabels2] = struct_to_cell(event2); %convert, struct dim2 extended along cell dim1
origlabels2 = cellfun(@lower, origlabels2, 'UniformOutput', 0); % to lowercase
nummatch2 = cellfun(@isnumeric, event2_cell(1,:));
strmatch2 = cellfun(@isstr, event2_cell(1,:));


%% Add missing fields to each event structure
%%Event1
% Add to event1 fields that are present in event2 but not yet in event1
fields_missing_1 = origlabels2(~strArrayFind(origlabels2, origlabels1, 'matchMode', 'exact')); %missing fieldnames
ncols_orig1 = size(event1_cell,2);
ncols = ncols_orig1 + length(fields_missing_1);

[names_num, names_str] = classify_fieldnames(fields_missing_1, origlabels2, nummatch2, strmatch2);
add_position = ncols_orig1+1;
if numel(names_num)>0
    stopind = add_position+length(names_num)-1;
    event1_cell(:,add_position:stopind) = {NaN}; %assign empty cells
    add_position = stopind+1;
end
if numel(names_str)>0
    stopind = add_position+length(names_str)-1;
    event1_cell(:,add_position:stopind) = {'NA'}; %assign empty cells
end

event1 = cell2struct(event1_cell, horzcat(origlabels1, names_num, names_str), 2)'; %convert to struct for sorting
event1 = orderfields(event1); %sort fields
[event1_cell, labels1] = struct_to_cell(structconv(event1)); %convert to cell
clear('add_position','stopind','names_num', 'names_str');


%%Event2
fields_missing_2 = origlabels1(~strArrayFind(origlabels1, origlabels2, 'matchMode', 'exact')); %missing fieldnames
ncols_orig2 = size(event2_cell,2);
ncols = ncols_orig2 + length(fields_missing_2);
[names_num, names_str] = classify_fieldnames(fields_missing_2, origlabels1, nummatch1, strmatch1);
add_position = ncols_orig2+1;
if numel(names_num)>0
    stopind = add_position+length(names_num)-1;
    event2_cell(:,add_position:stopind) = {NaN}; %assign empty cells
    add_position = stopind+1;
end
if numel(names_str)>0
    stopind = add_position+length(names_str)-1;
    event2_cell(:,add_position:stopind) = {'NA'}; %assign empty cells
end

event2 = cell2struct(event2_cell, horzcat(origlabels2, names_num, names_str), 2)'; %convert to struct for sorting
event2 = orderfields(event2); %sort fields
[event2_cell, labels2] = struct_to_cell(structconv(event2)); %convert to cell
clear('add_position','stopind','names_num', 'names_str');


%% Check field consistency
if isempty(horzcat(setdiff(labels1,labels2), setdiff(labels2,labels1)))
    labels = cellfun(@lower, labels1, 'UniformOutput', 0);
else
    error('merge_event_tables','Event table fields are not identical. Aborting.'); 
end


%% Adjust continuous time latency values (if necessary)
if startsWith('adjustDiscontinuousTime', timeSyncMode, 'IgnoreCase', true)
    % NOTE: The code does not execute this far if both event tables contain
    % boundary values. Hence, we assume that only one of the event tables
    % or neither of them contains boundary values.
    if boundpresent1
        % Adjust latency in 'event2_cell' and reject events that overlap with
        % 'boundary' values
        [event2_cell, rejevent_cell] = adjust_latency(event1_cell, labels1, event2_cell, labels2);   
    elseif boundpresent2
        % Adjust latency in 'event1_cell' and reject events that overlap with
        % 'boundary' values
        [event1_cell, rejevent_cell] = adjust_latency(event2_cell, labels2, event1_cell, labels1);
    else
        rejevent_cell = {};
    end

    % Report rejected events and create output 'rejevent'
    if ~isempty(rejevent_cell)
        disp('merge_event_tables: Rejecting events that overlap with boundary events...');  
        rejevent = cell2struct(rejevent_cell, labels, 2)';
        %returns element-by-element organization
    else
        rejevent = struct([]);
    end
elseif startsWith('ignoreDiscontinuousTime', timeSyncMode, 'IgnoreCase', true)
    rejevent = struct([]);
    disp('merge_event_tables: ignoring discontinuous time...');
end


%% Create merged event table, sort events and convert back to struct
% Create
newevent_cell = vertcat(event1_cell, event2_cell);

% Sort
latency_ind = find( strcmp(labels, 'latency') );
newevent_cell = cellsort(newevent_cell, latency_ind);

% Back to struct
newevent = cell2struct(newevent_cell, labels, 2)'; %returns element-by-element organization



%% Subfunctions

function [names_num, names_str] = classify_fieldnames(names, fieldnames, nummatch, strmatch)
    
    fieldnames_num = fieldnames(nummatch);
    fieldnames_str = fieldnames(strmatch); 
    
    names_num = fieldnames_num(ismember(fieldnames_num, names));
    names_str = fieldnames_str(ismember(fieldnames_str, names));    
end
        
function [evarr, evrejarr] = adjust_latency(evarr_b, labels_b, evarr, labels)
    % Adjusts latency values in 'evarr' so that 'boundary' events in 
    %'evarr_b' are taken into account. This allows merging evarr and evarr_b
    %with simple catenation.
    
    % Returns 'evarr' with adjusted event latencies without events that
    % overlap with 'boundary' events.
    % 'evrejarr' contains events that overlapped with 'boundary' events.

    % Modify 'evarr' latency values 
    s = warning('off','eeg_latency:boundaryOverlap');
    lat_ind = strmatch('latency', labels);
    mod_latencies = eeg_latency(cell2struct(evarr_b, labels_b, 2)',...
                                   [evarr{:,lat_ind}]);
   
    % Detect and separate events that overlap with 'boundary' events
    nan_match = isnan(mod_latencies);
    evrejarr = evarr(nan_match,:);
    
    % Assing modified values and select non-overlapping
    evarr(:,lat_ind) = mat2cell(mod_latencies, 1,...
                                ones(1,length(mod_latencies)))';
    evarr = evarr(~nan_match,:);
end
	
end
