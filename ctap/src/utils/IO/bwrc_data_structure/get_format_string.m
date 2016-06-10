function [fmt, types] = get_format_string(x)

fmt = '';
types = cell(numel(x), 1);

for (i = 1:(numel(x)))
    if isnumeric(x{i})
        fmt = [fmt '%f', ', '];
        types{i} = 'REAL';
    elseif ischar(x{i})
        fmt = [fmt, '''%s''', ', '];
        types{i} = 'TEXT';
    end
end

fmt(end-1:end) = '';

end
