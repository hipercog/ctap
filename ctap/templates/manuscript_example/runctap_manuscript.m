%% CTAP manuscript analysis batchfile
overwrite_syndata = true; %can be used to re-create synthetic data

%% Setup
project_dir = fullfile(cd(), 'example-project');
if ~isdir(project_dir), mkdir(project_dir); end;

[Cfg, ctap_args] = cfg_ctapmanu(project_dir);


%% Create synthetic data (only if needed)
% Note: Cfg needed to set data_dir_out
data_dir_seed = fullfile(cd(),'ctap','data');
data_dir_out = fullfile(Cfg.env.paths.projectRoot,'data','manuscript');
if ( isempty(dir(fullfile(data_dir_out,'*.set'))) || overwrite_syndata)
    % Normally this is run only once
    generate_synthetic_data_manuscript(data_dir_seed, data_dir_out);
end


%% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(data_dir_out, '*.set');
Cfg.MC = MC;


%% Select measurements to process
% Select measurements to run. WCST recordings included three subjects to
% reject: 11, 20 were >40yrs old, 23 was using voxra antidepressant.
clear('Filt')
%Filt.subjectnr = setdiff(1:34, [11, 20, 23]); %1:34 = all subjects
Filt.subjectnr = 1;
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);


%% Define pipeline
clear('stepSet');
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_tidy_chanlocs,...
                    @CTAP_reref_data,... 
                    @CTAP_blink2event,...
                    @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_load'];
% Not applicable but in WCST:
% @CTAP_load_events,...

%%{
i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_filter_data,... %makes amplitude hist narrower!
                    @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_filter'];
% filtering can take ages -> hence a cut here
% Not applicable but in WCST: 
% @CTAP_select_evdata

i = i+1;  %stepSet 3
stepSet(i).funH = { @CTAP_run_ica};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_ICA'];
% ICA can take ages -> hence a cut here

i = i+1;  %stepSet 4
stepSet(i).funH = { @CTAP_detect_bad_comps,... %blinks
                    @CTAP_reject_data,...
                    @CTAP_detect_bad_comps,... %ADJUST
                    @CTAP_reject_data};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_IC_CORRECTION'];

i = i+1;  %stepSet 5
stepSet(i).funH = { @CTAP_detect_bad_channels,... %variance thresholds need adjustmet!
                    @CTAP_reject_data,...
                    @CTAP_detect_bad_segments,... 
                    @CTAP_reject_data,...
                    @CTAP_interp_chan};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_ARTEFACT_CORRECTION'];

i = i+1; %stepSet 6
stepSet(i).funH = { @CTAP_run_ica };
stepSet(i).id = [num2str(i) '_clean_ICA'];
%}

i = i+1; %stepSet 7
stepSet(i).funH = { @CTAP_generate_cseg,...
                    @CTAP_compute_psd,...
                    @CTAP_extract_bandpowers,...
                    @CTAP_extract_PSDindices};
stepSet(i).id = [num2str(i) '_PSD_and_features'];
%}


%%{
i = i+1; %stepSet 8
stepSet(i).funH = {@CTAP_blink2event};
stepSet(i).id = 'test';
stepSet(i).srcID = '1_load';
%}

Cfg.pipe.stepSets = stepSet;

%% Select sets to process
%here any stepSet subset can be indexed numerically or logically
Cfg.pipe.runSets = {stepSet([5]).id}; %by position index
%Cfg.pipe.runSets = {'test'}; %by name
%Cfg.pipe.runSets = {'all'}; %whole thing


%% Assign arguments to the selected functions, perform various checks
Cfg = cfg_ctap_functions(Cfg, ctap_args);


%% Run the pipe
%{
tic;
CTAP_pipeline_looper(Cfg, 'debug', true, 'overwrite', true)
% CTAP_pipeline_looper(Cfg)
toc;
%}


%% Export features
%{
tic;
export_features_CTAP([Cfg.id '_db'], {'bandpowers','PSDindices'},...
    Filt, Cfg.MC, Cfg);
toc;
%}

%% Cleanup
clear i stepSet Filt ctap_args
