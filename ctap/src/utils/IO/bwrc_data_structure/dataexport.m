function [data  labels] = dataexport(sourcefile_arr, savefile, data_variable_names, varargin)
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
% 4.11.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.strformat = '''%s''';
Arg.doubleformat = '%e'; %'%6.3f'
Arg.intformat = '%3.0f';
Arg.delimiter = ';';
Arg.nastr = 'na';

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


%% Read data from file and create a data matrix
data = {};
labels = {};
for i=1:numel(sourcefile_arr)
    [pathstr, filename, ext, version] = fileparts(sourcefile_arr{i});
    msg = ['dataexport: Processing case ', [filename,ext], '...'];
    disp(msg);
   
    % Load data
    M = load(sourcefile_arr{i});

    % Convert data to array form
    if isempty(data_variable_names)
        [i_data_array, i_labels] = data2array(M);
    else
        [i_data_array, i_labels] = data2array(M, data_variable_names);
    end
    
    % Create export matrix and labels
    data = vertcat(data, i_data_array);
    
    if i == 1
       labels = i_labels; 
    end
    
    clear('i_', 'M');
end


%% Write data to text-file
if ~isempty(savefile)
    [datarows datacols]=size(data);

    % Create 'format_array'
    strmatch = cellfun(@isstr, data(1,:));
    doublematch = cellfun(@isfloat, data(1,:));
    intmatch = cellfun(@isinteger, data(1,:));

    format_array = cell(1, datacols);
    format_array(strmatch) = repmat({Arg.strformat}, 1, sum(strmatch)); 
    format_array(doublematch) = repmat({Arg.doubleformat}, 1, sum(doublematch)); 
    format_array(intmatch) = repmat({Arg.intformat}, 1, sum(intmatch));


    if ~isempty(Arg.nastr)
        cell2txtfile(savefile, labels, data, format_array,...
                 'delimiter', Arg.delimiter,...
                 'allownans', 'yes');
    else
        cell2txtfile(savefile, labels, data, format_array,...
                 'delimiter', Arg.delimiter);
    end
end

% [EOF]