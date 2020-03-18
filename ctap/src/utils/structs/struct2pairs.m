function C = struct2pairs(S)
%Turns a scalar struct S into a cell of string-value pairs C
%
%  C = struct2pairs(S)
%

if ~isstruct(S) || length(S) > 1
    error 'Input must be a scalar struct or cell';
end

C = [fieldnames(S).'; struct2cell(S).'];
C = C(:).';