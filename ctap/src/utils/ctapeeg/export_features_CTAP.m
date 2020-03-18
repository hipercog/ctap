function export_features_CTAP(id, featureIDArr, MC, Cfg, varargin)
%EXPORT_FEATURES_CTAP - Export data into sqlite or csv database 
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
%   MC              struct, Subject and measurement metadata struct
%   Cfg             struct, CTAP configuration structure
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   srcFilt     cell string array, directory names to export features from
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
% p.addRequired('measFilt', @isstruct);
p.addRequired('MC', @isstruct);
p.addRequired('Cfg', @isstruct);

p.addParameter('srcFilt', {}, @iscell);
p.addParameter('debug', false, @islogical);
p.addParameter('overwrite', false, @islogical);

p.parse(id, featureIDArr, MC, Cfg, varargin{:});
Arg = p.Results;


%% Initialize
% Create directory (if needed)
if ~isdir(Cfg.env.paths.exportRoot)
    mkdir(Cfg.env.paths.exportRoot);
end
if ~isfield(Cfg, 'export')
    % Metadata variable names to include in the export
    Cfg.export.csegMetaVariableNames = {'timestamp', 'latency', 'duration'};
end


%% Create an array of source files
% get all .mat files, their unique directories, and featuresRoot-relative paths
if verLessThan('matlab', '9.1.0') %< 'r2016b'
    feats = getAllFiles(Cfg.env.paths.featuresRoot, 'FileFilter', '\.mat$');
    [ft_paths, ft_files, ~] = cellfun(@fileparts, feats, 'UniformOutput', false);
    srcPaths = unique(ft_paths);
    %If save point filter is specified, export only those paths that match
    if ~isempty(Arg.srcFilt)
        [~, srcPts, ~] = cellfun(@fileparts, srcPaths, 'UniformOutput', false);
        srcPaths = srcPaths(ismember(srcPts, Arg.srcFilt));
    end
    if isempty(srcPaths)
        return
    end
    % srcPts are the remainder paths from featuresRoot to mat file locations
    srcPts = cellfun(@(x) x(length(Cfg.env.paths.featuresRoot) + 2:end)...
        , srcPaths, 'UniformOutput', false);
    myReport(['Feature file dirs:' srcPaths(:)'], Cfg.env.logFile, sprintf('\n'));

    %Loop over requested features
    for fti = 1:length(featureIDArr)
        i_feat = featureIDArr{fti};%work on a per-feature basis
        %subset to sources matching this feature
        ft_idx = ~cellfun(@isempty, cellfun(@(x) x==1, strfind(srcPts, i_feat)...
            , 'UniformOutput', false));
        src_pts_sub = srcPts(ft_idx);
        srcPath_sub = srcPaths(ft_idx);

        %Loop over source points (dirs containing .mat files for i_feat)
        for pt = 1:numel(src_pts_sub)
            %check whether to continue based on file existence and overwrite flag
            savefile = fullfile(Cfg.env.paths.exportRoot, sprintf('%s--%s.sqlite'...
                , id, strrep(src_pts_sub{pt}, filesep, '--')));
            if exist(savefile, 'file') && ~Arg.overwrite
                myReport(sprintf('Overwrite is OFF and %s exists already.%s',...
                    savefile, ' Skipping this FEATURE EXPORT'), Cfg.env.logFile);
                continue
            end
            myReport(sprintf('Exporting ''%s'' features from:\n%s', i_feat...
                , srcPath_sub{pt}), Cfg.env.logFile);

            %Get an array of source files
            idx = ismember(ft_paths, srcPath_sub{pt});
            src_file_arr = strcat(ft_paths(idx), filesep, ft_files(idx));

%             if ~isempty(measFilt)
%                 % Remove all measurements that don't match measFilt
%                 meas_sub = struct_filter(MC.measurement, measFilt);
%                 sfarr_meas_sub_idx = false(1, numel(src_file_arr));
%                 for m = 1:numel(meas_sub)
%                     tmp = ~cell2mat(cellfun(@isempty, strfind(src_file_arr...
%                         , meas_sub(m).casename), 'UniformOutput', false));
%                     sfarr_meas_sub_idx = sfarr_meas_sub_idx | tmp(:)';
%                 end
%                 src_file_arr(~sfarr_meas_sub_idx) = [];
%             end%if
            %% Export everything into DB file: CSV, sqlite
            sbf_export_data
        end
    end%i

%with r2016b we get nice new functions that search cell string arrays
else
    feats = dir(fullfile(Cfg.env.paths.featuresRoot, '**', '*.mat'));
    ft_paths = {feats.folder};
    ft_files = {feats.name};
    srcPaths = unique(ft_paths);
    % Filter on feature save points passed from pipe
    if ~isempty(Arg.srcFilt)
        srcPaths = srcPaths(endsWith(srcPaths, Arg.srcFilt)); 
    end
    if isempty(srcPaths)
        return
    end
    % srcPts are the remainder paths from featuresRoot to mat file locations
    srcPts = cellfun(@(x) x(length(Cfg.env.paths.featuresRoot) + 2:end)...
        , srcPaths, 'UniformOutput', false);
    myReport(['Feature files are at:' srcPaths(:)'], Cfg.env.logFile, sprintf('\n'));

    %Loop over requested features
    for fti = 1:length(featureIDArr)
        i_feat = featureIDArr{fti};%work on a per-feature basis
        %subset to sources matching this feature
        ft_idx = startsWith(srcPts, i_feat);
        src_pts_sub = srcPts(ft_idx);
        srcPath_sub = srcPaths(ft_idx);

        %Loop over source points (dirs containing .mat files for i_feat)
        for pt = 1:numel(src_pts_sub)
            %check whether to continue based on file existence and overwrite flag
            savefile = fullfile(Cfg.env.paths.exportRoot, sprintf('%s--%s.sqlite'...
                , id, strrep(src_pts_sub{pt}, filesep, '--')));
            if exist(savefile, 'file') && ~Arg.overwrite
                myReport(sprintf('Overwrite is OFF and %s exists already.%s',...
                    savefile, ' Skipping this FEATURE EXPORT'), Cfg.env.logFile);
                continue
            end
            myReport(sprintf('Exporting ''%s'' features from:\n%s', i_feat...
                , srcPath_sub{pt}), Cfg.env.logFile);

            %Get an array of source files
            idx = ismember(ft_paths, srcPath_sub{pt});
            src_file_arr = strcat(ft_paths(idx), filesep, ft_files(idx));

%             if ~isempty(measFilt)
%                 % Remove all measurements that don't match measFilt
%                 meas_sub = struct_filter(MC.measurement, measFilt);
%                 src_file_arr(~contains(src_file_arr, {meas_sub.casename})) = [];
%             end%if
            %% Export everything into DB file: CSV, sqlite
            sbf_export_data
        end
    end%fti
end%if

    %% SUB-FUNCTION TO HANDLE DATA EXPORT IN CRASH-PROOF MANNER
    function sbf_export_data()
        % Saving to an SQLite database is feasible for larger datasets
        if Arg.debug
            dataexport_sqlite(src_file_arr, savefile,...
            'cseg_meta_variable_names', Cfg.export.csegMetaVariableNames,...
            'factorsVariable', 'SEGMENT',...
            'outputFormat', 'long');
        else
            try
                dataexport_sqlite(src_file_arr, savefile,...
                'cseg_meta_variable_names', Cfg.export.csegMetaVariableNames,...
                'factorsVariable', 'SEGMENT',...
                'outputFormat', 'long');
            catch ME,
                myReport(sprintf('%s() failure: %s', mfilename, ME.message))
            end
        end
    end%sbf_export_data()

end%export_features_CTAP()