%% Clean SCCN data CTAP script
% Runtime options for CTAP:
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Setup
FILE_ROOT = mfilename('fullpath');
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'hydra_branch_example', 'cleanSCCNdata' )) - 1);

data_dir_in =fullfile(REPO_ROOT,'/ctap/data/test_data');

% Define step sets and their parameters
[Cfg, ctap_args] = sbf_cfg(data_dir_in);


%% Create measurement config (MC) based on folder
Cfg.MC = path2measconf(data_dir_in, '*.bdf');
% Select measurements to process
clear('Filt')
Filt.subject = 'eeg_recording_1';
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);


%% Select step sets to process
Cfg.pipe.runSets = {'all'}; %this is the default
% Cfg.pipe.runSets = {Cfg.pipe.stepSets(8).id};


%% Assign arguments to the selected functions, perform various checks
Cfg = ctap_auto_config(Cfg, ctap_args);


%% Run the pipe

% tic;
% CTAP_pipeline_looper(Cfg,...
%                     'debug', STOP_ON_ERROR,...
%                     'overwrite', OVERWRITE_OLD_RESULTS);
% toc;
% 
% % clean workspace
% % clear STOP_ON_ERROR OVERWRITE_OLD_RESULTS Filt ctap_args data_dir_in



%% Cleanup saved .sets

% USE THIS CODE TO SELECT A 128 CHAN SUBSET OF THE 252 CHANS SAVED BY LOOPER
setpths = fullfile(Cfg.env.paths.projectRoot, Cfg.pipe.runSets);
fname = [Cfg.pipe.runMeasurements{1} '.set'];
savename = strrep(fname, 'session_meas', '128ch');
savename1 = strrep(fname, 'session_meas', 'full');

for i = 1:numel(setpths)
    eeg = ctapeeg_load_data(fullfile(setpths{i}, fname) );  
    pop_saveset(eeg, 'filename', savename1, 'filepath', setpths{i});
    eeg = pop_select(eeg, 'channel', [1:8 10:2:248]);
    pop_saveset(eeg, 'filename', savename, 'filepath', setpths{i});
end
clear setpths fname savename eeg abcdfh escalp gscalp keepchans
    
%     Build an index of channels to keep, leaving only 128 scalp sites
%     abcdfh = find(ismember({eeg.chanlocs.type}, 'EEG') &...
%              contains({eeg.chanlocs.labels}, {'A' 'B' 'C' 'D' 'F' 'H'}));
%     escalp = find(ismember({eeg.chanlocs.type}, 'EEG') &...
%              contains({eeg.chanlocs.labels}, {'E'}));
%     gscalp = find(ismember({eeg.chanlocs.type}, 'EEG') &...
%              contains({eeg.chanlocs.labels}, {'G'}));
%     keepchans = [abcdfh escalp([1:10 31 32]) gscalp([18 20:28 31])];



%% Subfunctions
% Pipe definition
function [Cfg, out] = sbf_cfg(project_root_folder)

% Analysis branch ID
Cfg.id = 'sccn-clean-20min';

Cfg.srcid = {''};

Cfg.env.paths.projectRoot = project_root_folder;


%% Define important directories and files
Cfg.env.paths.branchSource = ''; 
Cfg.env.paths.ctapRoot = project_root_folder;
Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;

% Channel location file
Cfg.eeg.chanlocs = fullfile(project_root_folder, 'channel_locations.elp');
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
                    @CTAP_select_data,...
                    @CTAP_fir_filter,...
                    @CTAP_select_data,...
                    @CTAP_run_ica,...
                    @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_load'];

out.load_chanlocs = struct(...
    'overwrite', true,...
    'delchan', 1);
out.load_chanlocs.field = {{251:254 'type' 'EOG'}...
                         , {255:256 'type' 'ECG'}};
out.load_chanlocs.tidy  = {{'type' 'FID'} {'type' 'ECG'}};

out.select_data = struct(...
    'time', {[1100 2500] [100 1300]});

out.fir_filter = struct(...
    'locutoff', 1);

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};

out.peek_data = struct(...
    'plotAllPeeks', false,...
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