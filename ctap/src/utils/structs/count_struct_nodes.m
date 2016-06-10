function num_nodes = count_struct_nodes(a_struct)
%COUNT_STRUCT_NODES count the number of elements in a struct that are not
%   themselves structs, i.e. are leaves
%
% Description:
%   
%
% Syntax:
%   num_nodes = count_struct_nodes(a_struct);
%
% Inputs:
%   a_struct    : struct, any structure
%
% Outputs:
%   num_nodes   : scalar, count of the number of fields which are leaves
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%   
%
% See also:  
%
% Copyright 2014- Benjamin Cowley, FIOH, benjamin.cowley@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    num_nodes = 0;
    if ~isstruct(a_struct)
        warning('Not a struct.'); %#ok<*WNTAG>
        num_nodes = 1;
        return;
    end
    fns = fieldnames(a_struct);
    for i = numel(a_struct)
        for j = 1:length(fns)
            if isstruct(a_struct(i).(fns{j}))
                num_nodes = num_nodes+...
                    count_struct_nodes(a_struct(i).(fns{j}));
            else
                num_nodes = num_nodes+1;
            end
        end
    end
end
