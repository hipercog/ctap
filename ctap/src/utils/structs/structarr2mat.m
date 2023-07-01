function out = structarr2mat(mats, idx)
% STRUCTARR2MAT PULL OUT A MATRIX FROM A STRUCT ARRARY AT THE GIVEN INDEX, E.G.
%   x = 3x1 cell array
%       {1x2 cell}
%       {1x2 cell}
%       {1x2 cell}
%   x{1}{1} = [2x2]
%   y = structarr2mat(x, 2)
%   y = [2x2x3]

    cel2mat = cellfun(@(x) x{idx}, mats, 'UniformOutput', false);
    nd = ndims(cel2mat{1});
    out = cat(nd + 1, cel2mat{:});
end