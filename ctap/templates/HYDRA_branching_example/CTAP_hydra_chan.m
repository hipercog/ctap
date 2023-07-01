function [EEG,Cfg] = CTAP_hydra_chan(EEG, Cfg)

% sweep the provided value range and decide the best parameter
%
% Note:
%   * assumes ctap root to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
%   * all parameter need should attached to Cfg.ctap.detect_bad_channels and pass Cfg as function parameter.
%
% Syntax:
%   [EEG, Cfg] = CTAP_test_chan(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_channels:
%   .method       string/char
%   .values       numerical array
%   Other arguments as in ctapeeg_detect_bad_channels().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%   Cfg.ctap.detect_bad_channels:
%   .(paramName)   paramName see ctapeeg_detect_bad_channels, each
%                  methods have the corresponding paramName, and it's value
%                  should be the best parameter picked.
% ;

%% General setup
if ~Cfg.HYDRA.ifapply
    return
end

BRANCH_NAME = 'ctap_synthetic_pre_badchan';


RERUN_PREPRO = true;
RERUN_SWEEP = true;

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = Cfg.HYDRA.PARAM;
PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_channels');
mkdir(PARAM.path.sweepresDir);


%% CTAP config
CH_FILE = Cfg.HYDRA.chanloc;

Arg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
Arg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Arg.eeg.reference = Cfg.eeg.reference;
Arg.eeg.veogChannelNames = Cfg.eeg.veogChannelNames; %'C17' has highest blink amplitudes
Arg.eeg.heogChannelNames = Cfg.eeg.heogChannelNames;
Arg.grfx.on = true;

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(PARAM.path.synDataRoot, '*_bad_channels_syndata.set');
Arg.MC = MC;

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1;
Pipe(i).funH = {@CTAP_load_data};
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
method = Cfg.ctap.detect_bad_channels.method;
SWPipeParams.detect_bad_channels.method = method;
SweepParams.funName = 'CTAP_detect_bad_channels';
values = num2cell(1.5:0.3:7);
switch method         
    case 'maha_fast'
        SweepParams.paramName = 'factorVal';
        SweepParams.values =  values;

    case 'variance'
        SweepParams.paramName = 'bounds';
        lowbound = 3;
        for i=1:length(values)
            SweepParams.values{i}=[-lowbound; values{i}];
        end
end

test_id = [method , '_o'];



% Run preprocessing pipe
if RERUN_PREPRO

    
    Arg.pipe.runMeasurements = {Arg.MC.measurement.casename};
    
    if (isempty(dir(fullfile(Arg.env.paths.analysisRoot, '1_loaddata'))))
        CTAP_pipeline_looper(Arg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
    end
end


% Sweep
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
    
    k_id = Arg.MC.measurement(k).casename;
    k_synid = strrep(Arg.MC.measurement(k).subject,'_syndata','');
    
    % Load needed datasets
    % Original data (for synthetic datasets)
    %[EEG_n, EEGart, EEGclean] = param_sweep_sdload(k_synid, PARAM);
    
    % CTAP data that the sweep was based on
    CTAP_inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
    CTAP_infile = sprintf('%s.set', k_id);
    EEGprepro = pop_loadset(CTAP_infile, CTAP_inpath);
    
    %get injected channel name
    artifact_chanloc = strings(numel(EEGprepro.CTAP.artifact.variance), 1);
    for j=1:numel(EEGprepro.CTAP.artifact.variance)
        artifact_chanloc(j) = string(EEGprepro.chanlocs(EEGprepro.CTAP.artifact.variance(j).channel_idx).labels);
    end
        
    % Sweep results
    sweepres_file =...
        fullfile(PARAM.path.sweepresDir, sprintf('sweepres_%s.mat', k_id));
    load(sweepres_file);
    
    %Number of blink related components
    n_sweeps = numel(SWEEG);
    dmat = zeros(n_sweeps, 2);
  
    dmmat = zeros(n_sweeps, 3);
    performance = zeros(n_sweeps, 3);
    performance1 = zeros(n_sweeps, 3);

    tmp_savedir = fullfile(PARAM.path.sweepresDir, k_id);
    mkdir(tmp_savedir);
    for i = 1:n_sweeps
        dmat(i,:) = [values{i},...
                    numel(SWEEG{i}.CTAP.badchans.(method).chans)];
        count = 0;
        for n=1:numel(SWEEG{i}.CTAP.badchans.(method).chans)
            if(ismember(SWEEG{i}.CTAP.badchans.(method).chans(n),artifact_chanloc))
                count=count+1;
            end
        end
        dmmat(i,:) = [values{i},...
                    count...
                    numel(SWEEG{i}.CTAP.badchans.(method).chans)];
        myReport(sprintf('mad: %1.2f, n_chans: %d, n_true_badchans:%d\n', dmmat(i,1), dmmat(i,3), dmmat(i,2))...
            , fullfile(tmp_savedir, 'sweeplog.txt'));
        
        % PLOT BAD CHANS
        badness = numel(SWEEG{i}.CTAP.badchans.(method).chans);
        chinds = get_eeg_inds(EEGprepro, SWEEG{i}.CTAP.badchans.(method).chans);
        if any(chinds)
            figh = ctaptest_plot_bad_chan(EEGprepro, chinds...
                    , 'context', sprintf('sweep-%d', i)...
                    , 'savepath', tmp_savedir);
        end
        
        
        sensitivity = count/PARAM.syndata.WRECK_N;
        specificity = (SWEEG{i}.nbchan-10-badness+count)/(SWEEG{i}.nbchan-10);
        TPR = sensitivity; 
        FPR = (badness-count)/(SWEEG{i}.nbchan-10);
        performance(i,:) = [values{i},...
                        sensitivity...
                        specificity];
        performance1(i,:) = [values{i},...
                        FPR,...
                        TPR];
                    
        myReport(sprintf('mad: %1.2f, sensitivity(TPR): %1.2f, specificity: %1.2f, FPR: %1.2f\n', performance(i,1), performance(i,2), performance(i,3),performance1(i,2))...
            , fullfile(tmp_savedir, 'sweep_performence_log.txt'));
    end
    
    save(fullfile(PARAM.path.sweepresDir,...
                    sprintf('sweep_badchan_%s_%s.mat', k_id, test_id )),'dmmat');
    gt = zeros(n_sweeps,1)+numel(EEGprepro.CTAP.artifact.variance);           
    %plot Number of artefactual channels detected
    figH_1 = figure();
    plot(dmmat(:,1), dmmat(:,2),'--o',dmmat(:,1), dmmat(:,3),'--*',dmmat(:,1),gt(:),'--x')
    xlabel('MAD multiplication factor');
    ylabel('Number of artefactual channels');
    legend('The number of detected coincidence with generated badchan','badchan detected','ground truth')
    saveas(figH_1, fullfile(PARAM.path.sweepresDir,...
                        sprintf('sweep_N-bad-chan-num-meets_%s_%s.png', k_id,  SWPipeParams.detect_bad_channels.method)));
    close(figH_1);
    
    %plot performance of different parameters
    figH_2 = figure();
    plot(performance(:,1), performance(:,2),'--o',performance(:,1), performance(:,3),'--*')
    xlabel('MAD multiplication factor');
    ylabel('performance');
    legend('sensitivity','specificity')
    saveas(figH_2, fullfile(PARAM.path.sweepresDir,...
                sprintf('sweep_N-bad-chan-performance_%s_%s.png', k_id,  SWPipeParams.detect_bad_channels.method)));
    close(figH_2);
    
    %plot ROC space 
    figH_3 = figure();
    x = linspace(0,1);
    y = x;
    p = performance1(:,1);
    plot(performance1(:,2), performance1(:,3),'o',x,y,'--')
    xlabel('FPR');
    ylabel('TPR');
    for i=1:length(p)
        text(performance1(i,2), performance1(i,3),num2str(i));
    end
    title('ROC Space')
    saveas(figH_3, fullfile(PARAM.path.sweepresDir,...
                        sprintf('sweep_N-bad-chan-performance1_%s_%s.png', k_id,  SWPipeParams.detect_bad_channels.method)));
    close(figH_3);
    
    
    
    
    %% pick best bounds parameter and update Cfg
    dist_p = zeros(n_sweeps, 1);
    for i = 1:n_sweeps
        dist_p(i) = sqrt((0-performance1(i,2))^2+(1-performance1(i,3))^2);
    end   
    [M,I] = min(dist_p);
    res =  cell2mat(values(I));

    pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
    switch method
        case 'maha_fast'
            SWPipeParams.(pipeFun).(SweepParams.paramName) = res;
            Cfg.ctap.(pipeFun).(SweepParams.paramName) = res;
            
        case 'variance'
            SWPipeParams.(pipeFun).(SweepParams.paramName) = [-lowbound;res];
            Cfg.ctap.(pipeFun).(SweepParams.paramName) = [-lowbound;res];
    end

    
   
    msg = myReport(sprintf('the best parameter: %f', res)...
        , Cfg.env.logFile);
    EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, SWPipeParams.(pipeFun));
    
    clear('SWEEG');

end
end