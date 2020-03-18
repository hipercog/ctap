function S = struct_filter(S, Filt)
% struct_filter - Filter an element-by-element organized struct of data
%
% Description:
%   Selects a subset of rows from an element-by-element organized struct
%   based on a filter Filt. Rows that match all filtering criteria are
%   returned i.e. multiple filtering criteria are combined using AND.
%
% Syntax:
%   S = struct_filter(S, Filt);
%
% Inputs:
%   S         struct, element-by-element organized struct of data
%   Filt      struct, a struct of filtering criteria (see examples)
%
% Outputs:
%   S         struct, element-by-element organized struct of data with a 
%               subset of rows matching Filt. 
%
% Examples:
%   S.a = 1:3;
%   S.b = {'d1','d2', 'd3'};
%   S = structconv(S); %to element-by-element organization
%
%   clear Filt; %just to make sure
%   Filt.a = 1;
%   S2 = struct_filter(S, Filt)
%
%   clear Filt;
%   Filt.b = {'d2','d3'};
%   S3 = struct_filter(S, Filt)
%
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO (feature-request): make it possible to filter also plane-organized structs using structconv()

%% Check input
if size(S,1)==1
    % S should be of size dlen x 1, not 1 x dlen
    S = S';
end

if isempty(S)
   error('struct_filter:emptyInput','The input struct S is empty. Cannot compute.'); 
end

if isempty(Filt)
   error('struct_filter:emptyInput','The input struct Filt is empty. Cannot compute.'); 
end


%% Select cases (filtering)
% Creates the variable 'match' based on filtering selections passed by
% input variable 'filt'
dlen = numel(S);

ffnames = fieldnames(Filt);
n_ff = length(ffnames);

if n_ff >= 1

    select = false(dlen, n_ff); %temporary storage of filtering results
    for i = 1:n_ff 
        if isnumeric(Filt.(ffnames{i}))
            select(:,i) = ismember([S.(ffnames{i})], Filt.(ffnames{i}));
        else
            select(:,i) = ismember({S.(ffnames{i})}, Filt.(ffnames{i}));
        end
    end

    %select cases that meet all criteria (logical AND)
    match = sum(select, 2) == size(select, 2); 
    
else
    disp('getgroup: No fields found in ''Filt'', selecting all cases.');
    match = true(dlen,1);
end


S = S(match);