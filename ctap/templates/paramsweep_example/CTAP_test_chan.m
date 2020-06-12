function [EEG,Cfg] = CTAP_test_chan(EEG, Cfg)



BRANCH_NAME = 'ctap_hydra_badchan';

FILE_ROOT = mfilename('fullpath');
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'CTAP_test_chan')) - 1);


RERUN_PREPRO = true;
RERUN_SWEEP = true;

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = param_sweep_setup(PROJECT_ROOT);

PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_channels');
mkdir(PARAM.path.sweepresDir);


%% CTAP config
CH_FILE = 'chanlocs128_biosemi.elp';

Arg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
Arg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Arg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Arg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Arg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Arg.grfx.on = true;

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(PARAM.path.synDataRoot, '*.set');
Arg.MC = MC;

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1;
Pipe(i).funH = {@CTAP_load_data,...
                @CTAP_blink2event,...
                @CTAP_generate_cseg};
Pipe(i).id = [num2str(i) '_loaddata'];


PipeParams = struct([]);

Arg.pipe.runSets = {'all'};
Arg.pipe.stepSets = Pipe;
Arg = ctap_auto_config(Arg, PipeParams);


%% Sweep config
i = 1;
SWPipe(i).funH = {  @CTAP_detect_bad_channels,... %detect bad channels
    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_badchan_correction'];

SWPipeParams.detect_bad_channels.method = 'variance';

SweepParams.funName = 'CTAP_detect_bad_channels';
SweepParams.paramName = 'bounds';
SweepParams.values = num2cell(1.5:0.3:7);


% Run preprocessing pipe
if RERUN_PREPRO
    %     clear('Filt')
    %     Filt.subjectnr = 1;
    %     Arg.pipe.runMeasurements = get_measurement_id(Arg.MC, Filt);
    
    Arg.pipe.runMeasurements = {Arg.MC.measurement.casename};
    
    CTAP_pipeline_looper(Arg,...
        'debug', STOP_ON_ERROR,...
        'overwrite', OVERWRITE_OLD_RESULTS);
end


%% Sweep
if RERUN_SWEEP
    for k = 1:numel(Arg.MC.measurement)
        
        k_id = Arg.MC.measurement(k).casename;
        
        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        %inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
        inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
        infile = sprintf('%s.set', k_id);
        
        EEGprepro = pop_loadset(infile, inpath);
        
        % Note: This step does sweeping ONLY, preprocess using some other means
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(...
            EEGprepro, SWPipe, SWPipeParams, Arg, SweepParams);
        sweepres_file = fullfile(PARAM.path.sweepresDir, ...
            sprintf('sweepres_%s.mat', k_id));
        save(sweepres_file...
            , 'SWEEG', 'PARAMS','SWPipe','PipeParams', 'SweepParams', '-v7.3');
        clear('SWEEG');
    end
end


%% Analyze
for k = 1:numel(Arg.MC.measurement)
    %for k = 1
    
    k_id = Arg.MC.measurement(k).casename;
    k_synid = strrep(Arg.MC.measurement(k).subject,'_syndata','');
    
    % Load needed datasets
    % Original data (for synthetic datasets)
    
    [EEG_n, EEGart, EEGclean] = param_sweep_sdload(k_synid, PARAM);
    
    % CTAP data that the sweep was based on
    CTAP_inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
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
    
    
    %% pick best bounds parameter and update Cfg
    bounds = dmat(:,1);
    channel_dected = dmat(:,2);
    res = bounds(1);
    cd = 0;
    for i = 1:numel(bounds)
        if channel_dected(i)<=PARAM.syndata.WRECK_N && channel_dected(i)> cd
            cd = channel_dected(i);
            res = bounds(i);
        end
    end
    
    res =  2.400000;
    pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
    SWPipeParams.(pipeFun).(SweepParams.paramName) = res;
    Cfg.ctap.(pipeFun) = SWPipeParams.(pipeFun);
    msg = myReport(sprintf('the best parameter:', res)...
        , Cfg.env.logFile);
    EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, SWPipeParams.(pipeFun));
    
    
    
 %end
end
