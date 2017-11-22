 %% Clean SCCN data CTAP script
% As referenced in the second CTAP article:
% Cowley BU, Korpela J, (2018) Computational Testing for Automated Preprocessing 
% 2: practical demonstration of a system for scientific data-processing workflow 
% management for high-volume EEG. Frontiers in Neuroscience [IN PROGRESS]

% OPERATION STEPS
% # 1
% Get:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%     git clone https://adelorme@bitbucket.org/sccn_eeglab/eeglab.git
%   * CTAP
%   * The 13 files of EEG data in .bdf format from the study 'Auditory Two-
%       Choice Response Task with an Ignored Feature Difference', available at
%       http://headit.ucsd.edu/studies/9d557882-a236-11e2-9420-0050563f2612

% # 2
% Add EEGLAB and CTAP to your Matlab path. For a script to do this see 
% update_matlab_path_ctap.m at CTAP repository root: the directory containing
% 'ctap' and 'dependencies' folders.

% # 3
% Set your working directory to CTAP root

% # 4
% Set up a data directory to contain the .bdf files. Pass the complete 
% path to this directory into the variable 'data_dir_in', below

% # 5
% On the Matlab console, execute >> runctap_manu2_short


%% Setup
data_dir_in = '/home/ben/Benslab/CTAP/CTAPIIdata';
analysis_ID = 'sccn-short-pipe';

% Define step sets and their parameters
[Cfg, ctap_args] = sbf_cfg(data_dir_in, analysis_ID);

% Runtime options for CTAP:
PREPRO = false;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Create measurement config (MC) based on folder
Cfg.MC = path2measconf(data_dir_in, '*.bdf');
% Select measurements to process
clear('Filt')
Filt.subject = 'eeg_recording_8';
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);


%% Select step sets to process
Cfg.pipe.runSets = {'all'}; %this is the default
% Cfg.pipe.runSets = {Cfg.pipe.stepSets(8).id};


%% Assign arguments to the selected functions, perform various checks
Cfg = ctap_auto_config(Cfg, ctap_args);


%% Run the pipe
if PREPRO
tic; %#ok<UNRCH>
CTAP_pipeline_looper(Cfg,...
                    'debug', STOP_ON_ERROR,...
                    'overwrite', OVERWRITE_OLD_RESULTS);
toc;
%clean workspace
clear STOP_ON_ERROR OVERWRITE_OLD_RESULTS Filt ctap_args data_dir_in
end


%% Plot ERPs of saved .sets
% {
setpth = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.runSets{end});
fnames = strcat(Cfg.pipe.runMeasurements, '.set');
% define subject-wise ERP data structure: of known size for subjects,conditions
erps = cell(numel(fnames), 4);
cond = {'short' 'long'};
codes = 100:50:250;
for i = 1:numel(fnames)
    eeg = ctapeeg_load_data(fullfile(setpth, fnames{i}) );
    eeg.event(isnan(str2double({eeg.event.type}))) = [];
    
    for c = 1:2
        stan = pop_epoch(eeg, cellstr(num2str(codes(3:4)' + (c-1))), [-1 1]);
        devi = pop_epoch(eeg, cellstr(num2str(codes(1:2)' + (c-1))), [-1 1]);

        erps{i, c * 2 - 1} = ctap_get_erp(stan);
        erps{i, c * 2} = ctap_get_erp(devi);
        ctaptest_plot_erp([erps{i, 1}; erps{i, 2}], stan.pnts, eeg.srate...
            , {[cond{c} ' standard'] [cond{c} ' deviant']}...
            , fullfile(Cfg.env.paths.exportRoot, sprintf(...
                'ERP%s-%s_%s.png', fnames{i}, cond{c}, 'tones')))

    end
end

% Obtain condition-wise grand average ERP and plot
for c = 1:2:4
    ERP_std = mean(cell2mat(erps(:,c)), 1);
    ERP_dev = mean(cell2mat(erps(:,c + 1)), 1);
    ctaptest_plot_erp([ERP_std; ERP_dev], numel(ERP_std), eeg.srate...
        , {[cond{ceil(c/2)} ' standard'] [cond{ceil(c/2)} ' deviant']}...
        , fullfile(Cfg.env.paths.exportRoot...
            , sprintf('ERP%s-%s_%s.png', 'all', cond{ceil(c/2)}, 'tones')))
end
%}


%% Subfunctions
% Pipe definition
function [Cfg, out] = sbf_cfg(project_root_folder, ID)

% Analysis branch ID
Cfg.id = ID;

Cfg.srcid = {''};

Cfg.env.paths.projectRoot = project_root_folder;


%% Define important directories and files
Cfg.env.paths.branchSource = ''; 
Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.projectRoot, Cfg.id);
Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;

% Channel location file
Cfg.eeg.chanlocs = fullfile(Cfg.env.paths.projectRoot, 'channel_locations_8.elp');
Channels = readlocs(Cfg.eeg.chanlocs);


%% Define other important stuff
Cfg.eeg.reference = {'average'};

% EOG channel specification for artifact detection purposes
Cfg.eeg.veogChannelNames = {Channels([254 255]).labels};%'1EX3' '1EX4'};
Cfg.eeg.heogChannelNames = {Channels([252 253]).labels};%'1EX1','1EX2'};


%% Configure analysis pipe

%% Load
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_reref_data,... 
                    @CTAP_blink2event,...
                    @CTAP_peek_data,...
                    @CTAP_fir_filter,...
                    @CTAP_run_ica };
stepSet(i).id = [num2str(i) '_load'];

out.load_chanlocs = struct(...
    'overwrite', true,...
    'delchan', 1);
out.load_chanlocs.field = {{251:254 'type' 'EOG'}...
                         , {255:256 'type' 'ECG'}};
out.load_chanlocs.tidy  = {{'type' 'FID'} {'type' 'ECG'}};

out.fir_filter = struct(...
    'locutoff', 1);

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};

out.peek_data = struct(...
    'plotEEGset', false,...
    'plotEEGHist', false);


%% IC correction
i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST for horizontal eye moves
                    @CTAP_reject_data,...
                    @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_filter_blink_ica,...
                    @CTAP_detect_bad_channels,...%adjust the variance thresholds!
                    @CTAP_reject_data,...
                    @CTAP_interp_chan,...
                    @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_artifact_correction'];


out.detect_bad_comps = struct(...
    'method', {'adjust' 'blink_template'},...
    'adjustarg', {'horiz' ''});

out.detect_bad_channels = struct(...
    'method', 'variance',...
    'channelType', {'EEG'});


%% Store to Cfg
Cfg.pipe.runSets = {'all'}; % step sets to run, the whole thing by default
Cfg.pipe.stepSets = stepSet; % record of all step sets

end