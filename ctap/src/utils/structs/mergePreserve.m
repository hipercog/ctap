function dst = mergePreserve(dst, src)
% dst = mergePreserve(dst, src)
% Recursively merge src into dst. Preserve existing non-struct values in dst.
% - If both are structs (including struct arrays) merge elementwise.
% - If both are cell arrays, merge elementwise; cell elements that are structs
%   are merged recursively. Missing dst elements are created from src.
% - If dst is empty or missing a field, copy from src.

if nargin < 2, error('Requires dst and src'); end

% If dst empty, return a copy of src
if isempty(dst)
    dst = src;
    return
end

% Handle cell arrays
if iscell(src)
    if ~iscell(dst)
        % prefer preserving dst type; if incompatible, copy src
        dst = src;
        return
    end
    n = max(numel(dst), numel(src));
    dst = reshape(dst, 1, numel(dst)); %#ok<NASGU>
    src = reshape(src, 1, numel(src));
    dstNew = cell(1, n);
    for i = 1:n
        if i <= numel(dst), di = dst{i}; else di = []; end
        if i <= numel(src), si = src{i}; else si = []; end
        if isempty(di)
            dstNew{i} = si;
        elseif isempty(si)
            dstNew{i} = di;
        elseif isstruct(si) && isstruct(di)
            dstNew{i} = mergePreserve(di, si);
        else
            % preserve existing dst cell element
            dstNew{i} = di;
        end
    end
    dst = reshape(dstNew, size(dst,1), n/size(dst,1));
    return
end

% Handle struct arrays
if isstruct(src)
    if ~isstruct(dst)
        dst = src;
        return
    end
    % operate elementwise over linear indices up to max length
    n = max(numel(dst), numel(src));
    dstLin = reshape(dst, 1, numel(dst));
    srcLin = reshape(src, 1, numel(src));
    dstNew = repmat(dstLin(1), 1, n); % placeholder allocation
    % Create an empty struct template if needed
    if isempty(dstLin)
        dstLin = repmat(struct(), 1, 0);
    end
    for i = 1:n
        if i <= numel(dstLin), di = dstLin{i}; else di = []; end
        if i <= numel(srcLin), si = srcLin{i}; else si = []; end
        if isempty(di)
            dstNew(i) = si;
        elseif isempty(si)
            dstNew(i) = di;
        else
            % merge fields
            dstNew(i) = mergeStructElements(di, si);
        end
    end
    dst = reshape(dstNew, size(dst,1), n/size(dst,1));
    return
end

% For non-struct, non-cell types: preserve dst (do nothing)
end

function out = mergeStructElements(out, src)
% Merge fields of scalar struct src into scalar struct out, preserving out values.
if isempty(out)
    out = src;
    return
end
fs = fieldnames(src);
for k = 1:numel(fs)
    f = fs{k};
    sval = src.(f);
    if isfield(out, f)
        dval = out.(f);
        if isstruct(sval) && isstruct(dval)
            out.(f) = mergePreserve(dval, sval);
        elseif iscell(sval) && iscell(dval)
            out.(f) = mergePreserve(dval, sval);
        else
            % preserve existing out.(f) — do nothing
        end
    else
        out.(f) = sval;
    end
end
end
