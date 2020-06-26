
%% Set path

FILE_ROOT = mfilename('fullpath');
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'paramsweep_example', 'HYDRA_run_test')) - 1);
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'HYDRA_run_test')) - 1);
CH_ROOT = append(REPO_ROOT , 'res/chanlocs128_biosemi_withEOG_demo.elp');
CH_FILE = 'chanlocs128_biosemi.elp';
PARAM = param_sweep_setup(PROJECT_ROOT);




% %% Generate data
% 
% % first synthetic dataset
% chanlocs = readlocs('chanlocs128_biosemi.elp');
% 
% param_sweep_sdgen('BCICIV_calib_ds1a.set', chanlocs, PARAM);


%% parameter sweep pipeline

ctapID = 'hydra_pipe_test';

PREPRO = true;
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;
OVERWRITE_SYNDATA = false
erploc = 'A31';


[Cfg, ~] = sbf_cfg(PROJECT_ROOT, ctapID);

data_dir_seed = append(REPO_ROOT,'ctap/data');
data_dir = fullfile(Cfg.env.paths.projectRoot, 'data', 'demo');
data_type= '*.set'
if ( isempty(dir(fullfile(data_dir,'*.set'))) || OVERWRITE_SYNDATA)
    % Normally this is run only once
    generate_synthetic_data_demo(data_dir_seed, data_dir);
end

%% Create the CONFIGURATION struct

% First, define step sets and their parameters
% [Cfg, ~] = sbf_cfg(PROJECT_ROOT, ctapID);

% Select measurements to process
sbj_filt = 1; 
% Next, create measurement config (MC) based on folder of synthetic source 
% files, & select subject subset
Cfg = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', data_type, 'sbj_filt', sbj_filt);

% Select pipe array and first and last pipe to run
pipeArr = {@sbf_pipe1,...
           @sbf_pipe2,...
           @sbf_peekpipe};
runps = 1:length(pipeArr);
%If the sources exist to feed the later pipes, you can also run only a subset:
% E.G. 2:length(pipeArr) OR [1 4]


%% Run the pipe
if PREPRO
    tic %#ok<*UNRCH>
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                    , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc
end


%% Obtain ERPs of known conditions from the processed data
% For this we use a helper function to rebuild the branching tree of paths
% to the export directories. Here, we only care about ERPs from pipe 2.
CTAP_postproc_brancher(Cfg, @ctap_manu2_oddball_erps, {'loc_label', erploc}...
                        , pipeArr, 'first', 2, 'last', 2, 'dbg', STOP_ON_ERROR)


%cleanup the global workspace
clear PREPRO STOP_ON_ERROR OVERWRITE_OLD_RESULTS sbj_filt pipeArr first last


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
    %Cfg.eeg.chanlocs = 'chanlocs128_biosemi_withEOG_demo.elp';
    Cfg.eeg.chanlocs = 'chanlocs128_biosemi.elp';
    % Define other important stuff
    Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};


    % EOG channel specification for artifact detection purposes
    Cfg.eeg.veogChannelNames = {'VEOG1','VEOG2'};
    Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};

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
                        @CTAP_fir_filter,...
                        @CTAP_run_ica };
    stepSet(i).id = [num2str(i) '_load'];

    out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
        'assist', true);
    out.fir_filter = struct(...
        'locutoff', 2,...
        'hicutoff', 30);

    out.run_ica = struct(...
        'method', 'fastica',...
        'overwrite', true);
    out.run_ica.channels = {'EEG' 'EOG'};


    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe 2
function [Cfg, out] = sbf_pipe2(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %FASTER bad IC detection
                        @CTAP_reject_data,...
                        @CTAP_test_chan,...
                        @CTAP_detect_bad_channels,...%bad channels by variance
                        @CTAP_reject_data,...
                        @CTAP_interp_chan };
    stepSet(i).id = [num2str(i) '_artifact_correction'];

    out.detect_bad_comps = struct(...
        'method', 'faster',...
        'bounds', [-2.5 2.5],...
        'match_logic', @any);
     
    out.detect_bad_channels = struct(...
        'method', 'variance',...
        'channelType', {'EEG'});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe for peeking at other pipe outputs
function [Cfg, out] = sbf_peekpipe(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'peekpipe';
    Cfg.srcid = {'pipe1#1_load'...
                'pipe1#pipe2#1_artifact_correction'};

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_peek_data };
    stepSet(i).id = [num2str(i) '_final_peek'];
    stepSet(i).save = false;

    out.peek_data = struct(...
        'secs', [10 30],... %start few seconds after data starts
        'peekStats', true,... %get statistics for each peek!
        'overwrite', false,...
        'plotAllPeeks', false,...
        'savePeekData', true,...
        'savePeekICA', true);

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end


