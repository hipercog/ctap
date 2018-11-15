function [strucout, in_sort] = subdir_parse(strucin, prestr, pststr, fname)
% SUBDIR_PARSE get the names of a subdir return struc edited down to
% bare essentials

    tmp = fieldnames(strucin);
    tmp = struct2cell(rmfield(strucin, tmp(2:end)));
    
    prestr = cellfun(@(x) x(1:strfind(x, prestr) + length(prestr)), tmp, 'Un', 0);
    tmp = cellfun(@(x, y) strrep(x, y, ''), tmp, prestr, 'Un', 0);
    
    pststr = cellfun(@(x) x(strfind(x, pststr):end), tmp, 'Un', 0);
    tmp = cellfun(@(x, y) strrep(x, y, ''), tmp, pststr, 'Un', 0);
    
    tmp = unique(tmp);
    
    [tmp, ix] = sort(tmp);
    in_sort = strucin(ix);
    strucout = cell2struct(tmp, fname, 1);
    
end