function PARAM = param_sweep_setup(projectRoot)
% PARAM_SWEEP_SETUP - Create setup for synthetic data based parameter sweeps
%
% Location of project root, very user specific
%projectRoot = '/home/ben/Benslab/CTAP/hydra';
%projectRoot = '/home/jkor/work_local/projects/ctap/ctapres_hydra';
%projectRoot = '/home/jussi/work_local/projects/ctap/ctapres_hydra';
%projectRoot = '/ukko/projects/ReKnow/HYDRA/CTAP'


%% Move to batch scripts
%{
SYNDATA = true;
RECOMPUTE_SYNDATA = false;
RERUN_PREPRO = false;
RERUN_SWEEP = false;
STOP_ON_ERROR = true;
seed_fname = 'BCICIV_calib_ds1a.set';

% note: branch is set later at test_param_sweep_*() functions

%% CTAP config (todo: specific for a certain seed data?)
CH_FILE = 'chanlocs128_biosemi.elp';

ctapRoot = PARAM.projectRoot;
Cfg.env.paths = cfg_create_paths(ctapRoot, branch_name, '');
Cfg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Cfg.grfx.on = false;
%}

%% Directories

% Desired project root folder
PARAM.path.projectRoot = projectRoot;

% Seed data source folder (from ctap -repo)
% This one assumes that working directory is ctap_dev repo root:
PARAM.path.seedDataSrc = fullfile(cd(),'/ctap/data/clean_seed');

% Synthetic dataset storage folder
PARAM.path.synDataRoot = fullfile(PARAM.path.projectRoot, 'syndata');

% Create directories
dirnames = fieldnames(PARAM.path);
for i=1:numel(dirnames)
    mkdir(PARAM.path.(dirnames{i}));
end


%% Synthetic data generation

% Data generation parameters
big_data = true;
if big_data
    PARAM.syndata.EEG_LEN_MIN = 20;
    PARAM.syndata.SRATE = 512;
else  
    PARAM.syndata.EEG_LEN_MIN = 5; %#ok<UNRCH>
    PARAM.syndata.SRATE = 256;
end

PARAM.syndata.EEG_LENGTH = 60 * PARAM.syndata.EEG_LEN_MIN; %in seconds ? 
PARAM.syndata.MODEL_ORDER = 20;
PARAM.syndata.BLINK_N = 10 * PARAM.syndata.EEG_LEN_MIN;
% Provide BLINK_N as a 1x2 vector and the blinks are generated in two
% distinct classes: Slower-BiggerAmp and Faster-SmallerAmp
% BLINK_N = repmat(5 * EEG_LEN_MIN, [1 2]); %here using 1:1 ratio
PARAM.syndata.EMG_N = 5 * PARAM.syndata.EEG_LEN_MIN;
% Provide EMG_N as a 1x2 vector and the EMG bursts are generated in two distinct
% classes: shortTime-slowFreq-largeAmp (like jaw clenching) and long-fast-small
% EMG_N = [3 * EEG_LEN_MIN, 2 * EEG_LEN_MIN];
PARAM.syndata.WRECK_N = 10;
PARAM.syndata.WRECK_MULTIPLIER_ARR = [2 1/2 3 1/3 4 1/4 5 1/5 6 1/6];
%chmatch = ismember({chanlocs.labels}, 'A4');
%chanlocs(chmatch)

end
