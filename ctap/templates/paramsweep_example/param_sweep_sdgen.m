% Generate synthetic data 

% seedEEG = pop_loadset(seed_fname, seed_srcdir);
seedEEG = ctapeeg_load_data(fullfile(seed_srcdir, seed_fname));

stream = RandStream.getGlobalStream;
reset(stream, 42);


[EEGclean, EEGart, EEG] = ...
    generate_synthetic_data_paramsweep(seedEEG, chanlocs,...
                                SYNDATA,...
                                EEG_LENGTH, SRATE, MODEL_ORDER,...
                                BLINK_N, EMG_N, WRECK_N,...
                                WRECK_MULTIPLIER_ARR);

pop_saveset(EEGclean,...
            'filepath', syndata_dir, ...
            'filename','syndata_clean.set');
pop_saveset(EEGart,...
            'filepath', syndata_dir, ...
            'filename','syndata_artifacts.set');
pop_saveset(EEG,...
            'filepath', syndata_dir, ...
            'filename','syndata.set');        
        
%{
    eeg_eventtypes(EEGart);


    idx = find(isnan(seedEEG.data(:,1)))
    {seedEEG.chanlocs(idx).labels}

    idx = find(isnan(EEG.data(:,1)))
    {EEG.chanlocs(idx).labels}


    idx = find(isnan(EEGclean.data(:,1)))
    {EEGclean.chanlocs(idx).labels}
%}