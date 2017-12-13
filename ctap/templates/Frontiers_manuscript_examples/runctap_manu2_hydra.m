%% Clean SCCN data CTAP script
% As referenced in the second CTAP article:
% Cowley BU, Korpela J, (2018) Computational Testing for Automated Preprocessing 
% 2: practical demonstration of a system for scientific data-processing workflow 
% management for high-volume EEG. Frontiers in Neuroscience [IN PROGRESS]

% OPERATION STEPS
% # 1
% Install / download:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%     git clone https://adelorme@bitbucket.org/sccn_eeglab/eeglab.git
%   * CTAP
%       git clone https://github.com/bwrc/ctap.git
%   * The 13 files of EEG data in .bdf format from the study 'Auditory Two-
%       Choice Response Task with an Ignored Feature Difference', available at
%       http://headit.ucsd.edu/studies/9d557882-a236-11e2-9420-0050563f2612

% # 2
% Set your working directory to CTAP root

% # 3
% Add EEGLAB and CTAP to your Matlab path. For a script to do this see 
% update_matlab_path_ctap.m at CTAP repository root: the directory containing
% 'ctap' and 'dependencies' folders.

% # 4
% Set up a data directory to contain the .bdf files. Pass the complete 
% path to this directory into the variable 'data_dir_in', below

% # 5
% On the Matlab console, execute >> runctap_manu2_hydra


%% Setup MAIN parameters
% set the input directory where your data is stored
data_dir_in = '/home/ben/Benslab/CTAP/CTAPIIdata';
% specify the file type of your data
data_type = '*.bdf';
% use sbj_filt to select all (or a subset) of available recordings
sbj_filt = setdiff(1:12, [3 7]);
% use ctapID to uniquely name the base folder of the output directory tree
ctapID = 'sccn-hydra-pipe';
% use keyword 'all' to select all stepSets, or use some index
set_select = 'all';
% set the electrode for which to calculate and plot ERPs after preprocessing
erploc = 'C20';

% Runtime options for CTAP:
PREPRO = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Create the CONFIGURATION struct

% First, define step sets and their parameters
[Cfg, ~] = sbf_cfg(data_dir_in, ctapID);

% Next, create measurement config (MC) based on folder, & select subject subset
[Cfg.MC, Cfg.pipe.runMeasurements] =...
    confilt_meas_dir(data_dir_in, data_type, sbj_filt);

% Select pipe array and first and last pipe to run
pipeArr = {@sbf_pipe1,...
           @sbf_pipe2A,...
           @sbf_pipe2B};
first = 1;
last = length(pipeArr);
%You can also run only a subset of pipes, e.g. 2:length(pipeArr)


%% Run the pipe
if PREPRO
    tic %#ok<*UNRCH>
    CTAP_pipeline_brancher(Cfg, pipeArr, first, last...
                        , STOP_ON_ERROR, OVERWRITE_OLD_RESULTS)
    toc
    clear PREPRO STOP_ON_ERROR OVERWRITE_OLD_RESULTS sbj_filt
end


%% Finally, obtain ERPs of known conditions from the processed data
% For this we use a helper function to rebuild the branching tree of paths
% to the export directories
CTAP_postproc_brancher(Cfg, pipeArr, first, last)%@oddball_erps, erploc
clear pipeArr first last



%% Subfunctions

%% Return configuration structure
function [Cfg, out] = sbf_cfg(project_root_folder, ID)

    % Analysis branch ID
    Cfg.id = ID;
    Cfg.srcid = {''};
    Cfg.env.paths.projectRoot = project_root_folder;

    % Define important directories and files
    Cfg.env.paths.branchSource = ''; 
    Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.projectRoot, Cfg.id);
    Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;

    % Channel location file
    Cfg.eeg.chanlocs = Cfg.env.paths.projectRoot;

    % Define other important stuff
    Cfg.eeg.reference = {'average'};

    % EOG channel specification for artifact detection purposes
    Cfg.eeg.heogChannelNames = {'EXG1' 'EXG2'};
    Cfg.eeg.veogChannelNames = {'EXG3' 'EXG4'};

    % dummy var
    out = struct([]);
end


%% Configure pipe 1
function [Cfg, out] = sbf_pipe1(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe1';
    Cfg.srcid = {''};

    %%%%%%%% Define pipeline %%%%%%%%
    % Load
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
    out.load_chanlocs.field = {{{'EXG1' 'EXG2' 'EXG3' 'EXG4'} 'type' 'EOG'}...
                             , {{'EXG5' 'EXG6' 'EXG7' 'EXG8'} 'type' 'NA'}};
    out.load_chanlocs.tidy  = {{'type' 'FID'} {'type' 'NA'}};

    out.fir_filter = struct(...
        'locutoff', 1);

    out.run_ica = struct(...
        'method', 'fastica',...
        'overwrite', true);
    out.run_ica.channels = {'EEG' 'EOG'};

    out.peek_data = struct(...
        'plotAllPeeks', false,...
        'peekStats', true,...
        'savePeekData', true,...
        'savePeekICA', true);


    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe 2
function [Cfg, out] = sbf_pipe2A(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2A';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST for horiz eye moves
                        @CTAP_reject_data,...
                        @CTAP_detect_bad_comps,... %detect blink related ICs
                        @CTAP_filter_blink_ica,...
                        @CTAP_sweep,...
                        @CTAP_detect_bad_channels,...%bad channels by variance
                        @CTAP_reject_data,...
                        @CTAP_interp_chan,...
                        @CTAP_peek_data };
    stepSet(i).id = [num2str(i) '_artifact_correction'];

    out.detect_bad_comps = struct(...
        'method', {'adjust' 'blink_template'},...
        'adjustarg', {'horiz' ''});

    out.sweep = struct(...
        'function', 'CTAP_detect_bad_channels',...
        'sweep_param', 'bounds',...
        'bounds', 1.5:0.3:7);
    out.sweep.SWPipe.funH = {@CTAP_detect_bad_channels, @CTAP_reject_data};
    out.sweep.SWPipe.id = '1_sweep';
    
    out.sweep.SWPipeParams.method = 'variance';
    
    out.detect_bad_channels = struct(...
        'method', 'variance',...
        'channelType', {'EEG'});

    out.peek_data = struct(...
        'plotAllPeeks', false,...
        'peekStats', true,...
        'savePeekData', true,...
        'savePeekICA', true);
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe 2
function [Cfg, out] = sbf_pipe2B(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2B';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %FASTER bad IC detection
                        @CTAP_reject_data,...
                        @CTAP_detect_bad_channels,...%bad channels by spectra
                        @CTAP_reject_data,...
                        @CTAP_interp_chan,...
                        @CTAP_peek_data };
    stepSet(i).id = [num2str(i) '_artifact_correction'];

    out.detect_bad_comps = struct(...
        'method', 'faster');

    out.detect_bad_channels = struct(...
        'method', 'rejspec',...
        'channelType', {'EEG'});

    out.peek_data = struct(...
        'plotAllPeeks', false,...
        'peekStats', true,...
        'savePeekData', true,...
        'savePeekICA', true);
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end
