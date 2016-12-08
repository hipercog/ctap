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
% Measurement config based on synthetic source files
MC = path2measconf(data_dir_out, '*.set');


%% Select measurements to process
clear('Filt')
Filt.subjectnr = 1;


%% Select pipes
pipeArr = {@cfg_pipe1,...
           @cfg_pipe2,...
           @cfg_pipe3a,...
           @cfg_pipe3b};


%% Run
for i = 1:length(pipeArr)
%for i = 3:length(pipeArr) %run only a subset of pipes
    
    % Set Cfg
    [i_Cfg, i_ctap_args] = pipeArr{i}(Cfg);
    
    for k = 1:length(i_Cfg.srcid)
        
        %i_Cfg.env.paths = cfg_get_directories(i_Cfg, Cfg, i_Cfg.srcid{k});
        i_Cfg.env.paths = cfg_create_paths(Cfg.env.paths.ctapRoot,...
                                               i_Cfg.id, i_Cfg.srcid{k});
        i_Cfg = ctap_auto_config(i_Cfg, i_ctap_args);
        i_Cfg.MC = MC;
        
        % Run the pipe
        i_Cfg.pipe.runMeasurements = get_measurement_id(MC, Filt);
        CTAP_pipeline_looper(i_Cfg,...
                            'debug', STOP_ON_ERROR,...
                            'overwrite', OVERWRITE_OLD_RESULTS);
        
        export_features_CTAP([i_Cfg.id '_db'], {'bandpowers','PSDindices'},...
                              Filt, MC, i_Cfg);
    end
    
    % Cleanup
    clear('i_*');
end
