function T = structconv(S)
%STRUCTCONV - Convert between plane and element-by-element organizations
%
% Description:
%   Converts between plane and element-by-element organizations of a Matlab
%   struct. If the input is of plane organization, it is converted to
%   element-by-element organized struct and vice versa.
%
%   Requirements/assumptions for plane organized sturcts:
%   * Fields contain only cell or numeric arrays, char arrays are not
%     allowed!
%   * All data in one field is of the same type
%   * Planes are of equal size i.e. size(S.(fieldnames(i)))=const for all i
%   * Special case allowed: for example struct
%            S.field1 = 2;
%            S.field2 = 'text';
%     will be passed through structconv.m unchanged (see lin 69-> for details).
%
%
% Syntax:
%   T = structconv(S)
%
% Inputs:
%   S   struct, Struct of either organization
%
% Outputs:
%   T   struct, Struct of opposite organization as 'S'
%
%
% Notes:
%   Supports three dimensions but tested with only 2 dimensional structs.
%
% References:
%   Matlab help: "Organizing Data in Structure Arrays"
%
% See also: struct_to_cell.m
%
% Version History:
% Empty entry handling added to subfunction element2plane and cell element
%   unwrapping to subfunction plane2element (21.8.2007, jkor, TTL)
% Plane to element conversion improved (16.5.2007, jkor, TTL)
% First version (9.5.2007, Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check input type and select conversion method
if sum(size(S) == [1 1]) == 2
    % Struct is of plane organization
    
    %% Check data size
    fields = fieldnames(S);
    % Data sizes for each field
    dsizes = NaN(length(fields),3);
    for idx = 1:length(fields)
        dsizes(idx,1) = size(S.(fields{idx}),1);
        dsizes(idx,2) = size(S.(fields{idx}),2);
        dsizes(idx,3) = size(S.(fields{idx}),3);
    end
    
    % Unique data sizes in each field
    usizes1 = unique(dsizes(:,1));
    usizes2 = unique(dsizes(:,2));
    usizes3 = unique(dsizes(:,3));
    
    % Check for deviations
    if length(usizes1)>1 || length(usizes2)>1 || length(usizes3)>1
        
        if (dsizes(1,1)==1 && dsizes(1,3)==1) &&...
           (length(usizes1)==1 && length(usizes3)==1) &&...
            (length(usizes2)>1)
            % Special case: dimensions 1 and 3 have length 1 for all fields 
            % but at least one field differs from the others in dimension 2
            % length. Could be e.g. that S is 
            % S.field1 = 2;
            % S.field2 = 'text';
            % This is stuct that cannot be classified as element or plane,
            % return it as such.
            T = S;
            return;
        else
            msg = 'Struct planes are of different sizes. Cannot convert.';
            error('structconv:planeSizeMismatch',msg);
        end
    end
    
    %% Convert
    T = plane2element(S);
    
else
    % Struct is of element-by-element organization
    
    %% Convert
    T = element2plane(S);
end


%% Subfunctions

    function R = plane2element(S)
    % Convert plane organization into element-by-element organization
        
        fields = fieldnames(S);
        [imax, jmax, kmax] = size(S.(fields{1}));
        %Assumes that S.(fields{1}) is cell or numeric array, NOT char array
        
        
        for n = 1:length(fields) 
            for i = 1:imax
                for j = 1:jmax
                    for k = 1:kmax
                        if isempty(S.(fields{n}))
                            % Empty value cannot be referred to with index
                            % (i,j,k) -> index out of bounds error
                            R(i,j,k).(fields{n}) = [];
    
                        else
                            if iscell(S.(fields{n})(i,j,k))
                                R(i,j,k).(fields{n}) = S.(fields{n}){i,j,k};      
                            else
                                R(i,j,k).(fields{n}) = S.(fields{n})(i,j,k);
                            end
                        end
                    end
                end
            end 
        end
       
    end


    function R = element2plane(S)
    % Convert element-by-element organization into plane organization
        
        fields = fieldnames(S);
        [imax, jmax, kmax] = size(S);
        
        for n = 1:length(fields) 
            for i = 1:imax
                for j = 1:jmax
                    for k = 1:kmax
                        
                        if isempty( S(i,j,k).(fields{n}) )
                            if isnumeric( S(i,j,k).(fields{n}) )
                                R.(fields{n})(i,j,k) = NaN;
                            elseif ischar( S(i,j,k).(fields{n}) )
                                R.(fields{n})(i,j,k) = {''};
                            else
                                error('structconv:invalidSourceElement',...
                                    'The input could not be converted into element-by-element organization.');
                            end
          
                            
                        else
                            if isnumeric( S(i,j,k).(fields{n}) )
                                R.(fields{n})(i,j,k) = S(i,j,k).(fields{n});
                            elseif ischar( S(i,j,k).(fields{n}) )
                                R.(fields{n})(i,j,k) = {S(i,j,k).(fields{n})};
                            elseif iscell( S(i,j,k).(fields{n}) )
                                R.(fields{n})(i,j,k) = {S(i,j,k).(fields{n})};
                            else
                                error('structconv:invalidSourceElement',...
                                    'The input could not be converted into element-by-element organization.');
                            end
                        end
                       
                    end %of k
                end %of j
            end %of i 
        end %of n
       
    end %of element2plane()


end