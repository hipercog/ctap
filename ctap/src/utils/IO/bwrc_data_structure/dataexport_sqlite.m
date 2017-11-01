function dataexport_sqlite(sourcefiles, dbfile, varargin)
%DATAEXPORT - Export contents of several ATTK data files into 1 output SQLite 
%           database
%
% Description:
%   Export contents of several ATTK data files into one output SQLite
%   database. Modified from 'dataexport_append.m'.
%
% Syntax:
%   [data  labels] = dataexport_sqlitew(sourcefile_arr, dbfile, ...
%                    data_variable_names, varargin);
%
% Inputs:
%   sourcefiles  [1,n] cell of strings, Full filenames of source .mat
%                   files
%   dbfile        string, Full filename of the output sqlite3 file.
%   data_variable_names     [1,p] cell of strings, Names of variables
%                           in data files that should be exported.
%                           If 'data_variable_names' does not exist or is
%                           empty, all variables are converted. See
%                           data2array.m for details.
%                           E.g. {'ResBPrel','ResBPabs'}
%   cseg_meta_variable_names    [1,r] cell of strings, Names of metadata
%                               fields to export from M.SEGMENT.
%   varargin        Keyword-value pairs
%       'strformat'     string, fprintf format for string values,
%                       default:'''%s''' for SPSS compatible files, '%s'
%                       might also be a good option for some programs
%       'intformat'     string, fprintf format for integer values,
%                       default:'3.0f'
%       'doubleformat'  string, fprintf format for double values,
%                       default:'6.3f'
%
% Outputs:
%   Writes output to an sqlite3 database.
%
% Assumptions:
%   All files must contain the same variables calculated using same
%   parameters and settings.
%
% References:
%   ATTK Matlab data structure documentation:
%   http://sps-doha-02/sites/329804/Aineistot/ATTK_Matlab_data_structure.doc
%
% Example:
%   sourcefile_arr = {'C:\work\file1.mat','C:\work\file1.mat'};
%   savefile = 'C:\work\csv\export.csv';
%   data_variable_names = {'HRV','BPV'};
%   [data  labels] = dataexport(sourcefile_arr, savefile,...
%                    data_variable_names);
%
%
% Notes:
%
% See also: datacat0.m, datacat1.m, data2array.m, cell2txtfile.m
%
% Version History:
% 04.11.2007 Created (Jussi Korpela, TTL)
% 19.02.2008 Added long and wide format (Andreas Henelius, TTL)
% 19.7.2010 Support for long format for sublevel 1 data added through
% improvements in data2array.m and datacat*.m (Jussi Korpela, TTL)
% 07.10.2014 Support for sqlite databases implemented (Jussi Korpela and
% Andreas Henelius, TTL)
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL
% =========================================================================
%% Parse input arguments and replace default values if given as input
p = inputParser;
p.addRequired('sourcefiles', @iscellstr);
p.addRequired('dbfile', @isstr);

p.addParameter('data_variable_names', {}, @iscellstr);
p.addParameter('cseg_meta_variable_names', {}, @iscellstr);
p.addParameter('strformat', '''%s''', @isstr);
p.addParameter('doubleformat', '%e', @isstr);
p.addParameter('intformat', '%e', @isstr);
p.addParameter('factorsVariable', 'FACTORS', @isstr);
p.addParameter('outputFormat', 'long', @isstr); 
% outputFormat can only be long when using a database


p.parse(sourcefiles, dbfile, varargin{:});
Arg = p.Results;

%% Create savepath
[pathstr, ~, ~]   = fileparts(dbfile);
if ~isdir(pathstr) && ~isempty(pathstr)
    mkdir(pathstr);
end

% Open database connection
dbid = mksqlite('open', dbfile);

%% Read data from file and create a data matrix
% data    = {};
% labels  = {};
% dbRowId = 1;

