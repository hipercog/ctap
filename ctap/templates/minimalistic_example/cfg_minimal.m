function [Cfg, out] = cfg_minimal(project_root_folder)


% Analysis branch ID
% Important as this id is used to separate analysis branches with different
% configurations. Defined here to keep it with the configs.
Cfg.id = 'minimal';


%% Cross-platform stuff (not part of CTAP)
Cfg.env.paths.projectRoot = project_root_folder;


%% Define important directories and files
Cfg.env.paths.ctapRoot = fullfile(cd(), 'example-project');
Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.ctapRoot, Cfg.id);

% Note: other canonical locations are added in ctap_auto_config.m
% You should use it in your analysis batch file.

% Location of measurement config file
% If you have made your own measurement config file, you can store the
% location here.  The example uses autogeneration.
% Cfg.env.measurementInfo = fullfile(...);

% Channel location file
% For demonstration purposes this is in ctap repo folder "res", 
% which should be in your path and therefore accessible without full path
Cfg.eeg.chanlocs = 'chanlocs128_biosemi_withEOG_demo.elp';

                
%% Define other important stuff
Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
%data is average referenced -> change to this reference

% EOG channel specification for artifact detection purposes
% Allowed values: {},{'chname'},{'chname1','chname2'}
% In case of two channel names their abs(ch1-ch2) is used as the signal.
Cfg.eeg.veogChannelNames = {'VEOG1','VEOG2'};
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};

%Cfg.event.csegEvent = 'correctAnswerBlock';
% type of events that define data segments from which features are extracted


%% Configure analysis functions
% Appear in order of usage

% Load data
out.load_data = struct(...
    'type', 'set'); %also requires data path from Cfg.MC

% Load channel locations
out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
    'assist', true);
%     'filetype', '',...
%     'format', '',...
%     'skiplines', 0,...

% Edit channel locations
%out.tidy_chanlocs.tidy = true;
out.tidy_chanlocs.types =...
    {{'1:128' 'EEG'}, {'131 132' 'REF'}, {'129 130 133 134' 'EEG'}};
% channels 129, 130, 133, 134 are EOG channels by name but do not contain
% EOG activity

% Load events
out.load_events = struct(...
    'method', 'handle',...
    'handle', @loadWCSTevents);

% plot only a single figure each time, not a set of figures.
% out.peek_data.plotEEGset = false;

% Amplitude thresholding from continuous data (bad segments)
out.detect_bad_segments = struct(...
    'amplitudeTh', [-60, 60]); %in muV

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
out.fir_filter = struct(...
    'lowcutoff', 2,...
    'hicutoff', 30);

% ICA
out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};

% Detect bad ICA components
out.detect_bad_comps = struct(...
    'method', {'blink_template'});


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

out.extract_PSDindices.eind = struct(...
    'fmin', [1  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');
%Note!: Do not change the labels. Adjust frequency limits only!
out.extract_PSDindices.eind.bandLabels = {'delta' 'theta' 'alpha' 'beta'};

out.extract_PSDindices.eindcc = struct(...
    'fmin', [1  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');
out.extract_PSDindices.eindcc.bandLabels = {'delta' 'theta' 'alpha' 'beta'};

out.select_data.time = [1,5];

%out.filter_bandpass = struct(...
%    'lowCutOff', 0.5,...
%    'highCutOff', 45);



%{


%{
struct(...
    'blinks', true,...
    'bounds', [-2 2],...
    'method', {'adjust' 'adjust' 'adjust' 'recufast'},...
    'adjtect', {'horiz' 'verti' 'blink' ''});
%}



out.detect_bad_epochs = struct(...
    'method', 'recufast');

out.epoch_data = struct(...
    'method', 'regep');




out.normalize_data = struct(...
    'center', true,...
    'scale', false);


out.load_chanlocs = struct(...%most chanlocs fields come from Cfg.eeg.chanlocs
    'assist', true);

out.load_events = struct(...
    'method', 'handle',...
    'handle', @loadWCSTevents);

% out.reject_data %reads args from EEG.CTAP...created by detect functions

% out.reref_data %reference channels specified in Cfg.eeg.reference



out.tidy_chanlocs.types =...
    {{'1:32' 'EEG'},{'17 22' 'REF'},{'33' 'ECG'},{'34:35' 'EOG'},{'36' 'EDA'}};

out.generate_cseg = struct(...
    'measStartEvent', '254',...%event type string
	'measStopEvent', '255',...%event type string
	'segmentLength', 5,...%in sec
	'segmentOverlap', 0,...%in percentage [0,1]
	'csegEvent', 'cseg');%event type string

out.generate_cseg_clump = struct(...
    'guideEvent', 'correctAnswerBlock',...%event type string
	'segmentLength', 4,...%in sec
	'segmentOverlap', 0,...%in percentage [0,1]
	'csegEvent', 'cseg');%event type string

    


%}


%% Configure output

% Should plots be generated
Cfg.grfx.on = true;

% Result export
% Metadata variable names to include in the export
Cfg.export.csegMetaVariableNames = {'timestamp','latency','duration',...
                            'globalstim','localstim','rule','ruleblockid'};

