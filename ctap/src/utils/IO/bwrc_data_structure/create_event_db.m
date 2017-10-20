% Author: Andreas Henelius <andreas.henelius@ttl.fi>
%
%
function msg = create_event_db(dbfile, table_name, event_labels, event_types, clean)
%% Open database connection
dbid = mksqlite('open', dbfile);

%% Create the database
Tables = mksqlite('show tables');

if isempty(Tables)
    Tables.tablename = '';
end

%% Table 'subject'
if ~ismember('subject', {Tables.tablename})
    query = 'CREATE TABLE subject (subjectnr INTEGER PRIMARY KEY, subject TEXT, sex TEXT, age REAL)';
    msg = mksqlite(dbid, query);
else
    if clean
        msg = mksqlite(dbid, ['DROP TABLE ' 'subject']);
    end
end



%% Table 'measurement'
if ~ismember('measurement', {Tables.tablename})
    query = 'CREATE TABLE measurement (casename TEXT PRIMARY KEY, measurement TEXT, session TEXT, description TEXT)';
    msg = mksqlite(dbid, query);
else
    if clean
        msg = mksqlite(dbid, ['DROP TABLE ' 'measurement']);
    end
end


%% Table 'mc'
if ~ismember('mc', {Tables.tablename})
    query = 'CREATE TABLE mc (casename TEXT PRIMARY KEY, subject TEXT, recording TEXT, include INTEGER)';
    msg = mksqlite(dbid, query);
else
    if clean
        msg = mksqlite(dbid, ['DROP TABLE ' 'mc']);
    end
end


%% Table 'events'
if ~ismember(table_name, {Tables.tablename})
    % static fields
    query = ['CREATE TABLE ' table_name ' (id INTEGER PRIMARY KEY AUTOINCREMENT, subjectnr INTEGER, measurement TEXT, '];
    
    % dynamic fields
    for (ii = 1:numel(event_labels))
        query = [query sprintf('%s %s', lower(event_labels{ii}), event_types{ii}) ', '];
    end
    query(end-1:end) = '';
    query = [query ')'];
    
    msg = mksqlite(dbid, query);
else
    
    if clean
        msg = mksqlite(dbid, ['DROP TABLE ' table_name]);
    end
    
end
%% Close database connection
mksqlite(dbid, 'close');
end
