function Sout = statop_on_struct(Sin, statop, fieldtype)
%STATOP_ON_STRUCT performs the operation defined by function handle 'stat',
%   on fields in the struct 'Sin' which are of type 'fieldtype'
% 
% SYNTAX
%   Sout = statop_on_struct(Sin, statop, fieldtype);
% 
% INPUT
%   'Sin'       struct, array containing fields subject to 'statop'
%   'statop'    function, some operator on the type of data in 'fieldtype'
%   'fieldtype' function, a Matlab 'isxxx' function, where xxx is some
%                       datatype
% 

% Check the paramters
p = inputParser;
p.addRequired('Sin', @isstruct);
valfun = @(x) isa(x, 'function_handle');
p.addRequired('statop', valfun);
p.addRequired('fieldtype', valfun);
% additional parameters can be defined here
p.parse(Sin, statop, fieldtype);
Arg = p.Results;


    fn = fieldnames(Arg.Sin);
    if isempty(fn)
        return
    end
    Sout = Sin(1);
    
    for i = 1:numel(fn)
        if Arg.fieldtype(Arg.Sin(1).(fn{i}))
            Sout.(fn{i}) = Arg.statop([Arg.Sin(:).(fn{i})]);
        end
    end
end