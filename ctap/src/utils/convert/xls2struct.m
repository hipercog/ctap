function Xls = xls2struct(filename, sheet, varargin)
%XLS2STRUCT - Read MS Excel data into struct
%
% Description:
%   The data from the sheet 'sheet' is read, numerical and text data
%   separately. 
%   Depending on the varargin 'DataSpreadsHorizontal' either the first row or the 
%   first column is considered to contain data labels. By default,
%   the first row is interpreted as labels, and rows 2:end contain the
%   data. 
%   The data labels are used to create the fields for struct 'Xls'. 
%   Text columns (rows) should have something on each row (column), 
%   otherwise they can be mistaken as numeric columns (rows).
%   Use e.g. "-" to mark empty text cells.
%
% Syntax:
%   Xls = xls2struct(filename, sheet, varargin);
%
% Inputs:
%   filename    string, fullpath to the .xls file
%   sheet       string, name of the sheet to be read
%   varargin    keyword-value pairs, Available combinations are:
%               Keyword         Values
%               'OutputType'    string, Output struct format
%                               values: {'plane'(default), 'element'}
%               'DataSpreadsHorizontal' logical, Defines in which direction 
%                                       data spreads, By default assumes
%                                       first row to contain labels and
%                                       rows 2:N data values.
%                                       values: {false(default), true}
%
% Outputs:
%   Xls         struct, fieldnames defined by the first row or columns from
%               sheet 'sheet' (see varargin 'DataSpreadsHorizontal').
%               Data organized by default according to "plane organization"
%               but also "element-by-element" organization possible. In
%               plane organization string entries are wrapped into cells.
%               In element organization string entries appear as pure
%               strings.
%
% References:
%
% Example: D = xls2struct('C:\temp\test.xls', 'data', 'OutputType', 'element');
%
% Notes:
%   It is possible that a single column that has been formatted as numeric
%   contains cells whose "real format" (as returned by xlsread.m) is text.
%   Such columns cause all kinds of hard-to-understand errors. Fix the
%   problem by replacing erroneous value with Excel's find&replace.
%
%   xlsread.m works flawlessly only on Windows. Running xlsread in 'basic'
%   mode caused unsolvable errors both in Windows and in Linux/Unix. Hence
%   cross-platform spreadsheet support can only be achieved using OpenOffice.
%   See loadods.m (from Matlab central) and ods2struct.m for details.
%
% See also: xlsread, structconv, loadods, ods2struct
%
% Version history
% Data direction option adde, 5/2009, jkor, TTL
% Output type selection added, 10.5.2007, jkor, TTL
% First created, 10.11.2006, Jussi Korpela, TTL
%
% Copyright 2006-2009 Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.OutputType = 'plane'; %{'plane', 'element'}
Arg.DataSpreadsHorizontal = false; %{false, true}

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Read xls data
[numData, strData, rawData] = xlsread(filename, sheet);
% 'numData' is difficult to use, since it sometimes contains non-numeric
% columns as columns of NaN's but sometimes doesn't. [later note: was it
% perhaps trailing string colums that were left out?]
% A more robust solution is to use 'rawData', althoug it has some weird
% properties as well (see below).

% numData   [n_datarows, n_datacols] double,
%           contains only numeric values or NaNs (i.e. no header)
% strData   [n_datarows+1, n_datacols] cell of strings,
%           contains only string values or empty cells, INCLUDES header
% rawData   [n, n_datacols] cell of mixed values,
%           contains both string and numeric values (also NaNs and empty cells)
%           INCLUDES header
%           MIGHT ALSO CONTAIN ROWS THAT DO NOT HAVE ANY DATA. It seems to be
%           an Excel feature that all cells somehow modified appear as data
%           in this output cell array. E.g. running "clear all" causes the
%           affected cells to be included in rawData...

%% Cut out empty rows from 'rawData'
n_datarows = max(size(numData,1), size(strData, 1)-1);
rawData = rawData(1:n_datarows+1, :);
%keyboard

%% Assign xls data columns into struct fields

% Note: If one of the rows below throws an error because rawData{1,i}
% does not evaluate to a valid fieldname, the reason might be "empty"
% cells in xls table. Select all empty columns/rows in the xls worksheet
% affected and delete them using context menu options. This usually
% fixes the problem. (In Excel a fresh worsheet cell with no data seems
% to be different than a cell which has had data but currently has no 
% data. Hence the deletion.)

if Arg.DataSpreadsHorizontal
    % data is in columns, use first column as field labels
    for i = 1:size(rawData,1)
        if isnumeric(rawData{i,2})
            %numeric row    
            Xls.(rawData{i,1}) = [rawData{i,2:end}]';
        else
            %text row
            Xls.(rawData{i,1}) = rawData(i,2:end)';
        end
    end   
     
else
    % data is in rows, use first row as field labels
    for i = 1:size(rawData,2)

        if isnumeric(rawData{2,i})
            %numeric column    
            Xls.(rawData{1,i}) = [rawData{2:end,i}]';
        else
            %text column
            Xls.(rawData{1,i}) = rawData(2:end,i);
        end
    end
end

% Convert to element-by-element organization
if strcmp(Arg.OutputType, 'element')
    Xls = structconv(Xls);
end