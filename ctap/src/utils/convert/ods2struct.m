function S = ods2struct(sourcefile, sheet, varargin)
%ODS2STRUCT - Read OpenOffice Calc (ODS) file contents into a struct
%
% Description:
%   The data from the sheet 'sheet' is read.
%   Depending on the varargin 'DataSpreadsHorizontal' either the first row or the 
%   first column is considered to contain data labels. By default,
%   the first row is interpreted as labels, and rows 2:end contain the
%   data. 
%   The data labels are used to create the fields for struct 'Xls'. 
%   Text columns (rows) should have something on each row (column), 
%   otherwise they can be mistaken as numeric columns (rows).
%   Use e.g. "-" to mark empty text cells.
%
% Algorithm:
%
% Syntax:
%   S = ods2struct(sourcefile, sheet, varargin);
%
% Inputs:
%   sourcefile  string, fullpath to the ODS file
%   sheet       string, name of the sheet to be read
%   varargin    keyword-value pairs, Available combinations are:
%               Keyword         Values
%               'OutputType'    string, Output struct format
%                               values: {'element' (default), 'plane'}
%               'DataSpreadsHorizontal' logical, Defines in which direction data
%                               spreads,
%                               values: {false (default), true}
%
% Outputs:
%   S           struct, fieldnames defined by the first row or columns from
%               sheet 'sheet' (see varargin 'DataSpreadsHorizontal').
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
% Example: S = ods2struct('C:\temp\test.ods', 'data', 'OutputType', 'plane');
%
% Notes:
%   Hyperlinks are not correctly loaded using loadods.m. Remove hyperlinks
%   by applying default formatting to hyperlinked cells.
%
% See also: loadods, structconv, xls2struct, xlsread
%
% Version History:
% 5/2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.OutputType = 'element'; %{'plane', 'element'}
Arg.DataSpreadsHorizontal = false; %{false, true}

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Read in data
% Uses readtext.m from Matlab Central
opt.sheet_name = sheet;
data = loadods(sourcefile, opt);


%% Drop out extra columns
nanmatch=cellfun(@isnan, data, 'UniformOutput', false);
nanmatch = cellfun(@sum, nanmatch);
nan_col_match = sum(nanmatch,1) == size(nanmatch,1);
data = data(:,~nan_col_match);
 
%% Drop extra rows
nanmatch=cellfun(@isnan, data, 'UniformOutput', false);
nanmatch = cellfun(@sum, nanmatch);
nan_row_match = sum(nanmatch,2) == size(nanmatch,2);
data = data(~nan_row_match,:);

if isempty(data)
   msg = ['Loading returned empty dataset. Check datasheet name, currently: ''',sheet,'''.']; 
   error('ods2struct:emptyDataset', msg);
end


%% Assign data to struct
if Arg.DataSpreadsHorizontal
    % data is in columns, use first column as field labels
    for k = 1:size(data,1)
        if ~isempty(data{k,1})
            S.(data{k,1}) = data(k, 2:end)'; 
        end
    end
     
else
    % data is in rows, use first row as field labels
    for k = 1:size(data,2)
        if ~isempty(data{1,k})
            S.(data{1,k}) = data(2:end, k); 
        end
    end
end


%% Convert to element-wise organization if needed
if strcmp(Arg.OutputType, 'element')
    S = structconv(S);
end

end %of ods2struct