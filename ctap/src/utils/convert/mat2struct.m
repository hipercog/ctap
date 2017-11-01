function [matstruct] = mat2struct(mat, fieldnames)
%MAT2STRUCT - Convert 2-dim matrix into struct
%
% Description:
%   Converts a 2-dimensional matrix into a struct with given fieldnames.
%   Runtime constants not defined by function arguments: no
%
% Syntax:
%   [matstruct] = mat2struct(mat, fieldnames)
%
% Inputs:
%   mat         i-by-k numeric, matrix
%   fieldnames  k-by-1 cell of strings, fieldnames for the new struct
%
% Outputs:
%   matstruct   struct, Data from matrix in fields defined by fieldnames.
%
% References:
%
% Example: test = mat2struct(rand(10,3), {'col1','col2','col3'});
%
% See also: mat2cell.m, cell2struct.m, struct2cell.m
%
% Version History:
% First version (3.5.2007, Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if size(mat,2) ~= length(fieldnames)
   error('mat2struct:sizeMismatchError', 'Cannot create structure because size(mat,2)~=length(fieldnames).'); 
end

mat_cell = mat2cell(mat, size(mat,1), ones(1,size(mat,2))); %matrix to cell
matstruct = cell2struct(mat_cell, fieldnames, 2); %cell to struct