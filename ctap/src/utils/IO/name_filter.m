function [fltnames, nameidx] = name_filter(rawnames, subj_filt)
%NAME_FILTER returns those elements from rawnames that match by:
%       names: being equal to, or containing, one of the given strings, or
%       indices: having an index equal to one of the given numbers, or
%       subject numbers: having a filename containing one of given numbers
%   CAN MIX TYPE MODES LIKE SO: strings AND/OR (indices OR subj_numbers),
% 
%   Can also do inverse filtering, same modes as above but flipped logic:
%       ~names: reject filenames containing these strings, if prepended with '~'
%       -1 * indices: reject files at any index with negative sign
%       -1 * subject numbers: reject filenames containing negative signed numbers
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

%--------------------------------------------------------------------------
% Initialise inputs
p = inputParser;
p.addRequired('rawnames', @isstruct);
p.addRequired('subj_filt', @(x) iscell(x) || isnumeric(x) || ischar(x) || islogical(x));
p.parse(rawnames, subj_filt);
% Arg = p.Results;


%% Return all or none
if strcmp('all', subj_filt)
    fltnames = rawnames;
    nameidx = true(numel(rawnames), 1);
    return
elseif isempty(subj_filt)
    fltnames = struct('name', {});
    nameidx = false(numel(rawnames), 1);
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
        num_filt = subj_filt{testnum};
    end
end


%% Find indices of filtered files
stridx = false(1, length(rawnames));
numidx = false(1, length(rawnames));
invert_strs = false;
invert_nums = false;

if ~isempty(str_filt)
    if all(cellfun(@(x) startsWith(x, '~'), str_filt, 'Un', 0))
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
    % Filter by numeric index or numeric part of given name
%TODO - REPLACE NUMERIC INDICES WITH LOGICAL, SO NO CONFUSION POSSIBLE!!!!!
    testi = num_filt(ismember(num_filt, 1:length(rawnames)));
    if isempty(testi)
        testi = num2cell(num_filt);
        numidx = sbf_string_match(rawnames...
                                , cellfun(@num2str, testi, 'Uni', false));
    else
        numidx = ismember(1:length(rawnames), num_filt);
    end
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


function idx = sbf_string_match(names, FILT)
    % Filter by exact OR partial string matches to given names
    idx = ismember({names.name}, FILT);
    if ~any(idx)
        idx = contains({names.name}, FILT);
    end
end
