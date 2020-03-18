%% HYDRA synthetic CTAP batchfile


disp(batch_id);
%% Load configurations
% Select configuration file to use
cfg_HYDRAKING;

Cfg.MC = read_measinfo_fromfiles(Cfg.env.paths.projectRoot, ...
    ['*.' my_args.load_data.type], ...
    {'[0-9]{3,4}', 0}, ...
    {'[0-9]{3,4}', 0, 4});
% A simplistic option:
% Cfg.MC = path2measconf(Cfg.env.paths.projectRoot, ['*.' my_args.load_data.type]);


%% Select measurements to process
% Select measurements to run
clear('Filt');
Filt.subjectnr = [Cfg.MC.measurement(1:numel(Cfg.MC.subject)).subjectnr];
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);


%% Define pipeline
clear('stepSet');
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data, ...
                    @CTAP_detect_bad_channels, ...
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_load_clean_chans'];
stepSet(i).srcID = '';

i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_detect_bad_epochs, ...
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_clean_epochs'];
stepSet(i).srcID = '';

i = i+1; %stepSet 3
stepSet(i).funH = { @CTAP_run_ica, ...
                    @CTAP_detect_bad_comps, ...
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_clean_comps'];
stepSet(i).srcID = '';

Cfg.pipe.stepSets = stepSet;


%% Select sets to process
Cfg.pipe.runSets = {'all'};
% here any stepSet subset can be indexed numerically or logically
% Cfg.pipe.runSets = {stepSet(1:3).id};


%% Assign arguments to the selected functions
Cfg = ctap_auto_config(Cfg, my_args);


%% Run the pipe
tic;
%CTAP_pipeline_looper(Cfg, 'debug', true);
CTAP_pipeline_looper(Cfg)
toc;

%% Comparison functions, output, etc

%% Cleanup
clear i my_args stepSet Filt batch_id
