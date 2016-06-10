function MeasMeta = gather_measurement_metadata(Subject, Measurement, varargin)
%GATHER_MEASUREMENT_METADATA - Collect information from MC
%
% Description:
%   A helper function that should be used to collect subject and measurement
%   specific metadata from MC. Typically this information is used when
%   storing features (and exporting them).
%
% Syntax:
%   MeasMeta = gather_measurement_metadata(Subject, Measurement, ...);
%
% Inputs:
%   'Subject'       ??, ??
%   'Measurement'   ??, ??
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%
% Outputs:
%   'MeasMeta'      ??, ??
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
% Copyright(c) 2015 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Subject', @isstruct); %MC.subject
p.addRequired('Measurement', @isstruct); %MC.measurement

p.addParamValue('measurementFields', ...
    {'casename','subject','subjectnr','session','measurement'},...
    @iscellstr);
p.addParamValue('subjectFields', {'age','sex'} , @iscellstr);

p.parse(Subject, Measurement, varargin{:});
Arg = p.Results;


%% Check data integrity
if ~strcmp(Subject.subject, Measurement.subject)
    error('gather_measurement_data:incoherentData','Subject field mismatch');
end


%% Collect data
MeasMeta = struct();
if ~isempty(Arg.measurementFields)
    for i = 1:length(Arg.measurementFields)
        i_field_name = Arg.measurementFields{i};

        if isfield(Measurement, i_field_name)
            MeasMeta.(i_field_name) = Measurement.(i_field_name);
        else
            fprintf(2,['gather_measurement_metadata: field ''',i_field_name,''' not found in Measurement.\n']);
        end
    end
end

if ~isempty(Arg.measurementFields)
    for i = 1:length(Arg.subjectFields)
        i_field_name = Arg.subjectFields{i};

        if isfield(Subject, i_field_name)
            MeasMeta.(i_field_name) = Subject.(i_field_name);
        else
            fprintf(2,['gather_measurement_metadata: field ''',i_field_name,''' not found in Subject.\n']);
        end
    end
end
