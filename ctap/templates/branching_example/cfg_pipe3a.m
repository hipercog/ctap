function [Cfg, out] = cfg_pipe3a(Cfg)

%% Define hierarchy
Cfg.id = 'pipe3a';
Cfg.srcid = {'pipe1#pipe2#1_ICA'};


%% Define pipeline

%% IC correction
%{
i = 1; 
stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_IC_correction'];
%}

% blink correction using IC high-pass filtering
i = 1;
stepSet(i).funH = { @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_filter_blink_ica,...
                    @CTAP_peek_data}; %correct ICs using FIR filter
stepSet(i).id = [num2str(i) '_blink_correction'];

out.detect_bad_comps = struct('method', 'blink_template');

out.peek_data.channels = {'C17','C18','C19','C21','C1','A3','A19','A21'};
out.peek_data.secs = 10;
out.peek_data.logStats = false; %todo: normfit.m missing...
out.peek_data.plotICA = false;


%% PSD and features
i = i+1;
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


%% Store to Cfg
Cfg.pipe.stepSets = stepSet;
Cfg.pipe.runSets = {stepSet(:).id};