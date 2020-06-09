function [fltnames, nameidx] = name_filter(rawnames, subj_filt, varargin)
%NAME_FILTER returns those elements from rawnames that match by:
%       names: being equal to (or uniquely containing) one given string, or
%       indices: logical vector indexing the files to keep, or
%       subject numbers: having a filename containing one of given numbers
%   CAN MIX NAMES AND SUBJECT NUMBERS IN ONE CELL ARRAY
% 
%   Can also do inverse filtering, same modes as above but flipped logic:
%       ~names: reject filenames containing these strings, if prepended with '~'
%       -1 * subject numbers: reject filenames containing negative signed numbers
% 
%   CANNOT MIX INVERSE MODES: will treat ALL as positive unless ALL are negative
% 
%   If keyword 'all' is used, all elements are returned
%   If filters are empty, no elements are returned
% 
% Input:
%   rawnames    struct, array with .name field; as return-value of dir()
%   subj_filt   cell, cell array of string names (or name parts) of files
%                  AND/OR row vector of file indices
%                  OR vector of numbers occurring in file names
% Varargin
%   subst       vector [1 2], start and end position of filenames to parse
%               Default [1:end]

%--------------------------------------------------------------------------
% Initialise inputs
p = inputParser;
p.KeepUnmatched = true; 

p.addRequired('rawnames', @isstruct)
p.addRequired('subj_filt'...
    , @(x) iscell(x) || isnumeric(x) || ischar(x) || islogical(x))

p.addParameter('subst', [ones(1, numel(rawnames)); strlength({rawnames.name})]...
    , @isnumeric)

p.parse(rawnames, subj_filt, varargin{:})
Arg = p.Results;


%% Return all or none
if strcmp('all', subj_filt)
    fltnames = rawnames;
    nameidx = true(numel(rawnames), 1);
    return
elseif isempty(subj_filt)
    fltnames = struct('name', {});
    nameidx = false(numel(rawnames), 1);
    return
elseif islogical(subj_filt)
    fltnames = rawnames(subj_filt);
    nameidx = find(subj_filt);
    return
end


%% Parse filters
if ~iscell(subj_filt)
    subj_filt = {subj_filt};
end

num_filt = [];
testchar = cellfun(@ischar, subj_filt);
str_filt = subj_filt(testchar);
if ~all(testchar)
    testcell = cellfun(@iscell, subj_filt);
    if any(testcell)
        if all(cellfun(@ischar, subj_filt{testcell}))%test for cell strings
            str_filt = [str_filt(:)' subj_filt{testcell}];
        end
    end
    testnum = cellfun(@isnumeric, subj_filt);
    if any(testnum)
        num_filt = [subj_filt{testnum}];
    end
end


%% Substring filenames if requested
if numel(Arg.subst) == 2
    if Arg.subst(2) <= Arg.subst(1) || Arg.subst(1) < 0 ||...
            Arg.subst(2) > min(strlength({rawnames.name}))
        error('name_filter:bad_param', 'Substring out of bounds')
    end
    Arg.subst = repmat(Arg.subst(:), 1, numel(rawnames));
end
for i = 1:numel(rawnames)
    rawnames(i).name = rawnames(i).name(Arg.subst(1, i) : Arg.subst(2, i));
end


%% Find indices of filtered files
stridx = false(1, length(rawnames));
numidx = false(1, length(rawnames));
invert_strs = false;
invert_nums = false;

if ~isempty(str_filt)
    if all(startsWith(str_filt, '~'))
        invert_strs = true;
    end
    str_filt = cellfun(@(x) [strrep(x(1), '~', '') x(2:end)], str_filt, 'Un', 0);
    stridx = sbf_string_match(rawnames, str_filt);
end

if ~isempty(num_filt)
    if all(num_filt < 0)
        invert_nums = true;
    end
    num_filt = abs(num_filt);
    % Filter by numeric part of given name
    numidx = sbf_num_match(rawnames, num_filt);
end


%% Return filtered files
if invert_strs
    stridx = ~stridx;
end
if invert_nums
    numidx = ~numidx;
end

fltnames = rawnames(stridx | numidx);
nameidx = find(stridx | numidx);

end

function idx = sbf_num_match(names, FILT)

    C = cell(numel(names), 1);
    %tokenise the names for numeric content
    for i = 1:numel(names)
        S = sprintf('%s ', names(i).name);
        S(isstrprop(S, 'alpha')) = ' ';
        S(isstrprop(S, 'punct')) = ' ';
        C{i} = sscanf(S, '%d')';
    end
    empty = cellfun(@isempty, C);
    M = cell2mat(C);
    M = M(:);
    if isvector(M)
        match = ismember(M, FILT);
        idx = false(1, size(C, 1));
        idx(~empty) = match;
    else
        idx = zeros(size(M, 1), 1);
        for i = 1:size(M, 1)
            idx(i) = numel(unique(M(i, :)));
        end
        idx = idx == sum(~empty);
        if sum(idx) > 1
            error('sbf_num_match:no_solution', 'No unique solution')
        end
        idx = ismember(M(idx, :), FILT);
    end
end

function idx = sbf_string_match(names, FILT)
    % Filter by exact OR partial string matches to given names
    idx = ismember({names.name}, FILT);
    if ~any(idx)
        idx = contains({names.name}, FILT);
    end
end
