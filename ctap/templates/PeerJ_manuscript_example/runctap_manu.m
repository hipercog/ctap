%% CTAP manuscript analysis batchfile
% As referenced in the first CTAP article:
% Cowley BU, Korpela J, Torniainen J. (2017) Computational testing for automated 
% preprocessing: a Matlab toolbox to enable large scale electroencephalography 
% data processing. PeerJ Computer Science 3:e108 
% https://doi.org/10.7717/peerj-cs.108
% 
% To run this, you need:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%     git clone https://adelorme@bitbucket.org/sccn_eeglab/eeglab.git
%   * CTAP

% Make sure your working directory is the CTAP root i.e. the folder with
% 'ctap' and 'dependencies'.

% Also make sure that EEGLAB and CTAP have been added to your Matlab path. 
% For a script to do this see update_matlab_path_ctap.m at CTAP repository
% root.

% On first run, create synthetic data:
overwrite_syndata = true;
% On subsequent runs, skip creation:
overwrite_syndata = false;

% Runtime options for CTAP:
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Setup
project_dir = fullfile(cd(), 'sccn-clean-20min');
if ~isdir(project_dir), mkdir(project_dir); end;

% Define step sets and their parameters
[Cfg, ctap_args] = cfg_manu(project_dir);


%% Create synthetic data (only if needed)
data_dir_seed = fullfile(cd(),'ctap','data');
data_dir_out = fullfile(Cfg.env.paths.projectRoot,'data','manuscript');
if ( isempty(dir(fullfile(data_dir_out,'*.set'))) || overwrite_syndata)
    % Normally this is run only once to create the data
    generate_synthetic_data_manuscript(data_dir_seed, data_dir_out);
end


%% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(data_dir_out, '*.set');
Cfg.MC = MC;


%% Select measurements to process
clear('Filt')
Filt.subjectnr = 1;
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);


%% Select step sets to process
% There are 8 step sets in this pipe.
% cfg_manu.m sets pipe.runSets by default but the lines below can be used
% to override the default behavior.
% Any stepSet subset can be indexed numerically or logically.
%Cfg.pipe.runSets = {'all'}; %this is the default
%Cfg.pipe.runSets = {Cfg.pipe.stepSets([2,5]).id}; %by position index
Cfg.pipe.runSets = {Cfg.pipe.stepSets(8).id};


%% Assign arguments to the selected functions, perform various checks
Cfg = ctap_auto_config(Cfg, ctap_args);


%% Run the pipe
%%{
tic;
CTAP_pipeline_looper(Cfg,...
                    'debug', STOP_ON_ERROR,...
                    'overwrite', OVERWRITE_OLD_RESULTS);
toc;
%}


%% Export features
%%{
tic;
export_features_CTAP([Cfg.id '_db'], {'bandpowers','PSDindices'},...
                     Filt, Cfg.MC, Cfg);
toc;
%}

%% Cleanup
clear Filt
