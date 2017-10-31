% Generate synthetic data
% Note: cannot be called directly. Called as part of
% test_param_sweep_sdgen_*()

% seedEEG = pop_loadset(seed_fname, seed_srcdir);
sd_file = fullfile(seed_srcdir, seed_fname);
[sd_path, sd_name] = fileparts(sd_file);
seedEEG = ctapeeg_load_data(sd_file);


stream = RandStream.getGlobalStream;
reset(stream, 42);


[EEGclean, EEGart, EEG] = ...
    generate_synthetic_data_paramsweep(seedEEG, chanlocs,...
                                SYNDATA,...
                                EEG_LENGTH, SRATE, MODEL_ORDER,...
                                BLINK_N, EMG_N, WRECK_N,...
                                WRECK_MULTIPLIER_ARR);

% save data
sd_factorized_subdir = fullfile(syndata_dir, sd_name);
mkdir(sd_factorized_subdir);

pop_saveset(EEGclean,...
            'filepath', sd_factorized_subdir, ...
            'filename', sprintf('%s_syndata_clean.set', sd_name));
pop_saveset(EEGart,...
            'filepath', sd_factorized_subdir, ...
            'filename', sprintf('%s_syndata_artifacts.set', sd_name));
pop_saveset(EEG,...
            'filepath', syndata_dir, ...
            'filename', sprintf('%s_syndata.set', sd_name));        
        
%{
    eeg_eventtypes(EEGart);


    idx = find(isnan(seedEEG.data(:,1)))
    {seedEEG.chanlocs(idx).labels}

    idx = find(isnan(EEG.data(:,1)))
    {EEG.chanlocs(idx).labels}


    idx = find(isnan(EEGclean.data(:,1)))
    {EEGclean.chanlocs(idx).labels}
%}