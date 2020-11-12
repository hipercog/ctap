function [EEG,Cfg] = CTAP_hydra_prepare(EEG, Cfg)

if ~Cfg.HYDRA.ifapply
    return
end

%% Generate synthetic data
PARAM = Cfg.HYDRA.PARAM;
CH_FILE = Cfg.HYDRA.chanloc;
chanlocs = readlocs(CH_FILE);
OVERWRITE_SYNDATA = true;
FULL_CLEAN_SEED = Cfg.HYDRA.FULL_CLEAN_SEED;
% only generating synthetic data when applying HYDRA
if Cfg.HYDRA.cleanseed_timerange
    % Extracting clean seed data according to the time range provided
    seedEEG = pop_select(EEG,'time', Cfg.HYDRA.cleanseed_timerange);
    
else
    %with a provided seed data segment extract from test data
    sd_file = fullfile(PARAM.path.seedDataSrc, Cfg.HYDRA.seed_fname);
    seedEEG = ctapeeg_load_data(sd_file);
    
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

