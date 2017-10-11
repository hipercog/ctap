function [Cfg, out] = cfg_manu(project_root_folder)
% Pipe definition file to be used with runctap_manu.m
%
% Note: CTAP_peek_data is used only at the start and in the end since
% plotting all the peek figures takes a longish time. Feel free to add more
% peeks if desired.


%% Define hierarchy
% Analysis branch ID
% Important as this id is used to separate analysis branches with different
% configurations. Defined here to keep it with the configs.
Cfg.id = 'ctapmanu';

Cfg.srcid = {''};


%% Cross-platform stuff (not part of CTAP)
Cfg.env.paths.projectRoot = project_root_folder;


%% Define important directories and files
Cfg.env.paths.branchSource = ''; %since this pipe starts from raw EEG data
Cfg.env.paths.ctapRoot = fullfile(cd(), 'example-project');
Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.ctapRoot, Cfg.id);

% Note: other canonical locations are added in ctap_auto_config.m
% You should use it in your analysis batch file.

% Location of measurement config file
% If you have made your own measurement config file, you can store the
% location here. The example uses autogeneration.
% Cfg.env.measurementInfo = fullfile(...);

% Channel location file
% For demonstration purposes this is in ctap repo folder "res", 
% which should be in your path and therefore accessible without full path
Cfg.eeg.chanlocs = 'chanlocs128_biosemi.elp';
Channels = readlocs(Cfg.eeg.chanlocs);

                
%% Define other important stuff
Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
%data is average referenced -> change to this reference

% EOG channel specification for artifact detection purposes
% Allowed values: {},{'chname'},{'chname1','chname2'}
% In case of two channel names their abs(ch1-ch2) is used as the signal.
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};

%Cfg.event.csegEvent = 'correctAnswerBlock';
% type of events that define data segments from which features are extracted



%% Configure analysis pipe
% Appear in order of usage


%% Load
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_tidy_chanlocs,...
                    @CTAP_reref_data,... 
                    @CTAP_blink2event,...
                    @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_load'];

out.load_data = struct(...
    'type', 'set'); %also requires data path from Cfg.MC

out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
    'assist', true);

out.tidy_chanlocs.types =...
    {{'1:128' 'EEG'}, {'129 130 131 132' 'EOG'}, {'133 134' 'REF'}};

% plot only a single figure each time, not a set of figures.
% out.peek_data.plotEEGset = false;
out.peek_data.peekevent = {'sa_blink'};


%% Filter
i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_fir_filter};
    %,... %makes amplitude hist narrower!
    %                @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_filter'];

% Filtering data
out.fir_filter = struct(...
    'locutoff', 2,...
    'hicutoff', 30);


%% ICA
i = i+1;  %stepSet 3
stepSet(i).funH = { @CTAP_run_ica};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_ICA'];
% ICA can take ages -> hence a cut here

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};


%% IC correction
% TODO: crashes on jkor's machine... do I have ADJUST installed?
i = i+1;  %stepSet 4
stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST
                    @CTAP_reject_data};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_IC_correction'];


%% Blink correction
i = i+1;  %stepSet 5
stepSet(i).funH = { @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_filter_blink_ica}; %correct ICs using FIR filter
stepSet(i).id = [num2str(i) '_blink_correction'];

out.detect_bad_comps = struct(...
    'method', 'blink_template');
out.detect_bad_comps = struct(...
    'method', {'adjust' 'blink_template'},...
    'adjustarg', {'horiz' ''});


%% Artifact correction
i = i+1;  %stepSet 6
stepSet(i).funH = { @CTAP_detect_bad_channels,... %variance thresholds need adjustment!
                    @CTAP_reject_data,...
                    @CTAP_interp_chan, ... %need to interpolate immediately to avoid missing channels
                    @CTAP_detect_bad_segments,... 
                    @CTAP_reject_data,...
                    @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_artifact_correction'];

out.detect_bad_channels = struct(...
    'method', 'variance',...
    'channelType', {'EEG'});

% Amplitude thresholding from continuous data (bad segments)
ampthChannels = setdiff(  {Channels.labels},...
                          {Cfg.eeg.reference{:},...
                           Cfg.eeg.heogChannelNames{:},...
                           Cfg.eeg.veogChannelNames{:},...
                           'VEOG1', 'VEOG2', 'C16', 'C29'}); %#ok<CCAT>
% channels {'VEOG1', 'VEOG2', 'C16', 'C29'} are frontal and contain large
% blinks. They are removed in order to not detect blinks in
% CTAP_detect_bad_segments().
out.detect_bad_segments = struct(...
    'channels', {ampthChannels}, ...
    'normalEEGAmpLimits', [-75, 75]); %in muV


%% Clean ICA
i = i+1; %stepSet 7
stepSet(i).funH = { @CTAP_run_ica };
stepSet(i).id = [num2str(i) '_clean_ICA'];


%% PSD and features
i = i+1; %stepSet 8
stepSet(i).funH = { @CTAP_generate_cseg,...
                    @CTAP_compute_psd,...
                    @CTAP_extract_bandpowers,...
                    @CTAP_extract_PSDindices};
stepSet(i).id = [num2str(i) '_PSD_and_features'];


% Uses Cfg.event.csegEvent as cseg event type.
out.compute_psd = struct(...
	'm', 2,...% in sec
	'overlap', 0.5,...% in percentage [0,1]
	'nfft', 1024); % in samples (int), should be 2^x, nfft > m*srate

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


%% Debug
% Some examples of how to add an extra step set with a custom source step
% set to do debugging.
%{
i = i+1; %stepSet 9
stepSet(i).funH = { @CTAP_detect_bad_segments,... 
                    @CTAP_reject_data };
stepSet(i).id = [num2str(i) '_debug'];
stepSet(i).srcID = '5_blink_correction';
%}
%{
i = i+1; %stepSet 9
stepSet(i).funH = { @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_debug'];
stepSet(i).srcID = '7_clean_ICA';
out.peek_data = struct(...
    'secs', 8,...
    'logStats', true,...
    'peekStats', true,...
    'plotEEG', false,...
    'plotEEGHist', false,...
    'plotICA', false);
%}

%% Store to Cfg
Cfg.pipe.runSets = {'all'}; % step sets to run, the whole thing by default
Cfg.pipe.stepSets = stepSet; % record of all step sets


%% Configure output

% Should plots be generated
Cfg.grfx.on = true;

% Result export
% Metadata variable names to include in the export
Cfg.export.csegMetaVariableNames = {'timestamp','latency','duration'};