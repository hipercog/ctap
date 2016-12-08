function [data,  labels, n_factors] = dataexport_append(sourcefile_arr, savefile, data_variable_names, varargin)
%DATAEXPORT - Export contents of several ATTK data files into one output table
%
% Description:
%   Export contents of several ATTK data files into one output text file.
%   By modifying the varargin parameter values, the output can be made
%   compatible with almost any analysis program such as R, GGobi and
%   Orange.
%
% Syntax:
%   [data  labels] = dataexport(sourcefile_arr, savefile, ...
%                    data_variable_names, varargin);
%
% Inputs:
%   sourcefile_arr  [1,n] cell of strings, Full filenames of source .mat
%                   files
%   savefile        string, Full filename of the output txt file, Leave out
%                   or define as [] if text file output is not desired
%   data_variable_names     [1,p] cell of strigs, Names of variables
%                           in data files that should be exported.
%                           If 'data_variable_names' does not exist or is
%                           empty, all variables are converted. See
%                           data2array.m for details.
%   varargin        Keyword-value pairs
%       'outputFormat'  Specify output format for export.
%                       Can be either 'long' (default) or 'wide'.
%       'strformat'     string, fprintf format for string values,
%                       default:'''%s''' for SPSS compatible files, '%s'
%                       might also be a good option for some programs
%       'intformat'     string, fprintf format for integer values,
%                       default:'3.0f'
%       'doubleformat'  string, fprintf format for double values,
%                       default:'6.3f'
%       'delimiter'     string, column delimiter for output file,
%                       default: ';'
%
% Outputs:
%   Writes output to 'savefile'. Creates "dataexport.csv" to current
%   working directory, if savefile is missing.
%   data    [k,l] cell array, Outputfile data in cell array
%   labels  [1,l] cell array, Outputfile header in cell array
%
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
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.strformat = '''%s''';
Arg.doubleformat = '%e'; %'%6.3f'
Arg.intformat = '%3.0f';

Arg.factorsVariable = 'FACTORS';

Arg.delimiter = ';';
Arg.allowNaN = 'no';
Arg.outputFormat = 'wide';%{'wide','long'}

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Function argument checking
% Non-existent arguments initialized with empty values
if ~exist('savefile', 'var')
    savefile = fullfile(pwd(), 'dataexport.csv');
end

if ~exist('data_variable_names')
    data_variable_names = [];
end

%% Create savepath
[pathstr, name, saveExt] = fileparts(savefile);
[status,message,messageid] = mkdir(pathstr);

%% Read data from file and create a data matrix
data = {};
labels = {};
dbRowId = 1;
for i=1:numel(sourcefile_arr)
    [pathstr, filename, ext] = fileparts(sourcefile_arr{i});
    msg = ['dataexport: Processing file ', [filename,ext], '...'];
    disp(msg);
    
    % Load data
    M = load(sourcefile_arr{i});
    
    
    % Convert data to array form
    if isempty(data_variable_names)
        disp('Exporting all variables.')
        [i_data_array, i_labels, n_factors] = data2array(M, [],...
                'outputFormat', Arg.outputFormat,...
                'factors_variable', Arg.factorsVariable);
    else
        resString = data_variable_names{1};
        for tmpi=2:numel(data_variable_names)
            resString = strcat(resString, ', ', data_variable_names{tmpi});
        end
        disp(['Exporting only variables: ' resString])
        [i_data_array, i_labels, n_factors] = data2array(M, data_variable_names,...
            'factors_variable', Arg.factorsVariable,...
            'outputFormat', Arg.outputFormat);
    end

    %{
    %% Choose LONG or WIDE data format
    if strcmpi(Arg.outputFormat,'long')
        disp('Using LONG format.')
        % Reformat i_data_array, so that each value is on its own row
        % format: value, parameterName, factors
        
        %TODO: This does not work as expected. Several columns from
        %FACTORS are treated as "variables" and so are "channels", if data
        %has sublevels. Need to be fixed.

        % Split data into numerical data and factors
        pureData       = i_data_array(:,1:end-n_factors);
        pureDataLabels = i_labels(:,1:end-n_factors);
        pureFactors        = i_data_array(:,end-n_factors+1:end);
        pureFactorLabels   = i_labels(:,end-n_factors+1:end);

        [pDrows, pDcols] = size(pureData);

        values        = reshape(pureData, numel(pureData), 1);
        parameterName = reshape(repmat(pureDataLabels,pDrows,1), numel(pureData), 1);
        factors       = repmat(pureFactors,pDcols,1);

        longData = [values parameterName factors];
        longLabels = ['value', 'variable', pureFactorLabels];

        i_data_array = longData;
        i_labels = longLabels;
    else
        disp('Using WIDE format.')
    end
    %}
    
    
    %% Create format array
    if i == 1
        labels = i_labels;
        
        [datarows datacols] = size(i_data_array);
        
        % Create 'format_array'
        strmatch = cellfun(@isstr, i_data_array(1,:));
        doublematch = cellfun(@isfloat, i_data_array(1,:));
        intmatch = cellfun(@isinteger, i_data_array(1,:));
        
        format_array = cell(1, datacols);
        format_array(strmatch) = repmat({Arg.strformat}, 1, sum(strmatch));
        format_array(doublematch) = repmat({Arg.doubleformat}, 1, sum(doublematch));
        format_array(intmatch) = repmat({Arg.intformat}, 1, sum(intmatch));
    end
    
    
    %% Write data to file
    
    switch saveExt
        
        case '.csv'
            if i == 1
                % Write header and data
                cell2txtfile(savefile, labels, i_data_array, format_array,...
                    'delimiter', Arg.delimiter,...
                    'writemode', 'wt',...
                    'allownans', Arg.allowNaN);
            else
                % Append
                cell2txtfile(savefile, {}, i_data_array, format_array,...
                    'delimiter', Arg.delimiter,...
                    'writemode', 'at',...
                    'allownans', Arg.allowNaN);
            end
    
        case '.sqlite'
            
            if i == 1
                dbid = mksqlite('open', savefile);
                
                Out = mksqlite('show tables');
                if ismember('restab', {Out.tablename})
                    Out = mksqlite(dbid, 'drop table restab');
                end

                query = 'create table restab (id INTEGER PRIMARY KEY AUTOINCREMENT, channel TEXT, variable TEXT, value REAL, timestamp TEXT, duration REAL, latency REAL, rule TEXT, subject TEXT, casename TEXT, subjectnr TEXT, part TEXT, session TEXT, measurement TEXT, age REAL, sex TEXT)';
                msg = mksqlite(dbid, query);
            end

            disp('Writing rows to database...');
            for n=1:size(i_data_array,1)
                valueStr = createSQLDataString(dbRowId, i_data_array(n,:), format_array);
                query = ['insert INTO restab VALUES',valueStr];
                msg=mksqlite(dbid, query);   
                dbRowId = dbRowId + 1;
            end
            disp('... done.');
      
        otherwise
            error('dataexport_append:unsupportedOutputFileType','The output file format is not supported.');
            
    end
    
    clear('i_', 'M');
end
% [EOF]