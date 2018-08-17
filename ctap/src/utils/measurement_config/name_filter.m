function fltnames = name_filter(rawnames, varargin)
%NAME_FILTER returns those elements from rawnames that match by:
%           being equal to, or containing, one of the given strings
%           having an index equal to one of the given numbers, or
%           having a filename containing one of the given numbers
%           If keyword 'all' is used, all elements are returned (default)
%           If filters are empty, no elements are returned

%--------------------------------------------------------------------------
% Initialise inputs
p = inputParser;
p.addRequired('rawnames', @isstruct);
p.addParameter('subj_filt', {'all'}, @iscell);
p.parse(rawnames, varargin{:});
Arg = p.Results;


if strcmp('all', Arg.subj_filt)
    fltnames = rawnames;
    return
end

num_filt = [];
str_filt = {};
testchar = cellfun(@ischar, Arg.subj_filt);
if all(testchar)
    str_filt = Arg.subj_filt;
else
    testcell = cellfun(@iscell, Arg.subj_filt);
    if any(testcell)
        testchar = cellfun(@ischar, Arg.subj_filt{testcell});
        if all(testchar)
            str_filt = Arg.subj_filt{testcell};
        end
    end
    testnum = cellfun(@isnumeric, Arg.subj_filt);
    if any(testnum)
        num_filt = Arg.subj_filt{testnum};
    end
end

stridx = false(1, length(rawnames));
numidx = false(1, length(rawnames));

if ~isempty(str_filt)
    stridx = sbf_string_match(rawnames, str_filt);
end

if ~isempty(num_filt)
    % Filter by numeric index or numeric part of folder name
    testi = num_filt(ismember(num_filt, 1:length(rawnames)));
    if isempty(testi)
        testi = num2cell(num_filt);
        numidx = sbf_string_match(rawnames, cellfun(@num2str, testi, 'Uni', false));
    else
        numidx = num_filt;
    end
end

fltnames = rawnames(stridx | numidx);

end


function idx = sbf_string_match(names, FILT)
    % Filter by exact OR partial string matches to folder names
    idx = ismember({names.name}, FILT);
    if ~any(idx)
        idx = contains({names.name}, FILT);
    end
end
