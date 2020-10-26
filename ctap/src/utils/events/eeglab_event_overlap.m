function inds = eeglab_event_overlap(event, target, neighbour, varargin)
%EEGLAB_EVENT_OVERLAP - Detects overlaps between events (EEGLAB compatible) 
%
% Description:
%   Can be used to detect overlaps between events. Input strings 'target'
%   and 'neighbour' define event types whose overlaps are of interest.
%   Can also search only for overlaps with following and/or preceding
%   'neighbour' events (see varargin).
%
% Syntax:
%   inds = eeglab_event_overlap(event, target, neighbour, varargin);
%
% Inputs:
%   event      struct, Event structure from EEG.event. Supports only event
%               tables whose .type field has only string values (see Notes).
%   target     string, Target event type, Event whose overlaps with 
%               'neighbour' are of interest
%   neighbour  string, Neighbouring event type, Event that possibly 
%               overlaps with 'target'
%
%   varargin    Keyword-value pairs
%   Keyword             Type, description, value
%   'searchDirections'  cell of strings, Search direction, default
%                       {'forward','backward'} which searches for both
%                       following and preceding neighbours, respectively 
%
% Outputs:
%   ind        [1,m] int, Indices of events of type 'target' that 
%              overlap with events of type 'neighbour'
%
% Assumptions:
%
% References:
%
% Example: inds = eeglab_event_overlap(EEG.event, 'seg', 'boundary'...
%                                      'searchDirections', {'forward'});
%
% Notes:
%   Supports only event tables (EEG.event) whose .type field contains only 
%   strings. Use eeg_checkevent.m to convert mixed type event table into
%   fully string type ones.
%
%   Assumes that neither 'target' nor 'neighbour' events extend over other 
%   events of the same type. Hence it can be assumed, that if there is no 
%   overlap between the nearest preceding event, there will not be 
%   overlap with the SECOND nearest preceding event either.
%
%   Contains a useful function overlap.m as a subfunction. Overlap.m
%   assesses overlaps in a very generic way.
%
% See also:
%
% Version History:
% 7.2.2008 Created (Jussi Korpela, TTL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.searchDirections = {'forward','backward'};
Arg.throwWarnings = true;

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Initialize output
inds=[];


%% Find target and neighbour positions
%MAYBEDO: Add support for numeric events in EEG.type. Not needed in CTAP though? 
targetpos = find(strcmp({event(:).type}, target));
neighbourpos = find(strcmp({event(:).type}, neighbour)); 

if isempty(targetpos)
    msg = ['Found no target events of type ''', target, '''.'];
    if Arg.throwWarnings
        warning('event_overlap:targetNotFound',msg);
    else
        fprintf(msg)
    end
    return; 
end

if isempty(neighbourpos)
    msg = ['Found no neighbour events of type ''', neighbour, '''.'];
    if Arg.throwWarnings
        warning('event_overlap:neighbourNotFound',msg);
    else
        disp(msg)
    end
    return;
end



%% Cycle through targets

for i = 1:length(targetpos)
    %DB: disp(['Round: ', num2str(i)]);
    
    i_npn_overlap = false(1,1);
    i_nfn_overlap = false(1,1);
    
    %% Search nearest preceding neighbours
    if sum(strcmp(Arg.searchDirections, 'backward'))==1
        
        i_npn = find(neighbourpos < targetpos(i), 1, 'last');
        if ~isempty(i_npn)
            % Preceding neighbour found
                        
            % Test for overlap
            i_npn_pos = neighbourpos(i_npn);
            i_npn_overlap = sbf_overlap(event(targetpos(i)).latency,...
                                    event(targetpos(i)).duration,...
                                    event(i_npn_pos).latency,...
                                    event(i_npn_pos).duration);
        end                           
    end
    
    
    %% Search nearest following neighbours 
    if sum(strcmp(Arg.searchDirections, 'forward'))==1

        i_nfn = find(targetpos(i) < neighbourpos, 1, 'first');
        if ~isempty(i_nfn)          
            % Following neighbour found
                            
            % Test for overlap
            i_nfn_pos = neighbourpos(i_nfn);
            i_nfn_overlap = sbf_overlap(event(targetpos(i)).latency,...
                                event(targetpos(i)).duration,...
                                event(i_nfn_pos).latency,...
                                event(i_nfn_pos).duration);
        end                           
    end
                        
                        
    % Store index if overlap found
    if i_npn_overlap || i_nfn_overlap
       inds = vertcat(inds, targetpos(i)); 
    end
    
    clear('i_');
end


%% Subfunctions
    function tf = sbf_overlap(start1, dur1, start2, dur2)
    % Tests if segments 1 and 2 overlap. Does not make a distinction
    % between partial and full overlap.
    % tf    [1,1] logical, TRUE if segments 1 and 2 overlap and FALSE 
    %                      if they do not.

    end1 = start1 + dur1 - 1;
    end2 = start2 + dur2 - 1;

    if (start2 <= start1) && (start1 <= end2)
        % Segment 1 beginning falls into segment 2 => overlap
        % True also if segment 1 falls entirely into segment 2
        tf = true(1,1);

    elseif (start2 <= end1) && (end1 <= end2)
        % Segment 1 end falls into segment 2 => overlap
        tf = true(1,1);
    
    elseif (start1 <= start2) && (start2 <= end1)
        % Segment 2 beginning falls into segment 1 AND
        % segment 1 end did not fall into segment 2 <=>
        % segment 2 falls entirely into segment 1 => overlap
        tf = true(1,1);
        
    else
        % Segments do not overlap
        tf = false(1,1);
    end
    end
end