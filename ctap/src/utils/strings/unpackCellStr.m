% obtain a non-nested cell array of strings (char arrays)
function strarr = unpackCellStr(input)
    test = cellfun(@iscell, input);
    strarr = [];
    if any(test)
        for i = 1:numel(test)
            if test(i), strarr = [strarr unpackCellStr(input{i}(:)')];
            else        strarr = [strarr input{i}];
            end
        end
    else
        strarr = input;
    end
end