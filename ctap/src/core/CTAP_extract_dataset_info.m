function [EEG, Cfg] = CTAP_extract_dataset_info(EEG, Cfg)
%CTAP_extract_dataset_info
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_extract_dataset_info(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct should be updated with parameter values
%                       actually used
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
%Arg.var = 'default';
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'extract_dataset_info')
    Arg = joinstruct(Arg, Cfg.ctap.extract_dataset_info);%override with user params
end


%% CORE Call the desired core function. The default is hard-coded, but if
%   the author wants, he can set the wrapper to listen for a core function
%   defined in the pipeline as a handle alongside the function parameters
%   which will replace the default. Thus users can choose to use the
%   wrapper layer but not the core layer (not recommended, unstable).    
outdir = get_savepath(Cfg, mfilename, 'qc');

diary_file = fullfile(outdir,...
  sprintf('%s_dataset_info.txt', EEG.CTAP.measurement.casename) );
if exist(diary_file, 'file')
    delete(diary_file); %remove file since diary appends
end

diary(diary_file);

eeg_eventtypes(EEG);

diary off;


%% ERROR/REPORT
%... the complete parameter set from the function call ...
Cfg.ctap.extract_dataset_info = Arg;
%log outcome to console and to log file
msg = myReport(sprintf('Dataset info stored for measurement %s.',...
    EEG.CTAP.measurement.casename), Cfg.env.logFile);
%create an entry to the history struct, with 
%   1. informative message, 
%   2. function filename
%   3. %the complete parameter set from the function call, for reference
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
