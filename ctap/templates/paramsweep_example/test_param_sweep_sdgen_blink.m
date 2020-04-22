% generate synthetic data, detect blink related ICs from it and remove them
%
% Note:
%   * assumes PROJECT_ROOT to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
% PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra';

%% General setup
FILE_ROOT = mfilename('fullpath');
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'test_param_sweep_sdgen_blink')) - 1);


BRANCH_NAME = 'ctap_hydra_blink';

RERUN_PREPRO = true;
RERUN_SWEEP = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = param_sweep_setup(PROJECT_ROOT);

PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_blinks');
mkdir(PARAM.path.sweepresDir);


%% CTAP config
CH_FILE = 'chanlocs128_biosemi.elp';

Cfg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
Cfg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Cfg.grfx.on = false;

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(PARAM.path.synDataRoot, '*.set');
Cfg.MC = MC;

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1; 
Pipe(i).funH = {@CTAP_load_data,...
                @CTAP_blink2event,...
                @CTAP_generate_cseg}; 
Pipe(i).id = [num2str(i) '_loaddata'];

i = i+1; 
Pipe(i).funH = {@CTAP_run_ica}; 
Pipe(i).id = [num2str(i) '_ICA'];

i = i+1; 
Pipe(i).funH = {@CTAP_blink2event}; 
Pipe(i).id = [num2str(i) '_tmp'];

clear('PipeParams'); %to avoid errors
PipeParams.run_ica.method = 'fastica';
PipeParams.run_ica.overwrite = true;
PipeParams.run_ica.channels = {'EEG' 'EOG'};
PipeParams.detect_bad_comps.method = 'blink_template';

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;

Cfg = ctap_auto_config(Cfg, PipeParams);


%% Sweep config
%{
i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_filter_blink_ica}; %correct ICs using FIR filter
SWPipe(i).id = [num2str(i) '_blink_correction'];
%}

i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_blink_correction'];

SweepParams.funName = 'CTAP_detect_bad_comps';
SweepParams.paramName = 'thr';
SweepParams.values = num2cell(linspace(1.3, 1.5, 30));


%% Run preprocessing pipe for all datasets in Cfg.MC
if RERUN_PREPRO

%     clear('Filt')
%     Filt.subjectnr = 1;
%     Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);
    
    Cfg.pipe.runMeasurements = {Cfg.MC.measurement.casename};
    
    CTAP_pipeline_looper(Cfg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
end
% TODO: possible bug if RECOMPUTE_SYNDATA & RERUN_PREPRO == 0, as resulting
% datasets might have mismatched dimensions

                
%% Sweep (all files in Cfg.MC)

if RERUN_SWEEP
    for k = 1:numel(Cfg.MC.measurement)

        k_id = Cfg.MC.measurement(k).casename;

        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        %inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
        inpath = fullfile(Cfg.env.paths.analysisRoot, '2_ICA');
        infile = sprintf('%s.set', k_id);

        EEGprepro = pop_loadset(infile, inpath);

        % Note: This step does sweeping ONLY, preprocess using some other means
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, PipeParams, Cfg, ...
                                          SweepParams);
        sweepres_file = fullfile(PARAM.path.sweepresDir, ...
                                 sprintf('sweepres_%s.mat', k_id));
        save(sweepres_file, 'SWEEG', 'PARAMS','SWPipe','PipeParams', 'SweepParams',...
        '-v7.3');
        clear('SWEEG');
    end
