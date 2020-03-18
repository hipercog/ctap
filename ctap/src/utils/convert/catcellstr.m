function strout = catcellstr(strarray, varargin)
%CATCELLSTR - Catenate cell array of strings into single string
%
% CONSIDER USING MATLAB BUILTIN STRJOIN(,'-') INSTEAD.
%
% Description:
%   Catenates individual elements of a cell array of strings into a single
%   string. Elements separated by 'sep'.
%   Handy for example when creating plotting labels, legends and titles.
%
% Syntax:
%   strout = catcellstr(strarray, varargin)
%
% Inputs:
%   strarray    [1,n] or [n,1] cell of strings, Array of strings to catenate
%               If 'strarray' is of type string, strout = strarray.
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, value
%   'sep'           str, Catenation separator, default: '-'	
%
% Outputs:
%   strout  string, Elements of 'strarray' catenated into single string
%           using 'Arg.sep' as delimiter.
%
% Assumptions:
%
% References:
%
% Example: strout = catcellstr({'pla','plop'}, 'sep', ';')
%
% Notes:
%
% See also:
%
% Version History:
% 29.10.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.sep = '-'; % Catenation separator

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Check inputs
if ischar(strarray)
    strout = strarray;
    return
elseif all(cellfun(@isempty, strarray))
    strout = '';
    return
end

%% Catenate
strarray = strarray(:); %to column vector

strarray(1:(end-1),2) = {Arg.sep}; %add separators
strarray = strarray';
strout = [strarray{:}]; %cantenate