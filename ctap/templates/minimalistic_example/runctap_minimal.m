%% Minimal CTAP batchfile
DEBUG = false;
OVERWRITE_SYNDATA = false; %can be used to re-create synthetic data

%% Setup
reporoot = mfilename('fullpath');
reporoot = reporoot(1:strfind(reporoot, fullfile(...
    'ctap', 'templates', 'minimalistic_example', 'runctap_minimal')) - 1);

project_dir = fullfile(reporoot, 'example-project');
if ~isdir(project_dir), mkdir(project_dir); end;

[Cfg, ctap_args] = cfg_minimal(project_dir);


%% Create synthetic data (only if needed)
% Note: Cfg needed to set data_dir_out
data_dir_seed = fullfile(reporoot, 'ctap', 'data', 'test_data');
data_dir = fullfile(Cfg.env.paths.projectRoot, 'data', 'demo');
if ( isempty(dir(fullfile(data_dir,'*.set'))) || OVERWRITE_SYNDATA)
    % Normally this is run only once
    generate_synthetic_data_demo(data_dir_seed, data_dir);
end


%% Create measurement config (MC) based on folder
% Select measurements to process
sbj_filt = 1; 
% Next, create measurement config (MC) based on folder of synthetic source 
% files, & select subject subset
Cfg = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', '*.set', 'sbj_filt', sbj_filt);


%% Define pipeline
clear('stepSet');
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_reref_data,... 
                    @CTAP_blink2event,...
                    @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_load'];

i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_fir_filter };
stepSet(i).id = [num2str(i) '_filter'];

i = i+1;  %stepSet 3
stepSet(i).funH = { @CTAP_run_ica };
stepSet(i).id = [num2str(i) '_ICA'];
stepSet(i).srcID = '';
% ICA can take ages -> hence a cut here

i = i+1;  %stepSet 4
stepSet(i).funH = { @CTAP_detect_bad_comps,...
                    @CTAP_reject_data,...
                    @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_IC_CORRECTION'];

i = i+1;  %stepSet 5
stepSet(i).funH = { @CTAP_detect_bad_channels,... %variance thresholds need adjustmet!
                    @CTAP_reject_data,...
                    @CTAP_interp_chan,...
                    @CTAP_detect_bad_segments,... 
                    @CTAP_reject_data};
stepSet(i).id = [num2str(i) '_ARTEFACT_CORRECTION'];

i = i+1; %stepSet 6
stepSet(i).funH = { @CTAP_generate_cseg,...
                    @CTAP_compute_psd,...
                    @CTAP_extract_bandpowers,...
                    @CTAP_extract_PSDindices };
stepSet(i).id = [num2str(i) '_PSD_and_features'];
%}

Cfg.pipe.stepSets = stepSet;


%% Select sets to process
%here any stepSet subset can be indexed numerically or logically
Cfg.pipe.runSets = {stepSet(1).id}; %by position index
%Cfg.pipe.runSets = {'test'}; %by name
% Cfg.pipe.runSets = {'all'}; %whole thing


%% Assign arguments to the selected functions, perform various checks
Cfg = ctap_auto_config(Cfg, ctap_args);


%% Run the pipe
tic;
CTAP_pipeline_looper(Cfg, 'debug', DEBUG, 'overwrite', true)
toc;


%% Export features
tic;
export_features_CTAP([Cfg.id '_db'], {'bandpowers','PSDindices'}, Cfg.MC, Cfg);
toc;

%% Cleanup
clear i stepSet Filt ctap_args
