% Batch synthetic data generation for HYDRA
%
% Note:
%   * assumes PROJECT_ROOT to be in workspace, example below:
%   PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra';


%% Setup

FILE_ROOT = mfilename('fullpath');
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'paramsweep_example', 'batch_psweep_datagen')) - 1);
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'batch_psweep_datagen')) - 1);
% CH_ROOT = REPO_ROOT + "/res/chanlocs128_biosemi.elp";

CH_ROOT = REPO_ROOT + "/res/channel_locations.elp";
PARAM = param_sweep_setup(PROJECT_ROOT);


%% Generate data

% first synthetic dataset
 chanlocs = readlocs('chanlocs128_biosemi.elp');
%chanlocs = readlocs('channel_locations.elp');
 param_sweep_sdgen('BCICIV_calib_ds1a.set', chanlocs, PARAM);
% 
% % second synthetic dataset
 %param_sweep_sdgen('B-scalp-EC-Oall.set', chanlocs, PARAM);
% 
% % third synthetic dataset
% param_sweep_sdgen('A-scalp-EO-Zall.set', chanlocs, PARAM);

% real dataset
%param_sweep_sdgen('eeg_recording_1_session_meas.set', chanlocs, PARAM);
