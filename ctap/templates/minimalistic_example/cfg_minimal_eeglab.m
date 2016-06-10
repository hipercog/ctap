function [Cfg, out] = cfg_minimal(dataRoot, analysisRoot, branchID)


%% Define directories
% Note: other canonical locations are added in cfg_ctap_functions.m
% You should use it in your analysis batch file.

Cfg.env.paths.analysisRoot = fullfile(analysisRoot,'ctap_analysis',branchID);
Cfg.eeg.chanlocs = fullfile(dataRoot,'eeglab_chan32.locs');

                
%% Define other important stuff
Cfg.eeg.reference = {'C3' 'C4'};

% EOG channel specification for artifact detection purposes.
% Not obligatory but highly recommended.
% Allowed values: {},{'chname'},{'chname1','chname2'}
% In case of two channel names their abs(chname1-chname2) is used as the 
% signal.
Cfg.eeg.veogChannelNames = {'EOG1'};
Cfg.eeg.heogChannelNames = {'EOG2'};

%Cfg.event.csegEvent = 'correctAnswerBlock';
% event type of events that define segments of data from which features are 
% extracted


%% Configure analysis functions
% Appear in order of usage

% Load channel locations
out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
    'assist', true);
%     'filetype', '',...
%     'format', '',...
%     'skiplines', 0,...

% Edit channel locations
out.tidy_chanlocs.tidy = true;
out.tidy_chanlocs.types =...
    {{'1:32' 'EEG'},{'17 22' 'REF'},{'33' ''},{'34:35' 'EOG'},{'36' ''}};
% non-EEG channels marked as empty?

% Load events
out.load_events = struct(...
    'method', 'handle',...
    'handle', @loadWCSTevents);

% Find blinks
out.blink2event.invert = true;  %code assumes blinks are positive,
                                % EOG1 has them negative

% Selecting data based on event type
out.select_evdata.evtype = 'testRegion';

% plot only a single figure each time, not a set of figures.
% out.peek_data.plotEEGset = false;

% Amplitude thresholding from continuous data (bad segments)
out.detect_bad_segments = struct(...
    'amplitudeTh', [-100, 100]); %in muV [-100, 100]

% Detection of bad channels
out.detect_bad_channels = struct(...
    'method', 'variance',...
    'channelType', {'EEG'});

% Data normalization
% Scaling "squeezes" amplitudes so that they are no longer in the typical 
% EEG range. Normally only centering makes sense. 
out.normalize_data = struct(...
    'center', true,...
    'scale', false);

% Filtering data
out.filter_data = struct(...
    'lowCutOff', 0.5,... %0.5
    'highCutOff', 45);

% ICA
out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};

% Detect bad ICA components
out.detect_bad_comps = struct(...
    'method', {'blink_template' 'adjust'},...
    'adjustarg', {'' {'horiz' 'verti'}});

% Compute PSD
% correctAnswerBlock durations 4...20 sec
% Uses Cfg.event.csegEvent as cseg event type.
out.compute_psd = struct(...
	'm', 2,...% in sec
	'overlap', 0.5,...% in percentage [0,1]
	'nfft', 1024); % in samples (int), should be 2^x, nfft > m*srate

% Extract features
% Bandpowers
out.extract_bandpowers = struct(...
    'fmin', [1  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20]); %Upper frequency limits, in Hz
% Time zero event '254' gets removed when subsetting to 'testRegion' events
% Use of '' as time zero event means dataset start is used as time zero

% PSD indices
out.extract_PSDindices = struct();
out.extract_PSDindices.entropy = struct(...
    'fmin', [1 1  1  1  1  3.5 5  4 8  2  3  6  10],...%Low freq limits, in Hz
    'fmax', [7 15 25 35 45 45  15 8 12 45 45 45 45]);%Hi freq limits, in Hz
tmp = get_refchan_inds()

out.extract_PSDindices.eind = struct(...
    'fmin', [1  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');
%Note!: Do not change the labels. Adjust frequency limits only!
out.extract_PSDindices.eind.bandLabels = {'delta' 'theta' 'alpha' 'beta'};

out.extract_PSDindices.eindcc = struct(...
    'fzStr', 'Fz',...
	'pzStr', 'Pz',...
    'fmin', [1  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');
%Note!: Do not change the labels. Adjust frequency limits only!
out.extract_PSDindices.eindcc.bandLabels = {'delta' 'theta' 'alpha' 'beta'};


%% Configure result export
Cfg.export.csegMetaVariableNames = {'timestamp','latency','duration',...
                            'globalstim','localstim','rule','ruleblockid'};

