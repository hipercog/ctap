%% Set path

FILE_ROOT = mfilename('fullpath');
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'paramsweep_example', 'evaluation')) - 1);
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'evaluation')) - 1);
CH_FILE = 'chanlocs128_biosemi.elp';


%% parameter sweep pipeline

ctapID = 'hydra_pipe_test';

RERUN_PREPRO = true;
PREPRO = true;
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;
OVERWRITE_SYNDATA = false
erploc = 'A31';


[Cfg, ~] = sbf_cfg(PROJECT_ROOT, ctapID);

data_dir_seed = append(REPO_ROOT,'ctap/data');
data_dir = fullfile(Cfg.env.paths.projectRoot, 'syndata');
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
MC = path2measconf(data_dir, '*.set');
Cfg.MC = MC;
% Cfg = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', data_type, 'sbj_filt', sbj_filt);

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1; 
Pipe(i).funH = {@CTAP_load_data,...
                @CTAP_reref_data,...
                @CTAP_blink2event,...
                @CTAP_fir_filter,...
%                 @CTAP_run_ica
                };
            
Pipe(i).id = [num2str(i) '_loaddata'];

out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
    'assist', true);
out.fir_filter = struct(...
    'locutoff', 2,...
    'hicutoff', 30);

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;
Cfg = ctap_auto_config(Cfg, out);

%% Run preprocessing pipe
if RERUN_PREPRO
    Cfg.pipe.runMeasurements = {Cfg.MC.measurement.casename};
    CTAP_pipeline_looper(Cfg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
end

%% Sweep config
i = 1; 
HYDRAPipe(i).funH = {  
%                        @CTAP_detect_bad_comps,... %FASTER bad IC detection 
%                        @CTAP_reject_data,...
                       @CTAP_test_chan,...
                       @CTAP_detect_bad_channels,...%bad channels by variance
                       }; % reject ICs
HYDRAPipe(i).id = [num2str(i) 'HYRDA_ps'];

HYDRAPipeParams.detect_bad_channels.method = 'variance';       
HYDRAPipeParams.detect_bad_channels = struct(...
            'method', 'variance',...
            'channelType', {'EEG'});

inpath = fullfile(Cfg.env.paths.analysisRoot, '1_loaddata');
infile = sprintf('%s.set', Cfg.MC.measurement.casename);
EEG = pop_loadset(infile, inpath);
% Update pipe parameters
Cfg.ctap.detect_bad_comps = struct(...
            'method', {'blink_template'});    
Cfg.ctap.detect_bad_channels = struct(...
        'method', 'variance',...
        'channelType', {'EEG'});
for k = 1:numel(HYDRAPipe) %over step sets
    
    for m = 1:numel(HYDRAPipe(k).funH) %over analysis steps
        Cfg.pipe.current.set = k;
        Cfg.pipe.current.funAtSet = m;
        [EEG, Cfg] = HYDRAPipe(k).funH{m}(EEG, Cfg);
    end
end

save EEG


%% Normal Method Pipe
i = 1; 
NPipe(i).funH = {  
                       @CTAP_detect_bad_channels,...%bad channels by variance
                       };

NPipe(i).id = [num2str(i) 'Normal'];

NPipeParams.detect_bad_channels.method = 'variance';       
NPipeParams.detect_bad_channels = struct(...
            'method', 'variance',...
            'channelType', {'EEG'});

inpath = fullfile(Cfg.env.paths.analysisRoot, '1_loaddata');
infile = sprintf('%s.set', Cfg.MC.measurement.casename);
EEG_N = pop_loadset(infile, inpath);
% Update pipe parameters
Arg = Cfg
Arg.ctap.detect_bad_comps = struct(...
            'method', {'blink_template'});    
Arg.ctap.detect_bad_channels = struct(...
        'method', 'variance',...
        'channelType', {'EEG'});
for k = 1:numel(HYDRAPipe) %over step sets
    
    for m = 1:numel(NPipe(k).funH) %over analysis steps
        Arg.pipe.current.set = k;
        Arg.pipe.current.funAtSet = m;
        [EEG_N, Arg] = NPipe(k).funH{m}(EEG_N, Arg);
    end
end
        
%% get bad chan detected number for HYDRA and normal methods

badchans_n_hydra = numel(EEG.CTAP.badchans.variance.chans);
badchans_n_n = numel(EEG_N.CTAP.badchans.variance.chans);

clear('EEG');
clear('EEG_N');

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
