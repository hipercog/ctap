%% Test syndata generation

% Input files used for generation
DATADIR = '/ukko/projects/ReKnow/Data/validation/data';

% Output directory for generated files
OUTDIR = '/home/jkor/work_local/projects/ctap/ctap_manuscript_experiments/syndata_ctap_manuscript';
if ~isdir(OUTDIR), mkdir(OUTDIR); end;

% Data generation parameters
EEG_LEN_MIN = 5;
CH_FILE = '/ukko/projects/ReKnow/Data/validation/chanlocs128_biosemi.elp';
SRATE = 256;
EEG_LENGTH = 60 * EEG_LEN_MIN; %in seconds ? 
MODEL_ORDER = 20;
MAX_BLINK_NUMBER = 10 * EEG_LEN_MIN;

files = dir(fullfile(DATADIR, '*1.set'));

for k = 1:length(files)

	fprintf(1, 'Processing file %s..\n', files(k).name);

	input_file = fullfile(DATADIR, files(k).name);

	eeg = generate_data(input_file, CH_FILE, EEG_LENGTH, SRATE, MODEL_ORDER);
	eeg = ctaptest_add_CTAP(eeg);
	eeg = ctaptest_add_artifacts(eeg, MAX_BLINK_NUMBER, 0, 0);

	filename = sprintf('%04d.set', k);

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
    
	pop_saveset(eeg, ...
			    'filename', filename, ... 
		        'filepath', OUTDIR, ... 
		        'savemode', 'onefile');
end


%% Analyze synthetic data

OUTDIR = '/home/jkor/work_local/projects/ctap/ctap_manuscript_experiments/syndata_ctap_manuscript';
EEG = pop_loadset('0001.set', OUTDIR);
    
EEG = pop_loadset('0001_session_meas.set',...
'/home/jkor/work_local/projects/ctap/ctap_manuscript_experiments/ctap/ctapmanu/1_load_WCST');

EEG = pop_loadset('0001_session_meas.set',...
'/home/jkor/work_local/projects/ctap/ctap_manuscript_experiments/ctap/ctapmanu/test');


ctap_eegplot(EEG, 'channels', ...
    {'HEOG1','HEOG2','L_MASTOID','R_MASTOID','VEOG1','VEOG2','C17','C18','C23','A21'});

eegplot(EEG.data,...
        'srate', EEG.srate,...
        'limits', [EEG.xmin EEG.xmax]*1000,...
        'events', EEG.event,...
        'winlength', 30,...
        'dispchans', 134);  
    
    
%% txt file export
outfile = '~/tmp/test.txt';

header = {'var1','var2','var3'};
conversion = {'%s','%f','%d'};
data = {'jee',2.5,4.0; '',NaN,4.0; 'jee2',2.4,5; };

cell2txtfile(outfile, header, data, conversion,...
                'allownans', 'yes',...
                'writemode', 'wt',...
                'delimiter', ';\t')

cell2txtfile(outfile, '', data, conversion,...
                'allownans', 'yes',...
                'writemode', 'at')

            
%% SQLite export with NaN

testfile = '/home/jkor/work_local/projects/ctap/ctap_pipeline/example-project/ctap_results/ctapmanu/features/bandpowers/BCICIV_calib_ds1a_syndata_session_meas_bandpowers.mat';

D = load(testfile);

D.ResBPabs.A1.data(1,[2:3]) = NaN;
D.ResBPrel.A1.data(1,[2:3]) = NaN;
D.ResBPabs.A1.data(1:2,:)
D.ResBPrel.A1.data(1:2,:)

modfile = 'modified_testfile.mat'; 
save(modfile, '-struct', 'D');
D = load(modfile);
D.ResBPabs.A1.data(1:2,:)
D.ResBPrel.A1.data(1:2,:)

dataexport_sqlite({'modified_testfile.mat'}, 'test.sqlite',...
                    'factorsVariable', 'SEGMENT',...
                    'cseg_meta_variable_names',  {'timestamp','latency','duration','globalstim','localstim','rule','ruleblockid'})






