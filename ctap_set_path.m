% An example script to set up Matlab path for CTAP use
%
% Note: It is very important to add CTAP dependencies and EEGLAB to the
% _end_ of Matlab path to avoid unnecessary function name collissions.

% Add EEGLAB
% eeglab_path = '/home/your/path/to/EEGLAB/eeglab14_1_1b';
% addpath(genpath(eeglab_path), '-end');

% Add CTAP
[ctap_path, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(ctap_path, 'ctap')), '-end');
addpath(genpath(fullfile(ctap_path, 'dependencies')), '-end');