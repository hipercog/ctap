function event = eeglab_create_event(latency, type, varargin)
%CREATE_EVENT - Create EEGLAB event structure (EEGLAB compatible)
%
% Description:
%   Creates an event structure that is compatible with EEGLAB. Only fields
%   latency and type must be specified (as required in EEGLAB
%   specifications).
%   Other fields can be defined using varargin.
%   If a field is defined empty in varargin, it will assume values NaN (numeric).
%
%   create_event was originally created because pop_editeventfield.m did
%   not function as expected in appending data to an existing event 
%   structure. However, later experimentation revealed the right syntax.
%   You should use pop_editeventfield with syntax like this: 
%   EEG = pop_editeventfield(EEG,'indices', 1:length(EEG.event),'epoch', {NaN});
%   (This adds a new field 'epoch' to every event with value NaN. More
%   cryptic examples in pop_editeventfield.m)
%
%   Create_event.m together with merge_event_tables.m can be used to create 
%   and merge two event tables. Notice that merge_event_tables.m treats
%   each input event table as unique and the resulting event table will be
%   of length length(table1)+length(table2). Hence adding a single field is
%   usually easier to do with pop_editeventfield.m.
%
%
% Syntax:
%   event = create_event(latency, type, varargin);
%
% Inputs:
%   latency     [1,n] numeric, Event latencies in [samples]
%   type        [1,n] cell/numeric OR [1,1] cell/numeric OR string,
%               Event types for the events. If length(type)==1 or 
%               ischar(type)==1 each event defined by latency will get the 
%               same value. Numeric inputs are converted into strings.
%               Values wrapped into cell arrays are currently
%               not checked nor converted, so user will be responsible of 
%               their type.
%               length 1, will be 
%   varargin    keyword-value pairs
%               Other fields to add into 'event'. Keyword can be any
%               string. Value should be a cell array of values, lengths
%               [1,n] and [1,1] are allowed. {[]} defines an empty field.
%               Notice that any parameters other than optional event fields
%               cannot be passed to create_event through varargin.
%
% Outputs:
%   event       struct, EEGLAB compatible event table structure as in
%                       EEG.event
%
% References:
%   Delorme, A.; Fernsler, T.; Serby, H. & Makeig, S. EEGLAB tutorial, 2006
%
% Example: 
%   event1 = create_event(1:10, {'etype1'}, 'duration',...
%                   num2cell((1:10)*2),'userfield1',{'test'},'userfield2',{[]});
%
% Notes:
%
% See also: merge_event_tables.m, pop_editeventfield.m
%
% Version History:
% 11.10.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Currently only optional event fields can be passed to create_event 
% as arguments through varargin.
Arg = struct();

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg, 'useKeyChecking', false);
    % Keys should not be checked as default values never exist. This
    % function uses varargin unconventionally.
end

%% Separate parameters and fieldname-value pairs


%% Handle inputs

% For 'type': convert string to cell of strings
if ischar(type)
   type = {type}; 
end

% For 'type': convert numeric to cell of strings
if isnumeric(type)
   type = num2cell(type);
   type = cellfun(@num2str, type, 'UniformOutput', false);
end

% For 'type': add values if necessary
if length(type) == 1
    type2 = cell(length(latency),1);
    type2(:) = type(1);
    type = type2; clear('type2');
end

% To column cell arrays
latency = latency(:);
type = type(:);


% User defined fields: add values if necessary
userfields = fieldnames(Arg);

if ~isempty(userfields)
    for k = 1:length(userfields)
       if length(Arg.(userfields{k})(:)) == 1
           % Field value vector is of length 1
           % Fields with value vectors longer than one are skipped (but
           % checked later against latency vector length)
          
           if isempty(Arg.(userfields{k}){:})
                % Only fieldname defined, value array empty
                Arg.(userfields{k}) = cell(length(latency),1);
                Arg.(userfields{k})(:) = {NaN};

           else
                % Both fieldname and value defined
                kValue = Arg.(userfields{k}){1}; %field info into temp variable
                Arg.(userfields{k}) = cell(length(latency),1);
                Arg.(userfields{k})(:) = {kValue};
                clear('kValue');
           end
       end
    end    
end


%% Check input consistency

% Required variables
if length(type) ~= length(latency)
    error('create_event:badInput',...
        'Input vector lengths do not match between ''type'' and ''latency''.');
end 

% Varargin variables
if ~isempty(userfields) 
    for k = 1:length(userfields)
       if length(latency) ~= length(Arg.(userfields{k}))
            error('create_event:badInput','Input vector lengths do not match.');
       end
    end
end


%% Assign values
event = repmat(struct('type', NaN, 'latency', 0), length(type), 1);
for i = 1:length(type)
   
    event(i).type = type{i};
    event(i).latency = latency(i);
    
    for k = 1:length(userfields)
        event(i).(userfields{k}) = Arg.(userfields{k}){i};
    end
end