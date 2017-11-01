function S1 = intersect_struct(S1, S2)
%INTERSECT_STRUCT - replace contents struct S1 with S2 ONLY where fields match
f = intersect(fieldnames(S1), fieldnames(S2));
for i = 1:length(f)
    S1.(f{i}) = S2.(f{i});
end