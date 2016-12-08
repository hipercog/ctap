function [mat, matlabels] = struct2mat(S)
%STRUCT2MAT - Convert a special case of struct into matrix
%
% Description:
%   Converts a struct whose elements are numeric vectors into a matrix.
%   Can be used e.g. to convert between different representations of a CNT
%   event structure EV2.
%
% Syntax:
%   [mat, matlabels] = struct2mat(S);
%
% Inputs:
%   S   struct, Struct with M fields that contain only numeric vectors
%       Every vector must be of the same length N.
%
% Outputs:
%   mat         [N,M] numeric, The data of S as a matrix
%   matlabels   [1,M] cell of strings, Matching fieldnames of S
%
% Assumptions:
%   Assumes a very specific type of struct as input.
%
% Notes:
%
% Example:
%   MatStruct = mat2struct(rand(5,3), {'col1','col2','col3'})
%   [mat, matlabels] = struct2mat(MatStruct)
%
% See also: mat2struct
%
% Version History:
% 24.3.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize variables
matlabels = fieldnames(S);
M = length(matlabels);
N = length(S.(matlabels{1}));
mat = NaN(N, M);

%% Assign data
for m = 1:M
    % Test m:th field data type
    if isnumeric(S.(matlabels{m}))
        % Test m:th field data length
        if length(S.(matlabels{m})) == N
            mat(:,m) = S.(matlabels{m});
        else
            msg = ['Field ', matlabels{m}, ' has too few/many elements. Cannot compute.'];
            error('struct2mat:inputError',msg);
        end
    else
        msg = ['Field ', matlabels{m}, ' is not numeric. Cannot compute.'];
        error('struct2mat:inputError',msg);
    end
end
end %of struct2mat.m