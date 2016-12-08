function [Cfg, out] = cfg_pipe1(Cfg)


%% Define hierarchy
Cfg.id = 'pipe1';
Cfg.srcid = {''};


%% Define pipeline

% Load data
i = 1;
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_tidy_chanlocs,...
                    @CTAP_reref_data,... 
                    @CTAP_blink2event,...
                    @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_load'];

out.load_data = struct(...
    'type', 'set'); %also requires data path from Cfg.MC

out.load_chanlocs = struct(...%chanlocs file path comes from Cfg.eeg.chanlocs
    'assist', true);

out.tidy_chanlocs.types =...
    {{'1:128' 'EEG'}, {'131 132' 'REF'}, {'129 130 133 134' 'EEG'}};

out.peek_data.peekevent = {'sa_blink'};
out.peek_data.channels = {'C17','C18','C19','C21','C1','A3','A19','A21'};
out.peek_data.secs = 10;
out.peek_data.logStats = false; %todo: normfit.m missing...


% Filter data
i = i +1;
stepSet(i).funH = { @CTAP_fir_filter};
stepSet(i).id = [num2str(i) '_filter'];

out.fir_filter = struct(...
    'lowcutoff', 2,...
    'hicutoff', 30);

out.peek_data.logStats = false; %todo: normfit.m missing...


%% Store to Cfg
Cfg.pipe.stepSets = stepSet;
Cfg.pipe.runSets = {stepSet(:).id};