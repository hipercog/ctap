% Define data path and other variables
dataPath = '/home/anhe/work/tmp_n1_eeglab_plugin/TESTDATA/';
sessionPhaseNumber = 1;

% Read NeurOne-data
% recording_mega = module_read_neurone(dataPath, sessionPhaseNumber);
recording_mega = module_read_neurone(dataPath, sessionPhaseNumber, 'channels', {'Fz', 'ECG'});