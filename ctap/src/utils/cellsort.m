function Y = cellsort(X, sortcols)
%CELLSORT - Sort cell array based on numeric values within the array
%
% Description:
%   Sorts cell arrays that are a mixture of numeric and other data. 
%   The sorting is done based on numeric columns only. If sorting based on
%   string values is needed, use Matlab built-in sortrows.m.
%
% Assumptions:
%   At least one column of 'X' should be a cell array of numeric values,
%   where each cell contains only one numeric value.
%   The content of other columns is not restricted. Columns that contain 
%   a mixture of numeric and other values are treated like non-numeric 
%   columns. 
%
%   Runtime constants not defined by function arguments: no
%
% Syntax:
%   Y = cellsort(X, sortcols);
%
% Inputs:
%   X           [n,m] cell, Cell array that contains at least one numeric
%               column (see assumptions above).
%   sortcols    [1,k] int, Indices of columns to use in sorting.
%               Uses sign to specify sorting order: negative index for
%               descending, positive for ascending
%
% Outputs:
%   Y           [n,m] cell, Rowsorted version of 'X'. 
%
% References:
%
% Example: Y = cellsort(X, [1 -3]);
%
% Notes:
%
% See also: sortrows.m, sort.m
%
% Version History:
% 8.10.2007 Numeric column detection improved (Jussi Korpela, TTL)
% 21.8.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Initialize variables
[n_rows, n_cols] = size(X);
N1 = 1:1:n_rows;
N2 = 1:1:n_cols;


%% Separate string and numeric columns
% Numeric
numcols = cellfun(@isnumeric, X); %returns a logical array of size(X)
numcols = (sum(numcols, 1) == size(numcols,1)); %logical 1 for columns that contain only numeric values
numcols_ind = N2(numcols);
n_numcols = sum(numcols);
x_num = cell2mat(X(:, numcols));
x_num(:,end+1) = N1'; %temporary row number column  

% String
%Old syntax, not in use. Maybe in the future?
%strcols = cellfun(@isstr, X);
%strcols = (sum(strcols, 1) >= 1); %logical 1 for columns that contain at least one string
%x_str = X(:, strcols)

% Other columns
x_other = X(:,~numcols);

%% Sort numeric columns
% Only columns specified in 'sortcols' are sorted
for i = 1:length(sortcols)
    ind = find( numcols_ind == abs(sortcols(i)) );
    
    if sortcols(i) < 0
       ind = -ind; % set sorting order to descending  
    end
    
    if ~isempty(ind) && (length(ind) == 1)
        x_num = sortrows(x_num, ind);
    else
        msg = ['Column ', num2str(abs(sortcols(i))), ' could not be found. Possibly a non-numeric column. No sorting done based on this column.'];
        warning('cellsort:inputError',msg);
    end
end


%% Rejoin numeric and str data
Y = cell(n_rows, n_cols);

% Assign numeric data
Y(:,numcols) = mat2cell(x_num(:,1:n_numcols), ones(n_rows,1), ones(n_numcols,1));

% Assign str data to rows
num_row_order = x_num(:,end);
for i = 1:n_rows
   Y(i,~numcols) = x_other(num_row_order(i,end),:); 
end