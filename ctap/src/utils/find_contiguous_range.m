function [inds] = find_contiguous_range(dvec, trgvalue)
%FIND_CONTIGUOUS_RANGE - Find contiguous ranges of some specified value within a vector
%
% Description:
%   Can be used to find contiguous ranges of 'trgvalue' within vector
%   'dvec'.
%
% Algorithm:
%   Simple stepping through using while.
%
% Syntax:
%   [inds] = find_contiguous_range(dvec, trgvalue)
%
% Inputs:
%   dvec        [1,n] or [n,1] int, A vector of integer values
%   trgvalue    [1,1] int, A target value
%
% Outputs:
%   inds        [m,2] int, Indices of contiguous ranges of 'trgvalue'
%               within 'dvec'.
%
% Assumptions:
%   Values comparable using == and ~=
%
%
% Example:
%   find_contiguous_range([1 1 1 1 1 0 0 1 1 0 0 1],1)
%   ans =
%        1     5
%        8     9
%       12    12
%
% Notes:
%
% See also: find, segpos
%
% Version History:
% 29.3.2011 Created (Jussi Korpela, TTL)
%
% Copyright 2011- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Find contiguous ranges
i = 1; %current position within dvec
last_was_target = false; % stores the state of dvec(i-1)
inds = []; %for storing contiguous target value ranges
ind = 0;%for indexing 'inds'

while(i<=numel(dvec))
    
    if (dvec(i) == trgvalue) && ~last_was_target
        % found first value of a new value range i.e. new range starts
        ind = ind + 1;
        inds(ind,1) = i;
        last_was_target = true;
    
    elseif (dvec(i) ~= trgvalue) && last_was_target
        % found a value not in ongoing value range i.e. range breaks 
        inds(ind,2) = i-1;
        last_was_target = false;
    end
        
    i = i+1;
end

if last_was_target
   inds(end,2) = numel(dvec); 
end
