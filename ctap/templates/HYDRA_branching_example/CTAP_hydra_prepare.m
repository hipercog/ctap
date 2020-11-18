function [EEG,Cfg] = CTAP_hydra_prepare(EEG, Cfg)

if ~Cfg.HYDRA.ifapply
    return
end

%% Generate synthetic data
PARAM = Cfg.HYDRA.PARAM;
CH_FILE = Cfg.HYDRA.chanloc;
chanlocs = readlocs(CH_FILE);
FULL_CLEAN_SEED = Cfg.HYDRA.FULL_CLEAN_SEED;
OVERWRITE_SYNDATA = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

% only generating synthetic data when applying HYDRA
if Cfg.HYDRA.provide_seed_timerange
    % Extracting clean seed data according to the time range provided
    seedEEG = pop_select(EEG,'time', Cfg.HYDRA.cleanseed_timerange);
    
else
    % with a provided seed data segment extract from test data
    % set CTAP Cfg
    BRANCH_NAME = 'CTAP_hydra_prepare';
    Arg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
    Arg.eeg.chanlocs = CH_FILE;
    Arg.eeg.reference = Cfg.eeg.reference;
    Arg.eeg.veogChannelNames = Cfg.eeg.veogChannelNames; %'C17' has highest blink amplitudes
    Arg.eeg.heogChannelNames = Cfg.eeg.heogChannelNames;
    Arg.grfx.on = false;
    
    % Create measurement config (MC) based on folder
    % Measurement config based on synthetic source files
    file_arr = {Cfg.HYDRA.seed_fname};
    file_arr = cellfun(@(x) fullfile(PARAM.path.seedDataSrc, x), file_arr, 'Unif', false);
    MC = filearr2measconf(file_arr);
    Arg.MC = MC;
    
    % set pipes 
    essential_prepipes = {{@CTAP_load_data}; {@CTAP_fir_filter}; {@CTAP_filter_design}; {@CTAP_fir_notchfilter};...
        {@CTAP_normalize_data}; {@CTAP_reref_data}; {CTAP_resample_data}; {@CTAP_load_chanlocs}};
    pipes = {};
    for i = 1:numel(Cfg.HYDRA.funH.a1)
        t = Cfg.HYDRA.funH.a1(i);
        if any(cellfun(@isequal, essential_prepipes, repmat({t}, size(essential_prepipes))))
            pipes{end+1} = t;
        end
    end
    pipes = vertcat(pipes{:});
    clear Pipe;
    
    i = 1;
    Pipe(i).funH = pipes;
    Pipe(i).id = [num2str(i) '_loaddata'];
    
    PipeParams = Cfg.HYDRA.ctapArgs.a1;
    Arg.pipe.runSets = {'all'};
    Arg.pipe.stepSets = Pipe;
    Arg = ctap_auto_config(Arg, PipeParams);
    
    % run pipeline looper
    Arg.pipe.runMeasurements = {Arg.MC.measurement.casename};
    if (isempty(dir(fullfile(Arg.env.paths.analysisRoot, '1_loaddata'))))
        CTAP_pipeline_looper(Arg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
    end
    k_id = Arg.MC.measurement(1).casename;
    inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
    infile = sprintf('%s.set', k_id);
    
    seedEEG = pop_loadset(infile, inpath);
end

% synthetic dataset
pattern = "CTAP_detect_";
currentp = strcat('a',num2str(Cfg.HYDRA.currentp));
for i = 1:numel(Cfg.HYDRA.funH.(currentp))
    if contains(char(Cfg.HYDRA.funH.(currentp){i}), pattern)
        detection_method = split(char(Cfg.HYDRA.funH.(currentp){i}),"CTAP_detect_");
        detection_method = detection_method{2};
    end
end

switch detection_method
    case "bad_segments"
        PARAM.syndata.WRECK_N = 0;
        PARAM.syndata.BLINK_N = 0;
        sd_name = strcat(Cfg.measurement.subject,'_bad_segments');
    case "bad_channels"
        PARAM.syndata.BLINK_N = 0;
        PARAM.syndata.EMG_N = 0;
        sd_name = strcat(Cfg.measurement.subject,'_bad_channels');
        
    case "bad_comps"
        PARAM.syndata.EMG_N = 0;
        PARAM.syndata.WRECK_N = 0;
        sd_name = strcat(Cfg.measurement.subject,'_bad_comps');
        
end


if OVERWRITE_SYNDATA
    [EEGclean, EEGart, EEGSynthetic] = ...
        generate_synthetic_data_paramsweep(seedEEG,...
        chanlocs,...
        ~FULL_CLEAN_SEED,...
        PARAM.syndata.EEG_LENGTH,...
        PARAM.syndata.SRATE,...
        PARAM.syndata.MODEL_ORDER,...
        PARAM.syndata.BLINK_N,...
        PARAM.syndata.EMG_N,...
        PARAM.syndata.WRECK_N,...
        PARAM.syndata.WRECK_MULTIPLIER_ARR);
    % save data
    sd_factorized_subdir = fullfile(PARAM.path.synDataRoot, sd_name);
    mkdir(sd_factorized_subdir);
    
    pop_saveset(EEGclean,...
        'filepath', sd_factorized_subdir,...
        'filename', sprintf('%s_syndata_clean.set', sd_name));
    pop_saveset(EEGart,...
        'filepath', sd_factorized_subdir, ...
        'filename', sprintf('%s_syndata_artifacts.set', sd_name));
    pop_saveset(EEGSynthetic,...
        'filepath', PARAM.path.synDataRoot, ...
        'filename', sprintf('%s_syndata.set', sd_name));
end

msg = myReport(sprintf('HYDRA synthetic data preparation done.')...
    , Cfg.env.logFile);
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg);


end

