function [Cfg, out] = cfg_pipe2(Cfg)

%% Define hierarchy
Cfg.id = 'pipe2';
Cfg.srcid = {'pipe1#1_load'};


%% Define pipeline

% ICA
i = 1;
stepSet(i).funH = { @CTAP_run_ica};
stepSet(i).id = [num2str(i) '_ICA'];
% ICA can take ages -> hence a cut here

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG' 'EOG'};



%% Store to Cfg
Cfg.pipe.stepSets = stepSet;
Cfg.pipe.runSets = {stepSet(:).id};