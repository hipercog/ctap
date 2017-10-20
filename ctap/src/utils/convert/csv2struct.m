function S = csv2struct(sourcefile, varargin)
%CSV2STRUCT - Read CSV/TXT file contents into a struct
%
% Description:
%   Reads delimited TXT data from file and returns it in struct.
%   Assumes ";" as the default delimiter.
%   The first row is interpreted as data labels and rows 2:end assumend to 
%   contain the actual data. 
%   The data labels are used to create the fields for output struct 'S'. 
%
% Algorithm:
%
% Syntax:
%   S = csv2struct(sourcefile, varargin);
%
% Inputs:
%   sourcefile  string, fullpath to the CSV/TXT file
%   varargin    keyword-value pairs, Available combinations are:
%               Keyword         Values
%               'OutputType'    string, Output struct format
%                               values: {'element' (default), 'plane'}
%               'Delimiter'     string, Delimiter used in data                              spreads,
%                               values: {';' (default), <any string>}
%
% Outputs:
%   S           struct, fieldnames defined by the first row of data.
%               Data organized by default according to "element-by-element
%               organization" but also "plane organization" possible. In
%               plane organization string entries are wrapped into cells.
%               In element organization string entries appear as pure
%               strings.
%
% Assumptions:
%
% References:
%
% Example:  S = ods2struct('C:\temp\test.csv', 'OutputType', 'plane',...
%                           'Delimiter', ',');
%
% Notes:
%
% See also: readtext, structconv, ods2struct, xls2struct
%
% Version History:
% 5/2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.OutputType = 'element'; %{'plane', 'element'}
Arg.Delimiter = ';';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Read in data
% Uses readtext.m from Matlab Central
[data, info] = readtext(sourcefile,Arg.Delimiter);

%% Assign data to struct
for k=1:size(data,2)
    if ~isempty(data{1,k})
        S.(data{1,k}) = data(2:end, k); 
    end  
end

%% Convert to element-wise organization if needed
if strcmp(Arg.OutputType, 'element')
    S = structconv(S);
end

end