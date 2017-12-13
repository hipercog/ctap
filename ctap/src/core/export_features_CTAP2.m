function export_features_CTAP2(id, featureIDArr, measFilt, MC, Cfg)
%CTAP_export_features2 - Export of CTAP study-level features into a text file
%
% Description:
%   Generates a list of result files based on 'featureIDArr' and
%   'measFilt'. Reads data from these files, formats it and saves the
%   result into a text file. 
%   Note: only simple primitive data are exported. Arrays, such as 
%   features from segments, are not exported.
%
%   Compared to export_features_CTAP, this function can export
%   whole-EEG features (one feature per EEG). The original
%   export_features_CTAP can only export features per epoch.
%
% Syntax:
%   export_features_CTAP2(id, featureIDArr, measFilt, MC, Cfg);
%
% Inputs:
%   id              string, Result csv file name (without ".csv")
%   featureIDArr    [1,M] cell of strings, Names of the feature collections
%                   to export. Available values are the subfolder names in 
%                   Cfg.env.paths.featuresRoot.
%   measFilt        struct, Filter that defines a subset of measurements to
%                   load. struct([]) loads all available measurements.
%   MC              struct, Subject and measurement metadata struct
%   Cfg             struct, CTAP configuration structure
%
% Outputs:
%   Saves output as an CSV file in Cfg.env.paths.exportRoot.
%
% Assumptions:
%
% References:
%
% Example:
%   CTAP_export_features2('myResultSet', {'dataset_info2'}, struct([]), MC, Cfg);
%
% Notes:
%
% Based on: export_features_CTAP
% See also: export_features_CTAP
%
% Version History:
% 1.06.2014 Created (Jussi Korpela, FIOH)
% 1.0.2017 Created (Jan Brogger)
%
% Copyright(c) 2017:
% Jan Brogger (jan@brogger.no)

% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Initialize
% Create directory (if needed)
if ~isdir(Cfg.env.paths.exportRoot)
    mkdir(Cfg.env.paths.exportRoot);
end


%% Create an array of source files
myReport(sprintf('Exporting features from: %s', Cfg.env.paths.featuresRoot));
sourcefile_arr = export_features_CTAP2_getfeaturefiles(...
                                        featureIDArr, measFilt, MC, Cfg);

savefile = fullfile(Cfg.env.paths.exportRoot, sprintf('%s.txt',id));

labels = {'subjectnr' 'subject' 'casename', ...
          'feature' 'feature2' 'value'};
format_array = {'%d', '%s', '%s', '%s', '%s', '%020.5f'};

[pathstr, name, saveExt] = fileparts(savefile); %#ok<*ASGLU>

j = 0;
for i=1:numel(sourcefile_arr)
    result = export_features_CTAP2_onefile(sourcefile_arr{i});        
    for k=1:numel(result)
        if ~isempty(result{k})
            j = j +1;
            if j == 1
                % Write header and data
                cell2txtfile(savefile, labels, result{k}, format_array,...
                    'delimiter', '\t',...
                    'writemode', 'wt',...
                    'allownans', 'false');
            else
                % Append
                cell2txtfile(savefile, {}, result{k}, format_array,...
                    'delimiter', '\t',...
                    'writemode', 'at',...
                    'allownans', 'false');
            end
        end
    end

end 
       
end


function sourcefile_arr =...
    export_features_CTAP2_getfeaturefiles(featureIDArr, measFilt, MC, Cfg)

    sourcefile_arr={};
    if isempty(measFilt)
        % Load all measurements available
        for i= 1:length(featureIDArr)
            i_feat = featureIDArr{i};
            i_srcPath = fullfile(Cfg.env.paths.featuresRoot,i_feat);
            i_fileArr = dir(fullfile(i_srcPath, sprintf('*_%s.mat',i_feat)));

            sourcefile_arr = vertcat(sourcefile_arr,...
                        strcat(i_srcPath, filesep, {i_fileArr.name}'));
        end%i    
    else
        % Load all measurement that match measFilt
        MeasurementSub = struct_filter(MC.measurement, measFilt);

        for i= 1:length(featureIDArr)
            i_feat = featureIDArr{i};
            for k = 1:length(MeasurementSub)
                k_file = fullfile(Cfg.env.paths.featuresRoot, i_feat, ...
                         sprintf('%s_%s.mat', MeasurementSub(k).casename,i_feat));

                if exist(k_file, 'file')
                    sourcefile_arr = vertcat(sourcefile_arr, k_file); %#ok<*AGROW>
                end
            end %k
        end%i
    end%if
end


function result = export_features_CTAP2_onefile(sourcefile)
	result = cell(1);
    resultCount = 0;
    [pathstr, filename, ext] = fileparts(sourcefile);
    msg = ['dataexport: Processing file ', [filename,ext], '...'];
    disp(msg);
    
    % Load data
    M = load(sourcefile);    
    % Get the fields of the data that are not part of the CTAP/ATTK data format
    % (i.e. not INFO or SEGMENT)
    thisFileFieldNames = fieldnames(M);    
    thisFileValueFields = thisFileFieldNames(...
        ~(strcmp(thisFileFieldNames, 'INFO') | strcmp(thisFileFieldNames, 'SEGMENT')));    
        
    subjectnr = M.INFO.subjectnr;
    subject = M.INFO.subject;
    casename = M.INFO.casename;
    
    for j=1:length(thisFileValueFields)  
        % Get the fields of the data that are not part of the CTAP/ATTK 
        %data format(i.e. not labels, units, paramters, sublevels)        
        thisStruct = eval(char(strcat('M.' , thisFileValueFields(j))));
        if isa(thisStruct,'double')            
            resultCount = resultCount+1;
            result{resultCount} = {subjectnr, ...
                          subject, ...
                          casename, ...
                          char(thisFileValueFields(j)), ...
                          char(thisFileValueFields(j)), ...
                          thisStruct};
        elseif isstruct(thisStruct)
            thisStructFieldNames = fieldnames(thisStruct);
            thisStructValueFields = ...
                thisStructFieldNames( ...
                ~( ...
                    ismember(thisStructFieldNames, 'labels') | ...
                    ismember(thisStructFieldNames, 'units') | ...
                    ismember(thisStructFieldNames, 'parameters') |...
                    ismember(thisStructFieldNames, 'sublevels') ...
                 ) ...
                );        
           for k=1:length(thisStructValueFields)
               thisStructValueField = thisStructValueFields(k);
               thisStructValueFieldType = eval(char(...
                  strcat('class(M.',thisFileValueFields(j),'.',thisStructValueField,')')...
                ));
              if strcmp(thisStructValueFieldType,'double') || ...
                 strcmp(thisStructValueFieldType,'datetime') || ...
                 strcmp(thisStructValueFieldType,'char')
                 actualValue = eval(char(...
                     strcat('M.',thisFileValueFields(j),'.',thisStructValueField) ...
                 ));
                  %Skip arrays, only do primitives
                  if numel(actualValue)==1
                     if strcmp(thisStructValueFieldType,'datetime')
                         actualValue = datenum(actualValue);
                     end
                     resultCount = resultCount+1;
                     result{resultCount} = {subjectnr, ...
                          subject, ...
                          casename, ...
                          char(thisFileValueFields(j)), ...
                          char(thisStructValueField), ...
                          actualValue};
                  end
              end
           end
        else
            error('Unknown field type');
       end
    end    
        
end