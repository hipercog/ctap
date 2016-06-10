function SO = RecuMergeStruct(A, B)
% RECUMERGESTRUCT recursively merges fields & subfields of structs A and B
%
% Description: The aim is to produce 1D arrays of every shared field in the
% two structs, indexed by the struct identifier, which we assume is a point
% field somewhere at the top level.
% Scalars are aggregated to vectors, vectors are aggregated if of equal
% size, mxn matrices are placed in cell arrays, as are cells and char
% arrays.
%
% INPUT
%   'A'      : struct, 'basis' of the merge
%   'B'      : struct, fields from B will be 'added' to fields from A
%
% OUTPUT
%   'SO'     : struct, compilation of structs A and B
%
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%   An original concept. Well-formed output and good behaviour not guaranteed!
%
% See also:  
%
% Copyright 2014- Benjamin Cowley, FIOH, benjamin.cowley@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin<2
        return;
    end
    SO = A;
    if isempty(A)
        SO = B;
        return;
    elseif isempty(B)
        return;
    end
    if ismatrix(A) && ismatrix(B)
        numa = numel(A);  numb = numel(B);
        for i = 1:min(numa, numb)
            SO(i) = MergeSimple(A(i), B(i));
        end
        if numb>numa
            for j = i:numb
                SO(j) = MergeSimple(A(j), B(j));
            end
        end
    else
        SO = MergeSimple(A,B);
    end
end

function SO = MergeSimple(A,B)
    SO = A;
    try
        fna = fieldnames(A);
        fnb = fieldnames(B);
        if ~isequal(fna, fnb)
            % copy extra fields from B to A
            for i = 1:length(fnb)
                fi = fnb{i};
                if ~isfield(A,fi)
                    SO.(fi) = B.(fi);
                end
            end
        end
        for i = 1:length(fna)
            fi = fna{i};
            if isfield(B,fi)
                if isempty(B.(fi))
                    continue;
                elseif isnumeric(B.(fi)) || islogical(B.(fi))
                    if isscalar(B.(fi)) && ~ismatrix(A.(fi))
                        if isrow(A.(fi))
                            SO.(fi) = [A.(fi)'; B.(fi)];
                        else
                            SO.(fi) = [A.(fi); B.(fi)];
                        end
                    elseif isvector(B.(fi))
                        [ra,ca] = size(A.(fi));   [rb,cb] = size(B.(fi));
                        if ra == rb
                            SO.(fi) = [A.(fi)'; B.(fi)'];
                        elseif ca == cb
                            SO.(fi) = [A.(fi); B.(fi)];
                        else
                            if iscell(SO.(fi))
                                SO.(fi){end+1} = B.(fi);
                            else
                                SO.(fi) = {A.(fi); B.(fi)};
                            end
                        end
                    else
                        if iscell(SO.(fi))
                            SO.(fi){end+1} = B.(fi);
                        else
                            SO.(fi) = {A.(fi); B.(fi)};
                        end
                    end
                elseif iscell(B.(fi)) || ischar(B.(fi))
                    if iscell(SO.(fi))
                        SO.(fi){end+1} = B.(fi);
                    else
                        SO.(fi) = {A.(fi); B.(fi)};
                    end
                elseif isstruct(B.(fi))
                    temp = RecuMergeStruct(A.(fi), B.(fi));
                    SO.(fi) = temp;
                end
            end
        end
    catch ME,
        disp([ME.message ' For: ' fi ';']);
    end
end
