function [EEGclean, EEGart, EEG] =...
    generate_synthetic_data_paramsweep( seedEEG, ...
                                        chanlocs,...
                                        SYNDATA,...
                                        dlen, ...
                                        srate, ...
                                        model_order,...
                                        n_blinks, ...
                                        n_emg, ...
                                        n_wrecks,...
                                        wreck_multiplier_arr)

% debug:
% EEG_LEN_MIN = 5;
% CH_FILE = 'chanlocs128_biosemi.elp';
% srate = 256;
% dlen = 60 * EEG_LEN_MIN; %in seconds ? 
% model_order = 20;
% n_blinks = 10 * EEG_LEN_MIN;
% n_emg = 5 * EEG_LEN_MIN;
% n_wrecks = floor(0.05 * 134); %10% of channels
% seedEEG = pop_loadset(files(k).name, DATADIR);
% chanlocs = readlocs(CH_FILE);

%% Generate clean synthetic data, or read clean real data
if SYNDATA
    EEGclean = eeglab_seedgen_synthetic_data(seedEEG, chanlocs,...
                                            dlen, srate, model_order);
else
    EEGclean = seedEEG;
    clear seedEEG;
end
EEGclean = ctaptest_add_ctap(EEGclean);


%% Add artifacts to clean data
[EEG, blinks, myo, wrecks] = ctaptest_add_artifacts(EEGclean...
                           , n_blinks, n_emg, n_wrecks...
                           , 'wreckMultiplierArr', wreck_multiplier_arr...
                           , 'randomAmountArtifacts', false);


%% Extract artifact variation
EEGart = EEG;
EEGart.data = EEG.data - EEGclean.data;
EEGart.blinks = blinks;
EEGart.myo = myo;
EEGart.wrecks = wrecks;

% if sum(strcmp({EEG.chanlocs.labels}, {EEGclean.chanlocs.labels}) == 0) == 0
%     EEGart = EEG;
%     art_channels = {EEGart.chanlocs.labels};
% 
%     EEGart.data = EEG.data - EEGclean.data;
%     %ctap_eegplot(EEGart);
% else 
%     keyboard;
% end


%% Augment artifact information
wrecked_channel_inds = [];
wrecked_channel_multipliers = [];
wrecked_channel_direction = [];
wrecked_channel_factor = [];

for i = 1:numel(EEG.CTAP.artifact.variance)
    clen = numel(EEG.CTAP.artifact.variance(i).channel_idx);
    wrecked_channel_inds = ...
        horzcat(wrecked_channel_inds, ...
                [EEG.CTAP.artifact.variance(i).channel_idx]);
    wrecked_channel_multipliers = ...
        horzcat(wrecked_channel_multipliers, ...
                repmat(EEG.CTAP.artifact.variance(i).multiplier,1,clen) );
    
    if (EEG.CTAP.artifact.variance(i).multiplier < 1)
        cdir = -1;
        cbad = 1/EEG.CTAP.artifact.variance(i).multiplier;
    else 
        cdir = 1;
        cbad = EEG.CTAP.artifact.variance(i).multiplier;    
    end
    wrecked_channel_direction = ...
        horzcat(wrecked_channel_direction, repmat(cdir, 1, clen) );
            
    wrecked_channel_factor = ...
        horzcat(wrecked_channel_factor, repmat(cbad, 1, clen) );
end

tmp = table({EEG.chanlocs(wrecked_channel_inds).labels}', ...
            wrecked_channel_inds', wrecked_channel_multipliers',...
            wrecked_channel_factor', wrecked_channel_direction',...
    'VariableNames', {'name','idx','multiplier','factor','direction'});
tmp = sortrows(tmp, 'factor', 'descend');
EEG.CTAP.artifact.variance_table = tmp;
                

%% Add artifact events to EEGart
% blink events
n_bl = length(EEGart.CTAP.artifact.blink);
bl_win_s = [EEGart.CTAP.artifact.blink(:).time_window_s];
bl_start_s = bl_win_s(1:2:2*n_bl);
bl_end_s = bl_win_s(2:2:2*n_bl);
blink_event = eeglab_create_event(bl_start_s * EEGart.srate,...
                      'sa_blink',...
                      'duration', num2cell((bl_end_s - bl_start_s) * EEGart.srate),...
                      'nid', num2cell(1:n_bl));

% EMG events
n_emg = length(EEGart.CTAP.artifact.EMG);
emg_win_smp = [EEGart.CTAP.artifact.EMG(:).time_window_smp];
emg_start_smp = emg_win_smp(1:2:2*n_emg);
emg_end_smp = emg_win_smp(2:2:2*n_emg);
emg_event = eeglab_create_event(emg_start_smp,...
                      'sa_EMG',...
                      'duration', num2cell(emg_end_smp - emg_start_smp),...
                      'nid', num2cell(1:n_emg));
emg_event_end = eeglab_create_event(emg_end_smp,...
                      'sa_EMG_end');

EEGart.event = eeglab_merge_event_tables(blink_event, emg_event,...
                                      'ignoreDiscontinuousTime');
EEGart.event = eeglab_merge_event_tables(EEGart.event, emg_event_end,...
                                      'ignoreDiscontinuousTime');
                                  
end