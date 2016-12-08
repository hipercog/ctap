function [match, first_match_ind] = strArrayFind(strArray, searchStringArray, varargin)
%strArrayFind - search for substrings or strings within a string array
%
% Description:
%   Searches 'strArray' for substrings or strings specified in 
%   'searchStringArray'. Uses Matlab builtin "regexp.m" for substring 
%   comparison and "strmatch.m" for exact string comparison. 
%   Returns a logical array specifying which strings within 'strArray'
%   contain substrings/exact strings specified in 'searchStringArray'.
%   Returns also the indices of first matches of search strings within
%   'strArray'.
%
% Syntax:
%  match = strArrayFind(strArray, searchStringArray, varargin); 
%
% Inputs:
%   strArray            [n,1] cell, cell array of strings
%   searchStringArray   [m,1] cell of strings OR string, substrings to 
%                       search from 'strArray'
%   varargin            keyword-value pairs
%       Keyword         Values
%       matchMode       'substr' [default], 'exact', Allows for strings to
%                       be matched as substrings or as exact strings.
%
% Outputs:
%   match               [n,1] logical, A vector indicating which elements
%                       of 'strArray' have at least one "matching" 
%                       counterpart in 'searchStringArray'.
%                       The exact definition of "matching" 
%                       depends on varargin 'matchMode'. 
%   first_match_ind     [m,1] int, Indices of 'strArray' where the m:th
%                       element of 'searchStringArray' was first found.
%                       Note that a given search string might have been
%                       found at several positions within 'strArray' but
%                       this variable return only the position of first
%                       match.
%                       In case of no match assumes value NaN.
%
% Notes:
%
% References:
%
% Example: 
%   match = strArrayFind({'j','kj','jl'}, 'j', 'matchMode', 'exact');
%
% Notes: 
%   Remember that many special characters have a special meaning in regular
%   expressions. For example if you use strArrayFind to search for '[LOG]' 
%   it means that you want to search for any of the letters L, O or G. The
%   regexp '\[LOG]' seems to match the string '[LOG]'.
%
% See also: strrep.m, strmatch.m
%
% Version History:
% 11.3.2009 New output & improvements in code (Jussi Korpela, TTL)  
% 8.10.2007 Exact string matching and varargin added. (Jussi Korpela, TTL)
% 31.10.2006 Created (Jussi Korpela, TTL)
%
% Copyright 2006- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.

Arg.matchMode = 'substr'; %{'substr', 'exact'}


%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Convert possible char arguments
if ~iscellstr(searchStringArray)
    if ischar(searchStringArray)
        searchStringArray = cellstr(searchStringArray);
    else
        error('strArrayFind:inputError','Input variable ''searchStringArray'' is of wrong type.');
    end
end

if ~iscellstr(strArray)
    if ischar(strArray)
        strArray = cellstr(strArray);
    else
        error('strArrayFind:inputError','Input variable ''strArray'' is of wrong type.');
    end
end

%% Search for strings
match = false(size(strArray));
first_match_ind = NaN(size(searchStringArray)); 
if strcmp(Arg.matchMode, 'substr') 
    for i = 1:length(searchStringArray)  
        % Search for substring matches      
        i_start_idx = regexp(strArray, searchStringArray{i}); % Return the starting indices of each substring in a cell array
        i_match = ~cellfun(@isempty, i_start_idx); %i:th round matches
        
        % Set output variables
        match = match | i_match;  % Update global match
         
        if sum(i_match) > 0
            % Store position of first match
            first_match_ind(i) = find(i_match, 1, 'first');
        end

        clear('i_*');
    end

elseif strcmp(Arg.matchMode, 'exact')
    for i = 1:length(searchStringArray)  
        % Search for exact matches
        i_match_ind = strmatch(searchStringArray{i}, strArray, 'exact');
        
        % Set output variables
        if ~isempty(i_match_ind)
            match(i_match_ind) = 1;  
            first_match_ind(i) = i_match_ind(1);
        end
        clear('i_*');
    end
     
else       
   msg = 'Unrecognized value for ''matchMode''. Try again.'; 
   error('strArrayFind:varargError',msg);
end
