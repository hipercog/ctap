%% Minimal CTAP batchfile
%update_matlab_path_jkor_isomyy
%update_matlab_path_anyone
%clc

dataFile = which('eeglab_data.set');
dataRoot = fileparts(dataFile);


%% Load configurations

% Parameters
batch_id = 'eeglabmini';
[Cfg, my_args] = cfg_minimal_eeglab(dataRoot, cd(), batch_id);

% Data files
MC = path2measconf(dataRoot, '*_data.set');
%MC = read_measinfo_spreadsheet(Cfg.env.measurementInfo);
Cfg.MC = MC;


%% Select measurements to process
% Select measurements to run
clear('Filt');
Filt.subjectnr = 1; %all subjects 1:26
MeasSub = struct_filter(MC.measurement, Filt);
Cfg.pipe.runMeasurements = {MeasSub.casename};


%% Define pipeline
% These standard options not available in minimal setup:
% @CTAP_load_events

% Mysterious crashes:
% @CTAP_peek_data for stepSet #1

clear('stepSet');
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_tidy_chanlocs,...
                    @CTAP_reref_data};
                %@CTAP_peek_data
                %@CTAP_blink2event cannot be applied to the 4 minute
                %dataset since it does not contain clear blinks, more data
                %needed
stepSet(i).id = [num2str(i) '_load_WCST'];
stepSet(i).srcID = '';

i = i+1;  %stepSet 2
stepSet(i).funH = { @CTAP_filter_data};
stepSet(i).id = [num2str(i) '_filter'];
stepSet(i).srcID = '';
% filtering takes ages -> hence a cut here

i = i+1;  %stepSet 3
stepSet(i).funH = { @CTAP_run_ica};%,...
                 %   @CTAP_peek_data};
stepSet(i).id = [num2str(i) '_ICA'];
stepSet(i).srcID = '';
% ICA can take ages -> hence a cut here

i = i+1;  %stepSet 4
stepSet(i).funH = { @CTAP_detect_bad_comps,... %blinks
                    @CTAP_detect_bad_comps,... %ADJUST
                    @CTAP_reject_data,...
                    @CTAP_detect_bad_segments,...
                    @CTAP_reject_data,...
                    @CTAP_detect_bad_channels,...
                    @CTAP_reject_data,...
                    @CTAP_interp_chan};%,...
                    %@CTAP_peek_data};
stepSet(i).id = [num2str(i) '_ARTEFACT_CORRECTION'];
stepSet(i).srcID = '';

i = i+1; %stepSet 5
 stepSet(i).funH = { @CTAP_generate_cseg,...
                     @CTAP_compute_psd,...
                     @CTAP_extract_bandpowers,...
                     @CTAP_extract_PSDindices};
stepSet(i).id = [num2str(i) '_PSD_and_features'];
stepSet(i).srcID = '';

Cfg.pipe.stepSets = stepSet;

%% Select sets to process
%here any stepSet subset can be indexed numerically or logically
%
Cfg.pipe.runSets = {stepSet(1).id}; %by position index
%Cfg.pipe.runSets = {'all'}; %whole thing

%% Assign arguments to the selected functions
Cfg = cfg_ctap_functions(Cfg, my_args);

%% Run the pipe
%%{
tic;
CTAP_pipeline_looper(Cfg, 'debug', true)
% CTAP_pipeline_looper(Cfg)
toc;
%}

%% Export features
%{
tic;
export_features_CTAP([batch_id '_db'], {'bandpowers','PSDindices'},...
    Filt, MC, Cfg);
toc;
%}

%% Cleanup
clear i MC stepSet Filt batch_id my_args MeasSub
