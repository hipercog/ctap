function S1 = joinstruct(S1, S2)
%JOINSTRUCT - Add/replace contents of struct S2 to struct S1
f = fieldnames(S2);
for i = 1:length(f)
    S1.(f{i}) = S2.(f{i});
end