function [sOut, diff_size] = struct_field_diff(s1, s2, verbose, s1str, s2str)
%STRUCT_FIELD_DIFF returns the difference between two structs
%
% Description: recursive comparison between two structs will give back the
% fields which are different between them , plus the count of the number of
% such fields.
%   
%
% Syntax:
%   sOut = struct_field_diff(s1, s2, s1str, s2str, verbose);
%
% Inputs:
%   s1          struct, that serves as baseline
%   s2          struct, additions in this struct are returned
%   verbose     boolean, flag for printing the structure difference
%   s1str       string, name of structure 1 in workspace or calling func
%   s2str       string, name of structure 2 in workspace or calling func
%
%
% Outputs:
%   sOut        struct, structure containing only difference
%   diff_size   scalar, count of the number of different fields
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%   Inspired by strucdiff() from Matlab's FX
%
% See also:  
%
% Copyright 2014- Benjamin Cowley, FIOH, benjamin.cowley@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    verbose = 0;
end
if nargin < 4
    s1str = inputname(1);
    s2str = inputname(2);
end

sOut = struct();
diff_size = 0;
% s1mem = whos('s1');
% s2mem = whos('s2');
% if s1mem.bytes == s2mem.bytes
%     return;
% end
if isstruct(s1) && isstruct(s2)
    sOut = s2;
    f1 = fieldnames(s1);
    f2 = fieldnames(s2);
    g1 = setdiff(f2,f1);
    for k = 1:length(g1)
        if verbose, fprintf('%s misses <.%s>.\n', s1str, g1{k}); end
        diff_size = diff_size + count_struct_nodes(s2.(g1{k}));
    end
    fcommon = intersect(f1,f2);
    for k = 1:length(fcommon)
%         for i = 1:length(s1)
        fk = fcommon{k};
        sOut = rmfield(sOut, fk);
        [tmpOut, dfsz] = struct_field_diff(...
            s1.(fk), s2.(fk), verbose, [s1str '.' fk], [s2str '.' fk]);
        if isstruct(tmpOut) && ~isempty(fieldnames(tmpOut))
            sOut.(fk) = tmpOut;
        end
        diff_size = diff_size + dfsz;
    end
elseif isstruct(s1)
    fprintf('struct_field_diff::struct %s was replaced by non-struct %s'...
        , s1str, s2str)
elseif isstruct(s2)
    sOut = s2;
    diff_size = sbf_count_struct_fields(s2);
else
    sOut = struct('s2_changed_data', s2);
end

    function c = sbf_count_struct_fields(s)
        f = fieldnames(s);
        c = numel(f);
        if isscalar(s)
            r = find(structfun(@isstruct, s));
        else
            disp('Found 2 grandmothers. True diff size > reported diff size.')
            return
        end
        for i = 1:numel(r)
            c = c + sbf_count_struct_fields(s.(f(i)));
        end
    end

end%struct_field_diff()
