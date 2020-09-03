function generate_synthetic_data_demo(SRCDIR, OUTDIR)

globalStream = RandStream.getGlobalStream;
reset(globalStream);

if ~isdir(OUTDIR), mkdir(OUTDIR); end;

% Data generation parameters
CH_FILE = 'chanlocs128_biosemi_withEOG.elp';
SRATE = 100;
EEG_LEN_MIN = 1;
EEG_LENGTH = 60 * EEG_LEN_MIN; %in seconds 
MODEL_ORDER = 20;
BLINK_N = 6 * EEG_LEN_MIN;
EMG_N = 4 * EEG_LEN_MIN;
WRECK_N = 2;

files = dir(fullfile(SRCDIR, 'BCICIV*.mat'));
if isempty(files)
    error('generate_synthetic_data_demo:no_seed'...
        , 'Seed data %s was NOT found - check your Matlab working directory'...
        , fullfile(SRCDIR, 'BCICIV*.mat'))
end

for k = 1:length(files)

	fprintf(1, 'Processing file %s..\n', files(k).name);

	input_file = fullfile(SRCDIR, files(k).name);
    basename = strsplit(files(k).name, '.');
    basename = basename{1};
    
    % import BCICIV mat file as EEGLAB struct and save
    % saving for later reference and because generate_data() forces this... 
    eeg = ctaptest_convert_bci(input_file); %import BCICIV mat file as EEGLAB struct
    pop_saveset(eeg, 'filename', sprintf('%s.set', basename) ,...
                     'filepath', SRCDIR);

    input_set_file = fullfile(SRCDIR, sprintf('%s.set', basename));
	eeg = ctaptest_generate_data(input_set_file, CH_FILE, EEG_LENGTH, SRATE, MODEL_ORDER);
	eeg = ctaptest_add_ctap(eeg);
	eeg = sbf_add_artifacts(eeg, BLINK_N, EMG_N, WRECK_N);


    % blink events
    n_bl = length(eeg.CTAP.artifact.blink);
    bl_win_s = [eeg.CTAP.artifact.blink(:).time_window_s];
    bl_start_s = bl_win_s(1:2:2*n_bl);
    bl_end_s = bl_win_s(2:2:2*n_bl);
    blink_event = eeglab_create_event(bl_start_s * eeg.srate,...
                          'sa_blink',...
                          'duration', num2cell((bl_end_s - bl_start_s) * eeg.srate),...
                          'nid', num2cell(1:n_bl));

    % EMG events
    n_emg = length(eeg.CTAP.artifact.EMG);
    emg_win_smp = [eeg.CTAP.artifact.EMG(:).time_window_smp];
    emg_start_smp = emg_win_smp(1:2:2*n_emg);
    emg_end_smp = emg_win_smp(2:2:2*n_emg);
    emg_event = eeglab_create_event(emg_start_smp,...
                          'sa_EMG',...
                          'duration', num2cell(emg_end_smp - emg_start_smp),...
                          'nid', num2cell(1:n_emg));
    emg_event_end = eeglab_create_event(emg_end_smp,...
                          'sa_EMG_end');

    eeg.event = eeglab_merge_event_tables(blink_event, emg_event,...
                                          'ignoreDiscontinuousTime');
    eeg.event = eeglab_merge_event_tables(eeg.event, emg_event_end,...
                                          'ignoreDiscontinuousTime');
                                      
    filename = sprintf('%s_syndata.set', basename);
	pop_saveset(eeg, ...
			    'filename', filename, ... 
		        'filepath', OUTDIR, ... 
		        'savemode', 'onefile');
end


% Adds artifacts to the EEG struct given as input
% artifact parameter ranges are hard coded for now
function eeg = sbf_add_artifacts(eeg, n_blinks, n_emg, n_wrecks)

    %% I. WRECK CHANNELS
    % CTAP_detect_bad_channels() finds bad channels if wreck_amount > 3, 
    % threshold is [-1, 1] and
    % filtering has not been run yet. Test the filtering part though.
    % Some non-wrecked
    % channels get identified as bad also.
    for a = 1:n_wrecks
        wreck_amount = randi([2 8]);
%         if rand() < 0.5
%             wreck_amount = 1 / wreck_amount; % randomly either amplify or dampen
%         end
        eeg = ctaptest_modify_variance(eeg,...
                                       randi([1, eeg.nbchan]),...
                                       wreck_amount);
    end

    %% II.   BLINKS
    for a=1:n_blinks
        eeg = ctaptest_add_blink(eeg,...
                                 randi([300,400]),...            % amplitude
                                 randi([5 round(eeg.xmax-5)]),...% start time (in s)
                                 0.100 + rand()*0.2);            % duration (in s)
    end

    %% III.  EMG
    for a=1:n_emg
        w0 = 8+rand()*12;           % band start 8-20 Hz
        w1 = w0+(8+rand()*7);       % band width 8-15 Hz
        wt = 3.0;                   % transition band (roll-off) 3 Hz
        w = [w0 w1 1.0];

        eeg = ctaptest_add_emg(eeg,...
                               20 + rand()*70,...             % amplitude
                               5 + rand()*(eeg.xmax - 10),... % start time (in s)
                               2 + rand()*3.0,...             % duration (in s)
                               [rand()*2 - 1 ...              % center X
                                rand()*2 - 1 ...              % center Y
                                rand()*.5 + .5],...           % center Z
                               rand()*2.5,...                 % radius
                               w...                           % frequency profile
                               );
    end

end


end %of generate_synthetic_data
