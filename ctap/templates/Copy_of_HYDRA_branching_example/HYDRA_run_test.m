%% CTAP HYDRA analysis batchfile
% 
% To run this, you need:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%       git clone https://github.com/sccn/eeglab.git
%   * CTAP
%       git clone https://github.com/bwrc/ctap.git
% 
% Make sure your working directory is the CTAP root i.e. the folder with
% 'ctap' and 'dependencies'.
% 
% Also make sure that EEGLAB and CTAP have been added to your Matlab path. 
% For a script to do this see update_matlab_path_ctap.m at CTAP repository
% root.


%% Set path

FILE_ROOT = mfilename('fullpath');
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'Copy_of_HYDRA_branching_example', 'HYDRA_run_test')) - 1);
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'HYDRA_run_test')) - 1);
CH_FILE = 'chanlocs128_biosemi_withEOG.elp'; % channel location file for generating synthetic data, comment it if not using HYDRA
PARAM = param_sweep_setup(PROJECT_ROOT);


%% Basic config
HYDRA = true;
cleanseed_timerange = [14 18];
FULL_CLEAN_SEED = false;


%% parameter sweep pipeline
% Create the CONFIGURATION struct

ctapID = 'hydra_pipe_test_test';
PREPRO = true;
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;
OVERWRITE_SYNDATA = false;
erploc = 'A31';


% First, define step sets and their parameters

[Cfg, ~] = sbf_cfg(PROJECT_ROOT, ctapID);
data_type = '*.set';
data_dir_seed = append(REPO_ROOT,'ctap/data/test_data');

% BCI dataset needs generate artifacts, hence we run data generation here, other data with artifacts don't need this

data_dir = fullfile(Cfg.env.paths.projectRoot, 'data', 'HYDRA');
if ( isempty(dir(fullfile(data_dir,'*.set'))) || OVERWRITE_SYNDATA)
    % Normally this is run only once
    generate_synthetic_data_demo(data_dir_seed, data_dir);
end
data_dir_seed = data_dir;


% Select measurements to process

sbj_filt = 1; 

% Next, create measurement config (MC) based on folder of synthetic source 
% files, & select subject subset.

Cfg = get_meas_cfg_MC(Cfg, data_dir_seed, 'eeg_ext', data_type, 'sbj_filt', sbj_filt); 
% create HYDRA field in cfg structure
if HYDRA
    Cfg.HYDRA.ifapply = HYDRA;
    Cfg.HYDRA.chanloc = CH_FILE;
    Cfg.HYDRA.cleanseed_timerange = cleanseed_timerange;
    Cfg.HYDRA.PARAM = PARAM;
    Cfg.HYDRA.FULL_CLEAN_SEED = FULL_CLEAN_SEED;
end
% Select pipe array and first and last pipe to run
pipeArr = {@sbf_pipe1,...
    @sbf_pipe2,...
    @sbf_pipe3n,...
    @sbf_pipe4,...
    @sbf_pipe4n
    };

runps = 1:length(pipeArr);


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
%config eeg info
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
    Cfg.eeg.chanlocs = 'chanlocs128_biosemi_withEOG.elp';
    % Define other important stuff
    Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};


    % EOG channel specification for artifact detection purposes
    Cfg.eeg.veogChannelNames = {'VEOG1','VEOG2'};
    Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};

    % dummy var
    out = struct([]);
end


%% Configure pipe 1
%first loading data
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
                        @CTAP_run_ica
                         };
    %@CTAP_peek_data,...
    stepSet(i).id = [num2str(i) '_load'];

    out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
        'assist', true);
    out.fir_filter = struct(...
        'locutoff', 1,...
        'hicutoff', 45);
    out.run_ica = struct(...
        'method', 'fastica',...
        'overwrite', true);
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
    stepSet(i).funH = { @CTAP_hydra_prepare,...
                        @CTAP_hydra_blink,...                      
                        @CTAP_detect_bad_comps,...         
                        @CTAP_reject_data,...
                        @CTAP_peek_data
                         };
    stepSet(i).id = [num2str(i) '_badcomps_correction'];
    
    out.run_ica.channels = {'EEG' 'EOG'};
    out.detect_bad_comps.method = 'blink_template';
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end

%% pipe 2n
function [Cfg, out] = sbf_pipe2n(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2n';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,...         
                        @CTAP_reject_data,...
                        @CTAP_peek_data
                         };
    stepSet(i).id = [num2str(i) '_badcomps_correction'];
    
    out.run_ica.channels = {'EEG' 'EOG'};
    out.detect_bad_comps.method = 'blink_template';
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe 3 detected bad segments
function [Cfg, out] = sbf_pipe3(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe3';
    Cfg.srcid = {'pipe1#1_load'};
    %%%%%%%% Define pipeline %%%%%%%%
   
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_hydra_prepare,...
                        @CTAP_hydra_badseg,...
                        @CTAP_detect_bad_segments,...
                        @CTAP_reject_data,...
                        @CTAP_peek_data
                         };
    stepSet(i).id = [num2str(i) '_badseg_correction'];
    
    out.detect_bad_segments = struct(...
        'method', 'quantileTh'); %in muV
%     'channels', {ampthChannels}, ...
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end

%% Configure pipe 3 detected bad segments
function [Cfg, out] = sbf_pipe3n(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe3n';
    Cfg.srcid = {'pipe1#1_load'};
    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_segments,...
                        @CTAP_reject_data,...
                        @CTAP_peek_data
                         };
    stepSet(i).id = [num2str(i) '_badseg_correction'];
    
    out.detect_bad_segments = struct(...
        'method', 'quantileTh'); %in muV
%     'channels', {ampthChannels}, ...
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end

%% Configure pipe 4 detected bad components
function [Cfg, out] = sbf_pipe4(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe4';
    Cfg.srcid = {'pipe1#1_load'};
    %%%%%%%% Define pipeline %%%%%%%%
    i = 1;  
    
    stepSet(i).funH = {
        @CTAP_hydra_prepare,...
        @CTAP_hydra_chan,...
        @CTAP_detect_bad_channels,...
        @CTAP_reject_data,...
        @CTAP_interp_chan,...
        @CTAP_peek_data
        };
                     
    stepSet(i).id = [num2str(i) '_badchan_correction'];
     
    out.detect_bad_channels = struct(...
        'method', 'maha_fast',...
        'channelType', {'EEG'});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end


%% Configure pipe 4 detected bad components
function [Cfg, out] = sbf_pipe4n(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe4n';
    Cfg.srcid = {'pipe1#1_load'};
    %%%%%%%% Define pipeline %%%%%%%%
    i = 1;  
    
    stepSet(i).funH = {...
        @CTAP_detect_bad_channels,...%bad channels by variance
        @CTAP_reject_data,...
        @CTAP_interp_chan,...
        @CTAP_peek_data
        };
                     
    stepSet(i).id = [num2str(i) '_badchan_correction'];
     
    out.detect_bad_channels = struct(...
        'method', 'maha_fast',...
        'channelType', {'EEG'});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end
