function [strucut, in_sort] = subdir_parse(strucin, prestr, pststr, subname)
% SUBDIR_PARSE get the names of a subdir return struc edited down to
% bare essentials

%Get just the first field of the subdir struct: fullpath-names
subx = fieldnames(strucin);
subx = struct2cell(rmfield(strucin, subx(2:end)))';

%Parse to paths & filenames
[paths, files, exts] = cellfun(@fileparts, subx, 'Un', 0);
files = cellfun(@(x, y) [x y], files, exts, 'Un', 0);

%Extract the interesting part of the fullpaths: SUB-STRING X
prestr = cellfun(@(x) x(1:strfind(x, prestr) + length(prestr)), subx, 'Un', 0);
subx = cellfun(@(x, y) strrep(x, y, ''), subx, prestr, 'Un', 0);

pststr = cellfun(@(x) x(strfind(x, pststr):end), subx, 'Un', 0);
subx = cellfun(@(x, y) strrep(x, y, ''), subx, pststr, 'Un', 0);

%Sort and squeeze the paths and parts
[subx, ix] = sort(subx);
files = files(ix);
paths = paths(ix);
[usubx, ~, ius] = unique(subx, 'stable');
% [ufiles, iof, iuf] = unique(files);
upaths = unique(paths, 'stable');

%Return output
in_sort = strucin(ix);
strucut = cell2struct(usubx, subname, find(size(usubx) == 1));
[strucut.path] = deal(upaths{:});

for i = 1:numel(strucut)
    strucut(i).file = files(ius == i);
end
    
end