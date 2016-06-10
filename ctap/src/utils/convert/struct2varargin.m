function varg = struct2varargin(S, selection_prefix)
% STRUCT2VARARGIN - Convert struct into varargin compatible cell array
%
% Description:
%   Converts struct into a cell array. The cell array will be of form
%   {fieldname_1, field_value_1, fieldname_2, field_value_2, ...}.
%   This function comes in handy when one wishes to represent certain set
%   of configuration parameters in struct form and these parameters have to
%   be passed on to other functions as varargin. The function
%   input_interp.m does the opposite i.e. converts varargin cell array to
%   struct.
%
%   Using input argument 'selection_prefix' it is possible to select which
%   fields in 'S' are passed on to 'varg'. With this feature it is possible
%   to convert e.g. only values that relate to a certain task. See section
%   "Example".
%
% Syntax:
%   varg = struct2varargin(S);
%
% Inputs:
%   S   struct, Struct to convert, Multilevel fields are not allowed i.e.
%       'S.field_1' is ok but 'S.field_1.field_b' is not.
%   selection_prefix    string, String specifying the entries of 'S' that
%                       are supposed to be converted. Only those fields in 
%                       'S' whose fieldname begin with 'selection_prefix' 
%                       are converted and saved to 'varg'. The string 
%                       'selection_prefix' is removed from the fieldnames
%                       prior to saving into 'varg'. If no selection is
%                       needed, use empty string or leave
%                       'selection_prefix' unspecified.
%
% Outputs:
%   varg    [1,2*n] cell, Contents of the struct 'S' in cell array. If 'S'
%           has n fields, 'varg' will be of length 2*n. 
%
% Assumptions:
%
% References:
%
% Example: 
%   For example one might have a struct 'Arg' with a set of fields '.plot_*' 
%   that define plotting parameters for a certain plotting function. Using
%   command
%   plot_varargin = struct2varargin(Arg, 'plot_');
%   you get only entries that began with 'plot_' in a cell array along with
%   the respective values. The prefix 'plot_' is removed in the process and
%   does not exist in the fieldnames stored into 'plot_varargin'.
%
% Notes:
%
% See also: input_interp
%
% Version History:
% 14.8.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('selection_prefix','var')
    selection_prefix = '';
end

% Convert struct to cell array
fnames = fieldnames(S); %fieldnames as cell array
data = struct2cell(S); %data value as cell array

% Select only certain entries
selection_inds = strmatch(selection_prefix, fnames);
fnames = fnames(selection_inds); 
data = data(selection_inds);

% Drop out selection prefix
fnames = strrep(fnames, selection_prefix, '');

% Initialize output
varg = cell(1, 2*length(fnames)); 

% Assign data to output
varg(1:2:2*length(fnames)) = fnames;
varg(2:2:2*length(fnames)) = data;