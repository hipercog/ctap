function measurement_config = mc_loader_sqlite(mc_source, varargin)
%MC_LOADER_SQLITE Load measurement configuration (MC) data
%
% Description
%
% Inputs
%
% Variable input arguments:
%
% Output
%
% Dependencies
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2011 Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  ========================================================================

%% Parse input arguments and replace default values if given as input
p = inputParser;
p.addRequired('mc_source', @isstr);
p.addOptional('dbfilter', {}, @isstruct);

p.addParamValue('mc_table', 'mc', @isstr);
p.addParamValue('events_table', 'events', @isstr);
p.addParamValue('blocks_table', 'blocks', @isstr);

p.parse(mc_source, varargin{:});
Arg = p.Results;

%% ========================================================================
% Create an sql query based on the filter
%% ========================================================================
% Empty structure (q) for the query filter. The structure will be filled only
% if a dbfilter is provided as an input argument.
q = {};
if ~isempty(Arg.dbfilter)
    filter_types = fieldnames(Arg.dbfilter);
    
    for i = 1:numel(filter_types)
        q.(filter_types{i}) = construct_query(Arg.dbfilter.(filter_types{i}));
    end
    
end
% =========================================================================

% Create default queries (this is needed, since we may not always
% want to give something to filter and we still need a default query to run
table_list = {Arg.mc_table, 'subject'};
query = {};
for i = 1:numel(table_list)
    if isfield(q, table_list{i})
        query.(table_list{i}) = ['select * from ' table_list{i} ' ' q.(table_list{i})];
    else
        query.(table_list{i}) = ['select * from ' table_list{i}];
    end
end

%% ========================================================================
% Read the measurement config from the database
% =========================================================================
% open the database for reading
dbid = mksqlite('open', mc_source);

% select all measurement data
query.(Arg.mc_table) = [query.(Arg.mc_table) ' order by casename'];
measurement_config.measurement = mksqlite(dbid, query.(Arg.mc_table));

% select all subject data
query.subject = [query.subject ' order by subject'];
measurement_config.subject = mksqlite(dbid, query.subject);

% close  the database connection
mksqlite(dbid, 'close')
% =========================================================================


end

%% A helper function used to construct an sql query given a cell array of
% criteria
function qs = construct_query(dbfilter)

fields = fieldnames(dbfilter);
q = cell(numel(fields), 1);
join_op = '=';

% Fields for which me must change the boolean operator type to 'and' instead of
% the default 'or' This is done to ensure that the querying feels "logical".
and_fields = {'id', 'subjectnr', 'age'};

for i = 1:numel(fields)
    
    if strmatch(fields{i}, and_fields, 'exact')
        bool_op = 'and';
    else
        bool_op = 'or';
    end
    
    %==================================================================
    nsub = numel(dbfilter.(fields{i}));

    if nsub == 1
        q{i} = ['(' fields{i} join_op '"' dbfilter.(fields{i}){1} '")'];
    else
        q{i} = [q{i} '(' fields{i} join_op '"' dbfilter.(fields{i}){1} '" ' bool_op ' '];
        for j=2:(nsub - 1)
           q{i} = [q{i} fields{i} join_op '"' dbfilter.(fields{i}){j} '" ' bool_op ' '];
        end
        q{i} = [q{i} fields{i} join_op '"' dbfilter.(fields{i}){nsub} '")' ];
    end
    %==================================================================
end

% Check if we must change the operator (e.g. = to > or <)
for i = 1:(numel(q))
    q{i} = strrep(q{i}, '="<=', '<="');
    q{i} = strrep(q{i}, '=">=',  '>="');
    q{i} = strrep(q{i}, '="<', '<"');
    q{i} = strrep(q{i}, '=">', '>"' );
end

% Now concatenate all these criteria to get the final query string
qs = 'where ';

for i = 1:(numel(q)-1)
    qs = [qs q{i} ' and '];
end
qs = [qs q{end}];

end


