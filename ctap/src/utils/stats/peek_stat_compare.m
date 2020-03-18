function result = peek_stat_compare(pkA, pkB, varargin)

    p = inputParser;
    p.addRequired('pkA', @istable);
    p.addRequired('pkB', @istable);
    p.addParameter('sumStat', @mean, @(f) isa(f, 'function_handle'));
    p.parse(pkA, pkB, varargin{:});
    Arg = p.Results;
    
    Anames = pkA.Properties.VariableNames;
    Bnames = pkB.Properties.VariableNames;
    
    % check tables are comparable
    if ~isempty(setdiff(Anames, Bnames))
        error('peek_stat_compare:mismatched_input'...
            , 'Peek stat table inputs have different columns')
    end
    
    % Get summary statistic difference of each field
    for fidx = 1:numel(Anames)
        result.(Anames{fidx}) =...
            Arg.sumStat(pkA.(Anames{fidx})) - Arg.sumStat(pkB.(Bnames{fidx}));
    end
end