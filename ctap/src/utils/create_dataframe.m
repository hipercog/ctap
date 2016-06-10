function df=create_dataframe(data, dimnames, dimlabels)
%CREATE_DATAFRAME - Create a struct that mimics R data.frame
%
% Description:
%
% Syntax:
%   df=create_dataframe(data, dimnames, dimlabels);
%
% Inputs:
%   data        [i,j,k,...] numeric, Data matrix
%   dimnames    [1, numel(size(data))] cell of strings, Data dimension names
%   dimlabels   [1, numel(size(data))] cell of vectors, Data dimension
%               labels. dimlabels{i} can be either cell or vector.
%
% Outputs:
%   df  struct, A self-documenting "data.frame"
%   df.data     [i,j,k,...] numeric, Data matrix
%   df.dim      [1,I] struct, Dimension information, I=numel(size(data))
%   df.dim(i).name      string, Name of dimension i.
%   df.dim(i).labels    [1,size(data,i)] vector of cell of strings, Data
%                       labels along dimension i.
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also:
%
% Version History:
% 27.6.2014 Created (Jussi Korpela, FIOH)
%
% Copyright 2014- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
df.data = data;

for i=1:numel(size(data))
   df.dim(i).name = dimnames{i};
   df.dim(i).labels = dimlabels{i}(:); %column vectors/cellarrays
end