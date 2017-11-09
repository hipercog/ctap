% Batch synthetic data generation for HYDRA
%
% Note:
%   * assumes PROJECT_ROOT to be in workspace, example below:
%   PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra';


%% Setup
PARAM = param_sweep_setup(PROJECT_ROOT);


%% Generate data

% first synthetic dataset
chanlocs = readlocs('chanlocs128_biosemi.elp');
param_sweep_sdgen('BCICIV_calib_ds1a.set', chanlocs, PARAM);

% second synthetic dataset
param_sweep_sdgen('B-scalp-EC-Oall.set', chanlocs, PARAM);

% third synthetic dataset
param_sweep_sdgen('A-scalp-EO-Zall.set', chanlocs, PARAM);

% real dataset

