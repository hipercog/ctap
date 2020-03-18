function [data_array, labels, nFactors] = data2array(S, data_variable_names, varargin)
%DATA2ARRAY - Convert the contents of an ATTK data file into cell array
%
% Description:
%   Converts the contents of an ATTK data file into a cell array. Typically
%   the resulting cell array is further written into a *.txt or *.csv file.
%   ATTK data file is a *.mat file that follows certain conventions (see
%   "Refenrences").
%   Variables INFO and FACTORS should always be present. These two
%   variables are always included into the data_array.
%
% Syntax:
%   [data_array, labels, nFactor] = data2array(S, data_variable_names, varargin);
%
% Inputs:
%   S   struct, Contains data variables as fields. Use command
%       "S = load('attk_data_file.mat')" to load the contents of an ATTK
%       data file into 'S'.
%   data_variable_names     [1,p] cell of strigs, Names of variables
%                           (fields of 'S') that should be converted.
%                           If 'data_variable_names' does not exist or is
%                           empty, all variables are converted.
%
% Outputs:
%   data_array  [n,m] cell (sublevel 0) and [n*k, m] cell (sublevel 1),
%               Contents of 'S' catenated vertically (and horizontally).
%   labels      [1, m] cell of strings, Column labels for 'data_array'.
%               Fields D.<variable>.labels are used as information source.
%   nFactors    Number of factors present in the data set.
%
%   varargin   Keyword-value pairs
%   'info_variable'     string, Name of the subject/measurement information
%                       variable, default: 'INFO'
%   'segment_variable'  string, Name of the calculation segment information
%                       variable, default: 'FACTORS'
%
%  Indices:
%   n   number of calculation segments i.e. size(D.<variable_i>.data, 1)
%   k   number of sublevel 1 classifier levels (if any)
%   m   sum(m_i), where m_i = size(D.<variable_i>.data, 2)
%
% References:
%   ATTK Matlab data structure documentation:
%   http://sps-doha-02/sites/329804/Aineistot/ATTK_Matlab_data_structure.doc
%
% Example:
%   S = load('attk_data_file.mat');
%   [data_array, labels] = data2array(S, {'HRV','BPV'});
%   [data_array, labels] = data2array(S, {'EEG','ERP'});
%
% Notes:
%   It is possible to export "sublevel 0 data" (such as HRV) in the
%   same cell array with "sublevel 1 data" (such as EEG) but the
%   result won't be pretty. "Sublevel 0 data" is copied k times
%   vertically to match the extent of "sublevel 1 data". The resulting
%   array can be misleading to anyone not familiar with the data. Therefore
%   it is recommended that "sublevel 0 data" and "sublevel 1 data" are
%   exported into separate arrays.
%
% See also: datacat0.m, datacat1.m, dataexport.m
%
% Version History:
% 4.11.2007 Created (Jussi Korpela, TTL)
% 19.7.2010 Support for long format data added (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.info_variable = 'INFO';
Arg.factors_variable = 'FACTORS';
Arg.outputFormat = 'long'; %{'wide','long'}


%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Interpret function arguments
if ~exist('data_variable_names','var')
    result_variable_selection = {'all'};
elseif isempty(data_variable_names)
    result_variable_selection = {'all'};
else
    result_variable_selection = data_variable_names;
end


%% Identify variables
%TODO: Test variable existence: write a dedicated function for it?
%info_match = strArrayFind(fields, {Arg.info_variable});


%% Extract INFO - Subject and measurement specific information
if isfield(S,'INFO')
    disp('data2array: INFO -field present...')
    infoPresent = true;
    INFO = S.(Arg.info_variable);
    S = rmfield(S, Arg.info_variable);
else
    infoPresent = false;
end


%% Extract FACTORS - Calculation segment specific information
if isfield(S,Arg.factors_variable)
    disp(['data2array: Using ',Arg.factors_variable,' for factors...'])
    FACTORS = S.(Arg.factors_variable);
    S = rmfield(S, Arg.factors_variable);
else
    error('data2array:factorsVariableNotFound',['Variable ',Arg.factors_variable,' not found. Cannot proceed.']);
end


%% Select variables (data collections) to process
allfields = fieldnames(S);
if sum(strcmp(result_variable_selection, 'all'))==1 && numel(result_variable_selection)==1
    fields = allfields; %select all
else
    % Select only some of the available
    selected_fields_match = strArrayFind(allfields, result_variable_selection, 'matchMode', 'exact');
    fields = allfields(selected_fields_match);
end


%% Separate fields in S (data collections) based on number of sublevels
S0 = struct();
S1 = struct();
for i = 1:numel(fields)
    
    % Check if there are sublevels present in the field
    if ~(isfield(S.(fields{i}), 'sublevels'))
        S.(fields{i}).sublevels.n = 0;
    end
    
    if S.(fields{i}).sublevels.n == 0
        disp(['data2array: collection ''',fields{i},''' does not have sublevels.']);
        S0.(fields{i}) = S.(fields{i});
        S = rmfield(S,fields{i});
        
    elseif S.(fields{i}).sublevels.n == 1
        disp(['data2array: collection ''',fields{i},''' has sublevels.']);
        S1.(fields{i}) = S.(fields{i});
        S = rmfield(S,fields{i});
    else
        
        error();
    end
    
    %{
    % T�t� voisi k�ytt�� struktuurin 'S' kenttien luokitteluu, mik�li
    % S.<var>.sublevels.n osoittautuu huonoksi tavaksi toimia.

    % Divide data by structure type
    % 'S' -> 'S0' and 'S1'
    for k = 1:numel(param_res_arr)
       if isfield(S.(param_res_arr{j}),'data')
            % Basic data construction: S.<variable>.data
            S0.(param_res_arr{j}) = S.(param_res_arr{j});
            S = rmfield(S, param_res_arr{j});
       else
            % EEG data construction: S.<variable>.<channel>.data
            S1.(param_res_arr{j}) = S.(param_res_arr{j});
            S = rmfield(S, param_res_arr{j});
       end
    end
    %}
end


%% Convert different types of data to array
% INFO
if infoPresent
    infofields = fieldnames(INFO);
    info_labels = infofields';
    info_row = {};
    for i = 1 : numel(infofields)
        info_row = horzcat(info_row, {INFO.(infofields{i})});
    end
    nFactors = numel(info_row);
else
    info_labels = [];
    nFactors = 0;
end

% FACTORS
factors_labels = FACTORS.labels;
factors_array = FACTORS.data;
nFactors = nFactors + numel(factors_labels);

% DATA sublevel 0
n_output_rows = NaN;
if ~isempty(fieldnames(S0))
    [data0_array, data0_labels] = datacat0(S0, 'outputFormat', Arg.outputFormat);
    data0_exist = true;
else
    data0_exist = false;
end

% DATA sublevel 1
if ~isempty(fieldnames(S1))
    [data1_array, data1_labels] = datacat1(S1, 'outputFormat', Arg.outputFormat);
    data1_exist = true;
else
    data1_exist = false;
end


%% Construct variable array
data_array  = [];
labels = [];
if strcmp(Arg.outputFormat, 'wide')
    % Combine S0 and S1 data
    % S0 data
    if data0_exist
        data_array  = data0_array;
        labels = data0_labels;
    end
    
    % Combine with S1
    if data1_exist
        n_levels1 = numel(unique(data1_array(:,1)));
        data_array = repmat(data_array, n_levels1, 1);
        
        % data_array = horzcat(data1_array, data_array);
        % labels = horzcat(data1_labels, labels);
        data_array  = horzcat(data1_array, data_array);
        labels = horzcat(data1_labels, labels);
    end
    
end
if strcmp(Arg.outputFormat, 'long')
    % long format data
    
    % Combine S0 and S1 data
    % S0 data
    if data0_exist
        data_array  = data0_array;
        labels = data0_labels;
    end
    
    % Combine with S1
    if data1_exist
        data_array  = vertcat(data_array, data1_array);
        labels = data1_labels;
        % S1 labels should override S0 labels, since S0 has only dummy
        % sublevel 1 whereas S1 sublevel 1 name comes from the dataset.
    end
end


%% Multiply INFO and FACTORS to match data output format
n_output_rows = size(data_array,1);

% INFO
if infoPresent
    info_array = repmat(info_row, n_output_rows, 1);
else
    info_array = [];
end

% FACTORS
n_times = n_output_rows / size(factors_array, 1);
if (n_times - round(n_times) ~=0)
    % We end up here if there are differing number of calculation segments
    % for feature data (data_array) and cseg metadata (factors_array).
    % Currently feature values are matched to cseg metadata by cseg event
    % order alone. There needs to be the same number of cseg events in 
    % EEG.event as there are feature values in each of feature sets in
    % S0 and S1.
    error('Feature data ("data_array") and cseg metadata ("factors_array") are out of sync. Possible reason is that features could not be computed for some calculation segments. Cannot create result array.');
end
factors_array = repmat(factors_array, n_times, 1);
% todo: check by ordering and/or time stamp comparison that cseg metadata
% and feature data are in sync. Currently the data does not contain enough
% information to do so...


%% Add INFO and FACTORS to variable array
data_array  = horzcat(data_array, factors_array, info_array);
labels = horzcat(labels, factors_labels, info_labels);
disp(['data2array: output format: ' , Arg.outputFormat]);

end
%[EOF]