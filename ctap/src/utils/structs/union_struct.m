function SU = union_struct(S1, S2)
%UNION_STRUCT works for non-nested structs with the same fields

if isempty(S1) && isempty(S2), SU = struct; return; end
if isempty(S1) && ~isempty(S2), SU = S2; return; end
if isempty(S2) && ~isempty(S1), SU = S1; return; end

fs1 = fieldnames(S1);
fs2 = fieldnames(S2);

if isempty(setdiff(fs1, fs2))
    numfs = numel(fs1);
    SU = cell2struct(sbf_cat_equal_structs, fs1, 1);
    SU = SU';
else
    error('union_struct:UNEQUAL', 'Struct argument fieldnames don''t match')
end


function out = sbf_cat_equal_structs

    C1 = struct2cell(S1');
    if size(C1, 1) ~= numfs || ~ismatrix(C1)
        C1 = struct2cell(S1);
    end
    C2 = struct2cell(S2');
    if size(C2, 1) ~= numfs || ~ismatrix(C2)
        C2 = struct2cell(S2);
    end
    out = [C1 C2];
end

end