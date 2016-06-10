function [ca, labels] = struct_to_cell(S)
%STRUCT_TO_CELL - Convert a struct into a cell array
%
% Description:
%   Converts struct into a cell array. Each field in struct becomes a
%   column in the cell array. See Matlab hep "Organizing 
%   Data in Structure Arrays" for details about organizind data into
%   structs.
%
%   Requirements/assumptions for plane organized structs:
%   *   Fields should be of size [n,1]
%   *   Char arrays are not allowed! Single string values are allowed in
%       the special case of n == 1 (data size [1,1]).
%
%   Conversion priciples:
%   *   Fields that contain a n-by-1 cell array get directly transferred into
%       the new cell array 
%   *   Fiels that contain a n-by-1 numeric array are transformed into 
%       n-by-1 cell arrays
%   *   Element organized structure field contents is transferred directly
%       into cell array cell content
%
%   Works properly with structures of both organizations. Plane organized
%   structs are converted into element organized ones before cell array
%   conversion.
%
% Syntax:
%   [ca, labels] = struct_to_cell(S);
%
% Inputs:
%   S   struct, The structure to convert. The struct is assumed to have m 
%       fields with [1,n] data values in each field. Two or three dimensional 
%       data fields in structs are not yet supported. Plane organized 
%       structs are converted into element organization using structconv.m
%       before cell array conversion.  
%
% Outputs:
%   ca      n-by-m cell array, Data from the fields of 'S' in columns m.
%   labels  1-by-m cell array of strings, Fieldnames from 'S', acts as
%           column header for 'ca'.
%
% Syntax examples:
%   S.f1 = {'a','b','c'}
%   S.f2 = [1 2 3]
%   [sca, slabels] = struct_to_cell(S)
%
%   Converting EEGLAB event table to cell array and back:
%   [event_ca,labels] = struct_to_cell(EEG.event);
%   EEG.event = cell2struct(event_ca, labels, 2)';
%
% Notes:
%   Supports only structures of data size [1,n]. If your sturcture has data
%   size [n,1], just transpose the result.
%   EEGLAB function eeg_eventformat() does about the same.
%
% See also: eeg_eventformat.m, cell2struct.m, struct2cell.m, structconv.m
%
% Version history
% First version (20.3.2007, Jussi Korpela, TTL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize variables
labels = fieldnames(S)';


%% Test input struct data lengths and conver to element organization
if sum(size(S) == [1 1]) == 2
    % Struct is plane organized
    
    %% Wrap single strings to cell
   for i = 1:length(labels) 
        if isstr(S.(labels{i}))
            S.(labels{i}) = {S.(labels{i})};
            % Char arrays will be wrapped as well -> they cause error in
            % the next block...
        end
    end
    
    %% Check data length
    dlen = length(S.(labels{1}));  
    for i = 2:length(labels) 
        if length(S.(labels{i})) ~= dlen
            msg = 'Struct fields have different number of elemens. Unable to convert into cell array.';
            error('struct_to_cell:dataLengthError',msg);
        end
    end
    
    %% Convert to element-by-element organized
    S = structconv(S);
    
else
    % Struct is element-by-element organized
    dlen = size(S,2);
end


%% Convert struct into cell array
ca = shiftdim(struct2cell(S),2);

% Correct dimension
if dlen == 1
    ca = ca'; 
end

end