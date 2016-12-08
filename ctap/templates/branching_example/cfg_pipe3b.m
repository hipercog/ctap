function [Cfg, out] = cfg_pipe3b(Cfg)

%% Define hierarchy
Cfg.id = 'pipe3b';
Cfg.srcid = {'pipe1#pipe2#1_ICA'};


%% Define pipeline

% IC correction
%{
i = 1; 
stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_IC_correction'];
%}

% blink correction using IC rejection
i = 1;
stepSet(i).funH = { @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_reject_data,...
                    @CTAP_peek_data}; %correct ICs using FIR filter
stepSet(i).id = [num2str(i) '_blink_correction'];

out.detect_bad_comps = struct('method', 'blink_template');

out.peek_data.channels = {'C17','C18','C19','C21','C1','A3','A19','A21'};
out.peek_data.secs = 10;
out.peek_data.logStats = false; %todo: normfit.m missing...
out.peek_data.plotICA = false;


%% Store to Cfg
Cfg.pipe.stepSets = stepSet;
Cfg.pipe.runSets = {stepSet(:).id};