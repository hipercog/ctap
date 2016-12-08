update_matlab_path_anyone;

% Setup paths to data, output and channel location file
UKKO_ROOT = '/ukko';

%BASEDIR = '/home/uni/ctaptest/testruns/run4/';
%RESULTDIR = '/home/uni/ctaptest/results/run4/';
%CH_FILE = '/../chanlocs128_biosemi.elp';  % can we make this non-relational
%DATADIR = '/home/uni/ctaptest/testing_dataset';
%
DATADIR = '/projects/ReKnow/Data/data';
CH_FILE = '/projects/ReKnow/Data/validation/chanlocs128_biosemi.elp');

% Results get dumped here
BASEDIR = '/tmp/kek_run';
RESULTDIR = '/tmp/kek_results';

ctaptest_load_hydra();

fprintf(1, 'DATA: %s\nBASE: %s\nRESULT:%s\n', DATADIR, BASEDIR, RESULTDIR);

if ~isdir(BASEDIR), mkdir(BASEDIR); end;
if ~isdir(RESULTDIR), mkdir(RESULTDIR); end;

DATA_0 = [BASEDIR 'D0'];
DATA_A = [BASEDIR 'DA'];
if ~isdir(DATA_0), mkdir(DATA_0); end;
if ~isdir(DATA_A), mkdir(DATA_A); end;

MODEL_ORDER = 20;
MAX_BLINK = 20;
MAX_EMG_BURST = 10;
MAX_BAD_CH = 10;
RUN_DATA_GEN = false;
RUN_TEST_CTAP = true;

%% GENERATE TESTING DATASET AND ARTIFACTS
if RUN_DATA_GEN
	fprintf(1, 'Generating test data!')
    files = dir(fullfile(DATADIR, '*.mat'));
    for k = 1:length(files)
        eeg = ctaptest_datagen(fullfile(DATADIR, files(k).name),...
                               CH_FILE, MODEL_ORDER);
        eeg = ctaptest_add_CTAP(eeg);
        eeg_0 = eeg;
        eeg_a = ctaptest_add_artifacts(eeg, MAX_BLINK, MAX_EMG_BURST,...
                                       MAX_BAD_CH);
        eeg_0 = ctapeeg_epoch_data(eeg_0, 'method', 'regep');
        eeg_a = ctapeeg_epoch_data(eeg_a, 'method', 'regep');
        fname = sprintf('%d04.set', k);
        pop_saveset(eeg_0, 'filename', fname, 'filepath', DATA_0,... 
                    'savemode', 'onefile');
        pop_saveset(eeg_a, 'filename', fname, 'filepath', DATA_A,... 
                    'savemode', 'onefile');
    end
end

FILES_A = dir(fullfile(DATA_0, '*.set'));
FILES_0 = dir(fullfile(DATA_A, '*.set'));
METHODS = {'cereberus','medusa','harpy', 'cyclops'};

%% RUN CTAP TEST SEQUENCE
if RUN_TEST_CTAP
	for k = 1:length(METHODS)
		fprintf(1, '\tBATCH-ID: [%s]\n', METHODS{k});
                DATA_STR = 'DA';
                OUTPUT = 'HYDRA2';
		batch_id = METHODS{k};
		pipebatch_HYDRAKING
                DATA_STR = 'D0';
                OUTPUT = 'KRAKEN2';
		batch_id = METHODS{k};
		pipebatch_HYDRAKING
	end
	%ctaptest_batchcomparematrix(BASEDIR, RESULTDIR);
end
