function S1 = joinstruct(S1, S2)
%JOINSTRUCT - Add/replace contents of struct S2 to struct S1
f = fieldnames(S2);
for i = 1:length(f)
    S1.(f{i}) = S2.(f{i});
end


% % S2 overwrites scalar non-struct fields
% f = fieldnames(S2);
% for i = 1:numel(f)
%     if isstruct(S2.(f{i})) && isstruct_safe(S1, f{i})
%         S1.(f{i}) = mergeStructs(S1.(f{i}), S2.(f{i}));
%     else
%         S1.(f{i}) = S2.(f{i});
%     end
% end
% 
% function ok = isstruct_safe(s,field)
%     ok = isfield(s,field) && isstruct(s.(field));
% end

%{
function dst = mergePreserve(dst, src)
% dst = mergePreserve(dst, src)
% Recursively merge src into dst. Existing non-struct dst fields are preserved.
if isempty(dst)
    dst = struct();
end
fs = fieldnames(src);
for k = 1:numel(fs)
    f = fs{k};
    if isfield(dst, f)
        % both struct -> recurse
        if isstruct(dst.(f)) && isstruct(src.(f))
            dst.(f) = mergePreserve(dst.(f), src.(f));
        else
            % preserve existing dst.(f) (do nothing)
        end
    else
        % dst missing field -> copy from src
        dst.(f) = src.(f);
    end
end
end
%}

end