end


                     
%% Analyze
for k = 1:numel(Cfg.MC.measurement)
%for k = 1

    k_id = Cfg.MC.measurement(k).casename;
    k_synid = strrep(Cfg.MC.measurement(k).subject,'_syndata','');
    
    % Load needed datasets
    % Original data (for synthetic datasets)
    
    [EEG, EEGart, EEGclean] = param_sweep_sdload(k_synid, PARAM);
           
    % CTAP data that the sweep was based on
    CTAP_inpath = fullfile(Cfg.env.paths.analysisRoot, '2_ICA');
    CTAP_infile = sprintf('%s.set', k_id);
    EEGprepro = pop_loadset(CTAP_infile, CTAP_inpath);
    
    % Sweep results
    sweepres_file = fullfile(PARAM.path.sweepresDir, ...
                             sprintf('sweepres_%s.mat', k_id));
    load(sweepres_file);
    
  
    %Number of blink related components
    n_sweeps = numel(SWEEG);
    dmat = NaN(n_sweeps, 2);
    cost_arr = NaN(n_sweeps, 1);
    diffA = NaN(n_sweeps, 1);
    % wU = NaN(n_sweeps, 1);

    % TODO: PARAMETERIZE THESE VALUES??
    ep_win = [-1, 1]; %sec
    ch_inds = horzcat(78:83, 91:96); %frontal

    %Create epoched observed/input data
    % EEG_obser_ep = pop_epoch(EEGprepro, {'blink'}, ep_win);
    %Create comparison basis EEG as combo of clean synth EEG + non-blink artifacts
    EEG_basis_ep = EEGprepro;
    EEG_basis_ep.data = EEGclean.data + EEGart.wrecks + EEGart.myo;
    EEG_basis_ep = pop_epoch(EEG_basis_ep, {'blink'}, ep_win);
    %Create epoched blink data only
    % EEG_blink_ep = EEGprepro;
    % EEG_blink_ep.data = EEGart.blinks;
    % EEG_blink_ep = pop_epoch(EEG_blink_ep, {'blink'}, ep_win);

    % output directory for blink-ERPs
    blinkerp_dir = fullfile(PARAM.path.sweepresDir, 'blink-ERP', k_id);
    mkdir(blinkerp_dir);

    for i = 1:n_sweeps
        dmat(i,:) = [SweepParams.values{i},...
                    numel(SWEEG{i}.CTAP.badcomps.blink_template.comps) ];
        fprintf('\nangle_rad: %1.2f, n_B_comp: %d\n\n', dmat(i,1), dmat(i,2));

        EEG_sweep_ep = pop_epoch( SWEEG{i}, {'blink'}, ep_win);
        cost_arr(i) = sum(sum(sum(abs(  EEG_basis_ep.data(ch_inds,:,:) - ...
                                        EEG_sweep_ep.data(ch_inds,:,:)  ))));    
        %UTILITY FUNCTION AS PER HYDRA PAPER - continuous
    %     diffS = sum(sum(sum(abs(...
    %             EEG_basis_ep.data(ch_inds,:,:) -...%signal S
    %             EEG_sweep_ep.data(ch_inds,:,:) ...%signal estimate S'
    %             ))));
    %     diffA(i) = sum(sum(sum(abs(...
    %             EEG_blink_ep.data(ch_inds,:,:) -...%artefacts A
    %             (EEG_obser_ep.data(ch_inds,:,:) - EEG_sweep_ep.data(ch_inds,:,:)) ...%artefact estimate A'
    %             ))));
    %     U(i) = diffS + diffA;

        %%{
        %PLOT BLINK ERP PER SWEEP
        subplot(n_sweeps, 1, i);
        fh_tmp = ctap_eeg_compare_ERP(EEGprepro,SWEEG{i}, {'blink'},...
                    'idArr', {'before rejection','after rejection'},...
                    'channels', {'C17'},...
                    'visible', 'off');
        savename = sprintf('sweep_blink-ERP_%d.png', i);
        savefile = fullfile(blinkerp_dir, savename);
        print(fh_tmp, '-dpng', savefile);
        close(fh_tmp);
        %}
    end
    plot(cost_arr)

    figH = figure();
    plot(dmat(:,1), dmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('Number of blink related IC components');
    saveas(figH, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink-IC_%s.png', k_id)));
    close(figH);

    %SweepParams.values
    %SWEEG{1}.CTAP.badcomps.blink_template.comps

    clear('SWEEG');
end
