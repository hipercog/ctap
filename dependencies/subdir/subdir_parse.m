function [strucout, in_sort] = subdir_parse(strucin, begstr, endstr, fname)
% SUBDIR_PARSE get the names of a subdir return struc edited down to
% bare essentials

    tmp = fieldnames(strucin);
    tmp = struct2cell(rmfield(strucin, tmp(2:end)));
    tmp = cellfun(@(x) strrep(x, begstr, ''), tmp, 'Un', 0);
    tmp = cellfun(@(y) strrep(y, endstr, ''), tmp, 'Un', 0);
    [tmp, ix] = sort(tmp);
    in_sort = strucin(ix);
    strucout = cell2struct(tmp, fname, 1);
    
end