for i=1:numel(sourcefiles)
    [~, filename, ext] = fileparts(sourcefiles{i});
    msg = ['dataexport: Processing file ', [filename,ext], '...'];
    disp(msg);
    
    % Load data
    M      = load(sourcefiles{i});
    i_Meta = M.INFO;
    M      = rmfield(M, 'INFO');
    
    % Convert data to array form
    if isempty(Arg.data_variable_names)
        
        disp('Exporting all variables.')
        [i_data_array, i_labels] = data2array(M, [],...
            'outputFormat', Arg.outputFormat,...
            'factors_variable', Arg.factorsVariable);
    else
        resString = Arg.data_variable_names{1};
        
        for tmpi=2:numel(Arg.data_variable_names)
            resString = strcat(resString, ', ', Arg.data_variable_names{tmpi});
        end
        
        disp(['Exporting only variables: ' resString])
        
        [i_data_array, i_labels] = data2array(...
            M, Arg.data_variable_names,...
            'factors_variable', Arg.factorsVariable,...
            'outputFormat', Arg.outputFormat);
    end
    
    %% Subset cseg metadata variable names
    % All kinds of fields are inherited from EEG.event but only a handful
    % of them might make sense. Hence the subsetting.
    if ~isempty(Arg.cseg_meta_variable_names)
        removeFields = setdiff(M.(Arg.factorsVariable).labels,...
                           Arg.cseg_meta_variable_names);
        keepFields = setdiff(i_labels, removeFields);
        keepMatch = ismember(i_labels, keepFields);
        i_labels = i_labels(keepMatch);
        i_data_array = i_data_array(:,keepMatch);                    
    end
    
    %% Create format array
    if i == 1
        labels = i_labels;
        
        [~, datacols] = size(i_data_array);
        
        % Create 'format_array'
        strmatch = cellfun(@isstr, i_data_array(1,:));
        doublematch = cellfun(@isfloat, i_data_array(1,:));
        intmatch = cellfun(@isinteger, i_data_array(1,:));
        
        format_array = cell(1, datacols);
        format_array(strmatch) = repmat({Arg.strformat}, 1, sum(strmatch));
        format_array(doublematch) =...
            repmat({Arg.doubleformat}, 1, sum(doublematch));
        format_array(intmatch) = repmat({Arg.intformat}, 1, sum(intmatch));
    end
    
    %% Get the format array
    [fmt, types] = get_format_string(i_data_array(1,:));
    
    % add id, subject id and measurement id not present in the the data array
    fmt = ['%s, %i, ''%s'', ' fmt];
    
    %% Create the database
    
    % Re-create table 'results'
    if i == 1
        Tables = mksqlite('show tables');
        
        if isempty(Tables)
            Tables.tablename = '';
        end
        
        % Check existence of table 'subject'
        if ~ismember('subject', {Tables.tablename})
            query = ['CREATE TABLE subject (subjectnr INTEGER PRIMARY KEY,'...
                ' subjectstr TEXT, sex TEXT, age REAL)'];
            msg = mksqlite(dbid, query);
        end
        
        % Check existence of table 'measurement'
        if ~ismember('measurement', {Tables.tablename})
            query =['CREATE TABLE measurement (measurement TEXT PRIMARY KEY,'...
                ' session TEXT, description TEXT)'];
            msg = mksqlite(dbid, query);
        end
        
        % Re-create table 'results'
        if ismember('results', {Tables.tablename})
            msg = mksqlite(dbid, 'DROP TABLE results');
        end
        
        query =['CREATE TABLE results (id INTEGER PRIMARY KEY AUTOINCREMENT,'...
            ' subjectnr INTEGER, measurement TEXT, '];
        for ii = 1:numel(types)
            query = [query sprintf(...
                '%s %s', lower(i_labels{ii}), types{ii}) ', ']; %#ok<AGROW>
        end
        query(end-1:end) = '';
        query = [query ')'];
    
        msg = mksqlite(dbid, query); %#ok<*NASGU>
    end
    
    %% Write data-rows to database
    qs  = ['INSERT INTO results VALUES (', fmt, ')'];
    
    fprintf('Writing %u rows to the database...\n', size(i_data_array, 1));
    msg = mksqlite(dbid, 'BEGIN TRANSACTION');

    % Find out if there are any NaN values
    numColMatch = ismember(types, 'REAL');
    nanMatch = cellfun(@isnan, i_data_array(:, numColMatch), 'UniformOutput', true);
    nanRowsMatch = sum(nanMatch, 2) > 0;
    nArr = 1:size(i_data_array, 1);
    nOKArr = nArr(~nanRowsMatch);
    nNaNArr = nArr(nanRowsMatch);
    
    % write rows that do not contain NaN
    if ~isempty(nOKArr)
        for n = nOKArr
            mksqlite(dbid, sprintf(qs,...
            'NULL', i_Meta.subjectnr, i_Meta.measurement, i_data_array{n,:}));
        end
    end
    
    % write rows that do contain NaN
    if ~isempty(nNaNArr)
        fprintf('%d rows with NaN found. Writing them separately...\n', length(nNaNArr));
        for n = nNaNArr
            queryStr = sprintf(qs, 'NULL', i_Meta.subjectnr, i_Meta.measurement, i_data_array{n,:});
            queryStr = strrep(queryStr, 'NaN', 'NULL');
            mksqlite(dbid, queryStr);
        end
    end

    
    % Write subject related information
    query = sprintf('REPLACE INTO subject VALUES (%i, ''%s'', ''%s'', %f)',...
        i_Meta.subjectnr, i_Meta.subject, i_Meta.sex, i_Meta.age);
    mksqlite(dbid, query);
    
    % TODO: If a numeric input happens to be text, query becomes very odd.
    % Implement some argument checking for all query making.
    
    % TODO (feature-addition)(jkor): Separate subject and measurement 
    % related data in M.INFO
    % and add all subject related data dynamically to table 'subject'. That
    % is, get rid of the hard-coded fields above and require only some kind
    % of subject id / number for the minimal setup.
    
    % Write measurement related information
    i_Meta.description = 'dummy description';
    query = sprintf(...
        'REPLACE INTO measurement VALUES (''%s'', ''%s'', ''%s'')',...
        i_Meta.measurement, i_Meta.session, i_Meta.description);
    mksqlite(dbid, query);
    
    clear('i_', 'M');
    
    msg = mksqlite(dbid, 'END TRANSACTION');
    disp('... done.');
    
end

mksqlite(dbid, 'close');

end
