function CTAP_export_features(id, featureIDArr, measFilt, MC, Cfg, varargin)
%CTAP_EXPORT_FEATURES - Export data into sqlite or csv database 
%
% Description:
%   Generates a list of result files based on 'featureIDArr' and
%   'measFilt'. Reads data from these files, formats it and saves the
%   result into a database (or text file). 
%
% Syntax:
%   export_features_CTAP(id, featureIDArr, measFilt, MC, Cfg);
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
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   debug       boolean, run with or without try-catch wrapper
%               default = false
%   overwrite   boolean, if false, check for existing db file and skip instead 
%               of overwriting older file.
%               default = false
%
% Outputs:
%   Saves output as an SQLite database in Cfg.env.paths.exportRoot.
%
% Assumptions:
%
% References:
%
% Example:
%   export_features_CTAP('myResultSet', {'bandpowers'}, struct([]), MC, Cfg);
%
% Notes:
%
% See also: dataexport_sqlite, dataexport_append, CTAP_extract_*
%
% Version History:
% 1.06.2014 Created (Jussi Korpela, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('id', @ischar);
p.addRequired('featureIDArr', @iscell);
p.addRequired('measFilt', @isstruct);
p.addRequired('MC', @isstruct);
p.addRequired('Cfg', @isstruct);

p.addParameter('debug', false, @islogical);
p.addParameter('overwrite', false, @islogical);

p.parse(Cfg, varargin{:});
Arg = p.Results;


%% Initialize
%check whether to continue based on file existence and overwrite flag
savefile = fullfile(Cfg.env.paths.exportRoot, sprintf('%s.sqlite', id));
if exist(savefile, 2) && ~Arg.overwrite
    myReport(sprintf('Overwrite is OFF and %s exists already.%s',...
        savefile, ' Skipping this FEATURE EXPORT'), Cfg.env.logFile);
    return
end
% Create directory (if needed)
if ~isdir(Cfg.env.paths.exportRoot)
    mkdir(Cfg.env.paths.exportRoot);
end
if ~isfield(Cfg, 'export')
    % Metadata variable names to include in the export
    Cfg.export.csegMetaVariableNames = {'timestamp','latency','duration'};
end

if Arg.debug
    sbf_loadNsaveDB()
else
    try
        sbf_loadNsaveDB()
    catch ME,
        myReport(sprintf('CTAP_export_features() failure: %s', ME.message))
        return
    end
end


function sbf_loadNsaveDB()
    %% Create an array of source files
    myReport(sprintf('Exporting features from: %s', Cfg.env.paths.featuresRoot)...
        , Cfg.env.logFile);

    sourcefile_arr={};
    if isempty(measFilt)
        % Load all measurements available
        for i= 1:length(featureIDArr)
            i_feat = featureIDArr{i};
            i_srcPath = fullfile(Cfg.env.paths.featuresRoot, i_feat);
            i_fileArr = dir(fullfile(i_srcPath, sprintf('*_%s.mat', i_feat)));

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
                    sprintf('%s_%s.mat', MeasurementSub(k).casename, i_feat));

                if exist(k_file, 'file')
                    sourcefile_arr = vertcat(sourcefile_arr, k_file); %#ok<*AGROW>
                end
            end %k
        end%i
    end%if


    %% Export everything into DB file: CSV, sqlite

    % Saving to a CSV file is not feasible for large datasets
    %{
    savefile = fullfile(Cfg.env.paths.exportRoot, sprintf('%s.csv',id));   
    [data  labels] = dataexport_append(sourcefile_arr, savefile,'',...
                        'allowNaN', 'yes',...
                        'factorsVariable', 'SEGMENT',...
                        'outputFormat', 'long',...
                        'doubleformat',Cfg.ctap.export_features.doubleFormat,...
                        'intformat', Cfg.ctap.export_features.doubleFormat);
    %}     

    % Saving to an SQLite database is feasible for larger datasets
    dataexport_sqlite(sourcefile_arr, savefile,...
            'cseg_meta_variable_names', Cfg.export.csegMetaVariableNames,...
            'factorsVariable', 'SEGMENT',...
            'outputFormat', 'long');
end

end %CTAP_export_features()