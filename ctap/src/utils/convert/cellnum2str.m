function strcell = cellnum2str(C)
%CELLNUM2STR - Convert numeric elements of a cell array into string
%
% Description:
%   Use this function to cell arrays of mixed data types into a cell array
%   of strings. Cells of 'C' that contain numeric arrays are converted to
%   string using num2str. Cells that contain string, cell or any other data 
%   type are left unchanged. 
%
%   Runtime constants not defined by function arguments: no
%
% Syntax:
%   strcell = cellnum2str(C)
%
% Inputs:
%   C           n-by-m cell, A cell array containing mixed data types
%                            (strings and numeric values)
%
% Outputs:
%   strcell     n-by-m cell, A cell array of only strings
%
% References:
%
% Example:
%
% See also: num2cell, cellstr, char, num2str 
%
% Version History:
% Code simplified using cellfun.m, 9.8.2007, jkor, TTL
% First version (21.5.2007, Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% New solution
% Initialize output
strcell = C;

% Find numeric values
numericSelection = cellfun(@isnumeric, C);

% Convert numeric values and replace
strcell(numericSelection) = cellfun(@num2str, C(numericSelection),...
                                    'UniformOutput',0);


%% Old solution                               
%{                                
% Initialize output
strcell = cell(size(C));

% Loop through 'C'

for i = 1:size(C,1)
    for j = 1:size(C,2)
        for k = 1:size(C,3)
            if isnumeric(C{i,j,k}) %numeric element found
                strcell(i,j,k) = {num2str(C{i,j,k})};
            else % other type of element found
                strcell(i,j,k) = C (i,j,k);
            end     
        end 
    end
end
%}