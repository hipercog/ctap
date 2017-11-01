% A generic (batch) script to:
%   1. generate synthetic data
%   2. preprocess the data 
%   3. run a parameter sweep pipe on the data
%   4. analyze results

%% Setup
%projectRoot = fullfile(tempdir(),'hydra');
projectRoot = '/home/jkor/work_local/projects/ctap/ctapres_hydra';

ctapRoot = projectRoot;
Cfg.env.paths = cfg_create_paths(ctapRoot, 'ctap_prepro', '');

% what to run:
run_datagen = true; % todo: not working anymore
run_prepro = true; %takes a long time due to ICA
run_sweep = true;
sweep_resave = false;
sweep_reload = false; %large files, prevent unnecessary loads
run_analyze = true;


%--------------------------------------------------------------------------
% Data generation options
%seed_srcdir = fullfile(projectRoot,'data','seed_data'); %from param_sweep_setup.m
srcname = 'BCICIV_calib_ds1a.set';
%syndata_dir = fullfile(projectRoot,'data','syn_data'); %from param_sweep_setup.m
%mkdir(syndata_dir);

EEG_LEN_MIN = 5;
CH_FILE = 'chanlocs128_biosemi.elp';
SRATE = 256;
EEG_LENGTH = 60 * EEG_LEN_MIN; %in seconds ? 
MODEL_ORDER = 20;
%todo: these are some kind of maxima, how?
BLINK_N = 10 * EEG_LEN_MIN;
EMG_N = 5 * EEG_LEN_MIN;
WRECK_N = 10;
WRECK_MULTIPLIER_ARR = [2 1/2 3 1/3 4 1/4 5 1/5 6 1/6];


%--------------------------------------------------------------------------
% prepro options
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

clear Pipe;
i = 1; 
Pipe(i).funH = {@CTAP_load_data,...
                @CTAP_blink2event,...
                @CTAP_generate_cseg}; 
Pipe(i).id = [num2str(i) '_loaddata'];

i = i+1; 
Pipe(i).funH = {@CTAP_run_ica}; 
Pipe(i).id = [num2str(i) '_ICA'];

i = i+1; 
Pipe(i).funH = {@CTAP_blink2event}; 
Pipe(i).id = [num2str(i) '_tmp'];


PipeParams.run_ica.method = 'fastica';
PipeParams.run_ica.overwrite = true;
PipeParams.run_ica.channels = {'EEG' 'EOG'};
PipeParams.detect_bad_comps.method = 'blink_template';


%--------------------------------------------------------------------------
% sweep options
sweepresdir = fullfile(projectRoot, 'sweep_results','channels');
mkdir(sweepresdir);

infile_subdir = '2_ICA';

i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_channels,... %detect blink related ICs
                    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_blink_correction'];

SWPipeParams.detect_bad_channels.method = 'variance';

SweepParams.funName = 'CTAP_detect_bad_channels';
SweepParams.paramName = 'bounds';
SweepParams.values = num2cell(1.5:0.1:7);


%--------------------------------------------------------------------------
% config Cfg
Cfg.eeg.chanlocs = CH_FILE;
%Channels = readlocs(Cfg.eeg.chanlocs);
Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Cfg.grfx.on = false;

Cfg.pipe.stepSets = Pipe;
Cfg.pipe.runSets = {'all'};
%Cfg.pipe.runSets = {Cfg.pipe.stepSets(3).id}; %/3_tmp/

Cfg = ctap_auto_config(Cfg, PipeParams);
%todo: cannot use this since it warns about stuff that are not needed here
%AND stops execution.



%% Generate synthetic data
if run_datagen

    seedEEG = pop_loadset(srcname, seed_srcdir);
    chanlocs = readlocs(CH_FILE);
    
    stream = RandStream.getGlobalStream;
    reset(stream, 42);
    [EEGclean, EEGart, EEG] = ...
        generate_synthetic_data_paramsweep(seedEEG, chanlocs, true,...
                                    EEG_LENGTH, SRATE, MODEL_ORDER,...
                                    BLINK_N, EMG_N, WRECK_N,...
                                    WRECK_MULTIPLIER_ARR);
                                
    % save data for fast loading
    pop_saveset(EEGclean,...
                'filepath', syndata_dir, ...
                'filename','syndata_clean.set');
    pop_saveset(EEGart,...
                'filepath', syndata_dir, ...
                'filename','syndata_artifacts.set');
    pop_saveset(EEG,...
                'filepath', syndata_dir, ...
                'filename','syndata.set');
else
    
    % just load the data
    EEGclean = pop_loadset('syndata_clean.set', syndata_dir);
    EEGart = pop_loadset('syndata_artifacts.set', syndata_dir);
    EEG = pop_loadset('syndata.set', syndata_dir);
end


%% Run preprocessing pipe

if run_prepro
    % Create measurement config (MC) based on folder
    % Measurement config based on synthetic source files
    MC = path2measconf(syndata_dir, '*.set');
    Cfg.MC = MC;

    clear('Filt');
    Filt.subjectnr = 1;
    Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);

    CTAP_pipeline_looper(Cfg,...
                        'debug', STOP_ON_ERROR,...
                        'overwrite', OVERWRITE_OLD_RESULTS);
end

                
%% Sweep
% Note: This step does sweeping ONLY, preprocess using some other means
if run_sweep
    inpath = fullfile(Cfg.env.paths.analysisRoot, infile_subdir);
    infile = 'syndata_session_meas.set';
    EEGprepro = pop_loadset(infile, inpath);

    [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Cfg, ...
                                              SweepParams);
    
    if sweep_resave
        save(fullfile(sweepresdir,'sweep_SWEEG.mat'), 'SWEEG', '-v7.3');
        % need to use -v7.3 since file becomes over 2Gb in size
        save(fullfile(sweepresdir,'sweep_params.mat'), 'PARAMS');
    end
  
else
    if sweep_reload
        load(fullfile(sweepresdir,'sweep_SWEEG.mat'), 'SWEEG');
        load(fullfile(sweepresdir,'sweep_params.mat'), 'PARAMS');
    end
    
end
          

%% Analyze
if run_analyze
    results = psweep_analyze_channels(EEGclean, EEGart, EEG, EEGprepro,...
                                      SWEEG, SweepParams, sweepresdir);
end

