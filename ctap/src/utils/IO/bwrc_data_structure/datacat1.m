function [data_array, labels] = datacat1(D, varargin) 
%datacat1 - Convert ATTK data structures into array and catenate (sublevel 1)
%
% Description:
%   Convert TTL data structures into array. Each data structure in 'D' must
%   contain one sublevel classifier, typically EEG channel.
%   Different sublevels are catenated vertically, whereas different data 
%   structures are catenated horizontally.
%   Works only with data structures that satisfy <variable>.sublevels.n == 1.
%   Several data structures are handled at once.
%
% Syntax:
%   [data_array, labels] = datacat1(D, varargin);
%
% Inputs:
%   D   struct with data structures to catenate as struct fields. D could 
%       for example contain fields .EEG and .ERP.
%       D CANNNOT CONTAIN metadata fields INFO, FACTORS or SEGMENT.
%       D HAS TO CONTAIN only data that is in one sublevel classifier
%       format.
%
% Outputs:
%   data_array  [n*k, m] cell, Data structure contents catenated
%               vertically and horizontally (see description).
%   labels      [1, m] cell of strings, Column labels for 'data_array'.
%               Fields D.<variable>.labels are used as information source.
%   varargind   Keyword-value pairs
%   'channel_label'     Label for sublevel 1 classifier, default: read from
%                       first data structure (<var1>.sublevels.names{1})
%   'non_data_fields'   Fields <var> that do not define a sublevel 
%                       classifier level, 
%                       default: {'labels','units','parameters','sublevels'}
%                       Because of this option, it is also possible to
%                       convert data structures that do not fully match the
%                       ATTK data structure description.
%
%   Indices:
%   n   number of calculation segments i.e. size(D.<variable_i>.data, 1)
%   k   number of sublevel 1 classifier levels
%   m   sum(m_i), where m_i = size(D.<variable_i>.data, 2)
%   
% Assumptions:
%   All data structures in D must have the same classifier with the same 
%   levels coded into sublevel 1.
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
%   D.EEG = EEG; %ATTK data structure with 0 sublevels
%   D.ERP = ERP; %ATTK data structure with 0 sublevels
%   [data_array, labels] = datacat1(D); 
%
% Notes:
%
% See also: datacat0.m, data2array.m, dataexport.m
%
% Version History:
% 4.11.2007 Created (Jussi Korpela, TTL)
% 19.7.2010 Support for long format added (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela & Andreas Henelius, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fields = fieldnames(D); %list fields to add

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.channel_label = D.(fields{1}).sublevels.labels{1};
Arg.non_data_fields = {'labels','units','parameters','sublevels'};
Arg.outputFormat = 'wide'; %{'wide','long'}

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Collect data
% Initialize outputs
labels = {};
data_array = {};

for k=1:numel(fields)% over variables

    k_labels = D.(fields{k}).labels; %save labels for reference
    k_labels = k_labels(:)'; % to row vector (just to make sure)
    
    D.(fields{k}) = rmfield(D.(fields{k}), Arg.non_data_fields); %remove non data fields
    
    %Sort fields so that channel name column is valid for all variables k
    D.(fields{k}) = orderfields(D.(fields{k})); 
    
    k_channels = fieldnames(D.(fields{k})); %rest of fields treated as level 1 classifiers
    
   
    if k == 1 
        % Save first sublevel classifer level name vector for reference
        ref_channels = k_channels;
        ref_field = fields{k};
    end
    
    % Test sublevel classifier level order and names
    if sum(strcmp(ref_channels, k_channels)) ~= numel(ref_channels)
        msg = ['Sublevel classifier of the variable ', fields{k} ,...
                ' differs from ', ref_field, ' which is used as reference.'];
        error('datacat1:sublevelClassifierError',msg)
    end
    
    k_data = {};

    for m = 1:numel(k_channels) %over channels
        [m_datarows m_datacols]=size(D.(fields{k}).(k_channels{m}).data);
        m_numel = numel(D.(fields{k}).(k_channels{m}).data);
        
        if strcmp(Arg.outputFormat,'wide')
            % Read data from field fields{k}
            m_datatmp = D.(fields{k}).(k_channels{m}).data;

            if  ~iscell(m_datatmp)
                % Convert to cell array if necessary
                m_datatmp=mat2cell(m_datatmp,ones(m_datarows,1),ones(m_datacols,1));
            end

            if k == 1
               % Add column of channel names 
               m_channel_vec =  repmat(k_channels(m),m_datarows,1);
               m_datatmp = horzcat(m_channel_vec, m_datatmp); 
            end
            
        else
            % long format
            m_data_long_tmp = reshape(...
                D.(fields{k}).(k_channels{m}).data, m_numel, 1);
            % columns stacked on top of each other: 1st all values of
            % variable1, 2nd all values of variable 2 etc.
            m_data_long_tmp = mat2cell(m_data_long_tmp,...
                                ones(m_numel,1),1);
            
            m_channel_vec =  repmat(k_channels(m),m_numel,1);
            
            m_labels_long_tmp = repmat(k_labels, m_datarows, 1);
            m_labels_long_tmp = reshape(m_labels_long_tmp,...
                                numel(m_labels_long_tmp), 1);
            
            m_datatmp = horzcat(m_channel_vec, m_labels_long_tmp, m_data_long_tmp);
        end
        
        % Append m:th data to result variables
        k_data = vertcat(k_data, m_datatmp);

        clear('m_*');

    end

    if strcmp(Arg.outputFormat,'wide')
        % Append k:th data to result variables
        data_array = horzcat(data_array, k_data);
        if k == 1
            labels = horzcat(Arg.channel_label, k_labels); 
        else
            labels = horzcat(labels, k_labels);
        end
    else
        %long format
        % Append k:th data to result variables
        data_array = vertcat(data_array, k_data);
        labels = {Arg.channel_label,'variable','value'};
    end

    clear('k_*');

end 
