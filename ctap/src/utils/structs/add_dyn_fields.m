function B = add_dyn_fields(A, B, dynames, varargin)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('A', @isstruct)
p.addRequired('B', @isstruct)
p.addRequired('dynames', @iscell)

p.addParameter('as_array', true, @islogical)

p.parse(A, B, dynames, varargin{:})
Arg = p.Results;


%% add dyanmic event fields
if Arg.as_array
    for i = 1:numel(dynames)
        tmp = {A.(dynames{i})};
        [B.(dynames{i})] = deal(tmp{:});
    end
else
    for i = 1:numel(dynames)
        tmp = {A.(dynames{i})};
        if isnumeric(cell2mat(tmp(1)))
            nullx = cellfun(@isempty, tmp);
            tmp{nullx} = NaN;
            tmp = cell2mat(tmp);
        end
        B.(dynames{i}) = tmp;
    end
end

end