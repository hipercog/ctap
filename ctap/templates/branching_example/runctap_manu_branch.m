%% An example draft of generic CTAP branching 
% Make sure your working directory is the CTAP root i.e. the folder with
% 'ctap' and 'dependencies'.


% On first run, create synthetic data:
OVERWRITE_SYNDATA = true;
% On subsequent runs, skip creation:
%OVERWRITE_SYNDATA = false;

% Runtime options for CTAP:
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Setup
project_dir = fullfile(cd(), 'example-project');
if ~isdir(project_dir), mkdir(project_dir); end;

[Cfg, ~] = cfg_base(project_dir);


%% Create synthetic data (only if needed)
% Note: Cfg needed to set data_dir_out
data_dir_seed = fullfile(cd(),'ctap','data');
data_dir_out = fullfile(Cfg.env.paths.projectRoot,'data','manuscript');
if ( isempty(dir(fullfile(data_dir_out,'*.set'))) || OVERWRITE_SYNDATA)
    % Normally this is run only once
    generate_synthetic_data_manuscript(data_dir_seed, data_dir_out);
end


%% Create measurement config (MC) based on folder
% Select measurements to process
sbj_filt = 1; 
% Next, create measurement config (MC) based on folder of synthetic source 
% files, & select subject subset
[Cfg.MC, Cfg.pipe.runMeasurements] =...
    confilt_meas_dir(data_dir_out, '*.set', sbj_filt);


%% Select pipes
pipeArr = {@cfg_pipe1,...
           @cfg_pipe2,...
           @cfg_pipe3a,...
           @cfg_pipe3b};
runps = 1:length(pipeArr);
%If the sources exist to feed the later pipes, you can also run only a subset:
% E.G. 2:length(pipeArr) OR [1 4]


%% Run the pipe
tic
    CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
toc
