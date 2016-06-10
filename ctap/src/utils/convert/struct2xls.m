function struct2xls(S, xlsfile, sheet, varargin)
%STRUCT2XLS - Write struct data into MS Excel, fields create columns
%
% Description:
%   Data from struct S is written into MS Excel file sheet 'sheet'. 
%   The first row is considered to contain column headings, which will 
%   match the fieldnames of struct S.
%
%   To maintain compatibility with xls2struct.m, text columns should contain
%   some data on each row. The value 'Arg.emptyText' is used to replace any
%   empty values in text columns. Text columns are identified based on first
%   row.
%
% Syntax: struct2xls(S, xlsfile, sheet, varargin)   
%
% Inputs:
%   S           struct, Matlab struct with either numeric or text data in
%               its fields.  Plane organized structures are preferred. 
%               Element organized structs are converted into plane
%               organization using structconv.m. See Matlab hep "Organizing 
%               Data in Structure Arrays" for details of struct organization.
%   xlsfile     string, Full filename of the *.xls file
%   sheet       string, name of the sheet to be written
%   varargin    keyword-value pairs, Available combinations are:
%               Keyword         Values
%               'emptyText'     string, Any string, default: 'n/a'
%
% Outputs:
%   Writes into xls file specified by 'xlsfile';
%
% References:
%
% Example: struct2xls(S, 'tiedosto.xls', 'datataulukkko');
%
% Notes:
%
% See also: xls2struct.m, xlsread.m, structconv.m
%
% Version history
% Created, 23.1.2008, Jussi Korpela, TTL
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.emptyText = 'n/a';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Test input struct type and convert if necessary
if sum(size(S) == [1 1]) ~= 2
    % Struct is of element-by-element organization
    S = structconv(S);
end


%% Convert to cell array
sc = struct_to_cell(S);


%% Find empty text cells and replace contents
textcol_match = cellfun(@isstr, sc(1,:)); %columns containing text
empty_textcell_match = cellfun(@isempty, sc(:,textcol_match)); %empty cells in text columns

tmp = false(size(sc));
tmp(:,textcol_match) = empty_textcell_match; %global position of empty text cells

sc(tmp) = {Arg.emptyText}; % replace empty values


%% Create output
label = fieldnames(S);
sc = vertcat(label', sc');


%% Write to file
warning off MATLAB:xlswrite:AddSheet;
xlswrite(xlsfile, sc, sheet);