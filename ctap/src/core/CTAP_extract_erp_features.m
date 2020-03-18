function [EEG, Cfg] = CTAP_extract_erp_features(EEG, Cfg)
%CTAP_extract_erp_features - Extract ERP features from epoched data
%
% Description:
%   Saves results into fullfile(Cfg.env.paths.featuresRoot, 'ERP').
%
% Syntax:
%   [EEG, Cfg] = CTAP_extract_erp_features(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.extract_erp_features:
%       .searchLimits   (k,2) numeric, latencies in ms
%       .erpDirections  (1,k) cellstring of {'pos','neg'}, ERP peak directions
%       .erpLabels      (1,k) cellstring, ERP identifier strings
%   All these fields are mandatory!
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes:
%   Use export_features_CTAP() to export extracted feature values into CSV
%   or database.
%
% See also: ctapeeg_erp_features()
%
% Copyright(c) 2016 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments

% All these are required!
Arg.searchLimits = []; %(k,2) numeric, latencies in ms
Arg.erpDirections = {}; %(1,k) cellstring of {'pos','neg'}, ERP peak directions
Arg.erpLabels = {}; %(1,k) cellstring, ERP identifier strings

% Override defaults with user parameters
if isfield(Cfg.ctap, 'extract_erp_features')
    Arg = joinstruct(Arg, Cfg.ctap.extract_erp_features); %override w user params
end


%% Core

% Gather measurement metadata (subject and measurement specific information)
INFO = gather_measurement_metadata(Cfg.subject, Cfg.measurement); %#ok<*NASGU>

%
[SEGMENT, ERP, ERPAREA] = ctapeeg_erp_features(EEG, Arg.searchLimits,...
                                               Arg.erpDirections, Arg.erpLabels, {});


%% Save
%featID = 'ERP';
%savepath = fullfile(Cfg.env.paths.featuresRoot,featID);
savepath = get_savepath(Cfg, mfilename, 'features');
savename = sprintf('%s.mat', Cfg.measurement.casename);
save(fullfile(savepath,savename), 'INFO', 'SEGMENT', 'ERP', 'ERPAREA');


%% ERROR/REPORT
Cfg.ctap.extract_erp_features = Arg;

msg = myReport(sprintf('Extracted ERP features.'), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
