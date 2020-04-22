% generate synthetic data and detect bad channels from it
% Note:
%   * assumes PROJECT_ROOT to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
% PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra';

%% General setup
BRANCH_NAME = 'ctap_hydra_badchan';

FILE_ROOT = mfilename('fullpath');
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'test_param_sweep_sdgen_badchan')) - 1);


RERUN_PREPRO = true;
RERUN_SWEEP = true;

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = param_sweep_setup(PROJECT_ROOT);

PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_channels');
mkdir(PARAM.path.sweepresDir);


%% CTAP config
CH_FILE = 'chanlocs128_biosemi.elp';

Cfg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
Cfg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Cfg.grfx.on = true;

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

%{
i = i+1; 
Pipe(i).funH = {@CTAP_run_ica}; 
Pipe(i).id = [num2str(i) '_ICA'];

i = i+1; 
Pipe(i).funH = {@CTAP_blink2event}; 
Pipe(i).id = [num2str(i) '_tmp'];

clear('PipeParams');
PipeParams.run_ica.method = 'fastica';
PipeParams.run_ica.overwrite = true;
PipeParams.run_ica.channels = {'EEG' 'EOG'};
PipeParams.detect_bad_comps.method = 'blink_template';
%}

PipeParams = struct([]);

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;
Cfg = ctap_auto_config(Cfg, PipeParams);


%% Sweep config
i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_channels,... %detect bad channels
                    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_badchan_correction'];

SWPipeParams.detect_bad_channels.method = 'variance';

SweepParams.funName = 'CTAP_detect_bad_channels';
SweepParams.paramName = 'bounds';
SweepParams.values = num2cell(1.5:0.3:7);


%% Run preprocessing pipe
if RERUN_PREPRO
%     clear('Filt')
%     Filt.subjectnr = 1;
%     Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);
    
    Cfg.pipe.runMeasurements = {Cfg.MC.measurement.casename};
    
    CTAP_pipeline_looper(Cfg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
end

                
%% Sweep                                   
if RERUN_SWEEP
    for k = 1:numel(Cfg.MC.measurement)

        k_id = Cfg.MC.measurement(k).casename;

        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        %inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
        inpath = fullfile(Cfg.env.paths.analysisRoot, '1_loaddata');
        infile = sprintf('%s.set', k_id);

        EEGprepro = pop_loadset(infile, inpath);

        % Note: This step does sweeping ONLY, preprocess using some other means
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(...
                            EEGprepro, SWPipe, SWPipeParams, Cfg, SweepParams);
        sweepres_file = fullfile(PARAM.path.sweepresDir, ...
                                 sprintf('sweepres_%s.mat', k_id));
        save(sweepres_file...
            , 'SWEEG', 'PARAMS','SWPipe','PipeParams', 'SweepParams', '-v7.3');
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
    CTAP_inpath = fullfile(Cfg.env.paths.analysisRoot, '1_loaddata');
    CTAP_infile = sprintf('%s.set', k_id);
    EEGprepro = pop_loadset(CTAP_infile, CTAP_inpath);
    
    % Sweep results
    sweepres_file =...
        fullfile(PARAM.path.sweepresDir, sprintf('sweepres_%s.mat', k_id));
    load(sweepres_file);
    
    %Number of blink related components
    n_sweeps = numel(SWEEG);
    dmat = NaN(n_sweeps, 2);
    cost_arr = NaN(n_sweeps, 1);

    ep_win = [-1, 1]; %sec
    ch_inds = horzcat(78:83, 91:96); %frontal
    EEGclean.event = EEGprepro.event;
    EEG_clean_ep = pop_epoch( EEGclean, {'blink'}, ep_win);

    tmp_savedir = fullfile(PARAM.path.sweepresDir, k_id);
    mkdir(tmp_savedir);
    for i = 1:n_sweeps
        dmat(i,:) = [SweepParams.values{i},...
                    numel(SWEEG{i}.CTAP.badchans.variance.chans) ];
        myReport(sprintf('mad: %1.2f, n_chans: %d\n', dmat(i,1), dmat(i,2))...
            , fullfile(tmp_savedir, 'sweeplog.txt'));

        % PLOT BAD CHANS
        chinds = get_eeg_inds(EEGprepro, SWEEG{i}.CTAP.badchans.variance.chans);
        if any(chinds)
            figh = ctaptest_plot_bad_chan(EEGprepro, chinds...
                , 'context', sprintf('sweep-%d', i)...
                , 'savepath', tmp_savedir);
        end
    end
    %plot(cost_arr, '-o')

    figH = figure();
    plot(dmat(:,1), dmat(:,2), '-o');
    xlabel('MAD multiplication factor');
    ylabel('Number of artefactual channels');
    saveas(figH, fullfile(PARAM.path.sweepresDir,...
            sprintf('sweep_N-bad-chan_%s.png', k_id)));
    close(figH);


    %% Test quality of identifications
    %SweepParams.values
    %EEG.CTAP.artifact.variance.channel_idx
    %EEG.CTAP.artifact.variance.multiplier

    th_value = 2;
    th_idx = find( [SweepParams.values{:}] <= th_value , 1, 'last' );

    %SWEEG{th_idx}.CTAP.badchans.variance.chans

    % channels identified as artifactual which are actually clean
    setdiff(SWEEG{th_idx}.CTAP.badchans.variance.chans, ...
            EEG.CTAP.artifact.variance_table.name)

    % wrecked channels not identified
    tmp2 = setdiff(EEG.CTAP.artifact.variance_table.name, ...
            SWEEG{th_idx}.CTAP.badchans.variance.chans);

    chm = ismember(EEG.CTAP.artifact.variance_table.name, tmp2);
    EEG.CTAP.artifact.variance_table(chm,:)   

    clear('SWEEG');
    
    
    
    
    
end
