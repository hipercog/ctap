function out = structarr2mat(mats, idx)
% STRUCTARR2MAT PULL OUT A MATRIX FROM A STRUCT ARRARY AT THE GIVEN INDEX, E.G.
%   x = 3x1 cell array
%       {1x2 cell}
%       {1x2 cell}
%       {1x2 cell}
%   x{1}{1} = [2x2]
%   y = structarr2mat(x, 2)
%   y = [2x2x3]

    mats_at_idx = cellfun(@(x) x{idx}, mats, 'UniformOutput', false);
    nd = ndims(mats_at_idx{1});
    try
        out = cat(nd + 1, mats_at_idx{:});
    catch
        mats_at_idx = reshape(mats_at_idx, 1, []);
        testi = cellfun(@size, mats_at_idx, 'Uni', 0);
        nd = find(any(diff(cat(1, testi{:}))));
        out = cat(nd, mats_at_idx{:});
    end
end