function [EEG, Cfg] = CTAP_extract_dataset_info2(EEG, Cfg)
%CTAP_extract_dataset_info2  - extract info about EEG file as features
%
% Description:
%   Saves results into Cfg.env.paths.featuresRoot/dataset_info2.
%
% Syntax:
%   [Cfg] = CTAP_extract_dataset_info2(~, Cfg);
%
% Inputs:
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: CTAP_extract_dataset_info() %
% Copyright(c) 2017 :
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'extract_dataset_info2')
    Arg = joinstruct(Arg, Cfg.ctap.extract_dataset_info2);%override with user params
end

[INFO, SEGMENT] = gather_measurement_metadata(Cfg.subject, Cfg.measurement); %#ok<ASGLU>

dataset_info2 = struct();
dataset_info2.srate = EEG.srate;
dataset_info2.samples = size(EEG.data, 2);
dataset_info2.lengthSeconds = dataset_info2.samples / dataset_info2.srate;
dataset_info2.startDateTime = EEG.startDateTime;
dataset_info2.segments = sum(ismember({EEG.event.type}, 'boundary')) + 1;
dataset_info2.nbchan = EEG.nbchan; %#ok<*STRNU>

savepath = fullfile(Cfg.env.paths.featuresRoot, 'dataset_info2');
if ~isdir(savepath)
    mkdir(savepath); 
end
savename = sprintf('%s_dataset_info2.mat', Cfg.measurement.casename);
save(fullfile(savepath,savename), 'INFO', 'SEGMENT', 'dataset_info2');


%% ERROR/REPORT
Cfg.ctap.extract_dataset_info2 = Arg;
msg = myReport(sprintf('Dataset info 2 stored for measurement %s.',...
    EEG.CTAP.measurement.casename), Cfg.env.logFile);
%create an entry to the history struct, with 
%   1. informative message, 
%   2. function filename
%   3. %the complete parameter set from the function call, for reference
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

