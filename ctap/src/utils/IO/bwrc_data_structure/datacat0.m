function [data_array, labels] = datacat0(D, varargin) 
%datacat0 - Convert ATTK data structures into array and catenate (sublevel 0)
%
% Description:
%   Convert TTL data structures into array and catenate horizontally. Works
%   with data structures that satisfy <variable>.sublevels.n == 0. Several
%   data structures are handled at once.
%
% Syntax:
%   [data_array, labels] = datacat0(D);
%
% Inputs:
%   D   struct with data structures to catenate as fields. D could for
%       example contain fields .HRV and .BPV. 
%
% Outputs:
%   data_array  [n, m] cell, Data structure contents catenated
%               horizontally.
%   labels      [1, m] cell of strings, Column labels for 'data_array'.
%               Fields D.<variable>.labels are used as information source.
%   Indices:
%   n   number of calculation segments i.e. size(D.<variable_i>.data, 1)
%   m   sum(m_i), where m_i = size(D.<variable_i>.data, 2)
%   
% Assumptions:
%   Each data structure (D.<variable>) must contain the same number of 
%   data rows.
%   Each data structure should follow the conventions used for ATTK data
%   structures.
%
% References:
%   ATTK Matlab data structure documentation:
%   http://sps-doha-02/sites/329804/Aineistot/ATTK_Matlab_data_structure.doc
%
% Example:
%   D.SEGMENT = SEGMENT; %ATTK data structure with 0 sublevels 
%   D.HRV = HRV; %ATTK data structure with 0 sublevels
%   D.BPV = BPV; %ATTK data structure with 0 sublevels
%   [data_array, labels] = datacat0(D); 
%
% Notes:
%
% See also: datacat1.m, data2array.m, dataexport.m
%
% Version History:
% 4.11.2007 Created (Jussi Korpela, TTL)
% 19.7.2010 Support for long format added (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.outputFormat = 'wide'; %{'wide','long'}
Arg.channel_label = 'channel';
Arg.sublevel_id_string = {'combchan'};

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Initialize variables
labels = {};
data_array = {};

fields = fieldnames(D); %fields correspond to variables

%% Catenate variable data
for k=1:numel(fields) % over variables
     [k_datarows k_datacols]=size(D.(fields{k}).data);
    
    if strcmp(Arg.outputFormat,'wide')
        % Read data from field fields{k}
        k_datatmp = D.(fields{k}).data;

        if  ~iscell(k_datatmp)
            % Convert to cell array if necessary
            k_datatmp=mat2cell(k_datatmp,ones(k_datarows,1),ones(k_datacols,1));
        end

        % Append k:th data to result variables
        data_array = horzcat(data_array, k_datatmp);
        labels = horzcat(labels, D.(fields{k}).labels);
    
    else
       % long format 
        k_labels = D.(fields{k}).labels; %save labels for reference
        k_labels = k_labels(:)'; % to row vector (just to make sure)
        k_numel = numel(D.(fields{k}).data);
        
        k_data_long_tmp = reshape(D.(fields{k}).data, k_numel, 1);
        % columns stacked on top of each other: 1st all values of
        % variable1, 2nd all values of variable 2 etc.
        k_data_long_tmp = mat2cell(k_data_long_tmp,...
                            ones(k_numel,1),1);

        k_labels_long_tmp = repmat(k_labels, k_datarows, 1);
        k_labels_long_tmp = reshape(k_labels_long_tmp,...
                            numel(k_labels_long_tmp), 1);
        k_channel_long_tmp = repmat(Arg.sublevel_id_string, k_numel, 1);

        k_datatmp = horzcat(k_channel_long_tmp, k_labels_long_tmp, k_data_long_tmp);
        
        % Append k:th data to result variables
        data_array = vertcat(data_array, k_datatmp);
        labels = {Arg.channel_label,'variable','value'};
    end

    clear('k_*');
end  