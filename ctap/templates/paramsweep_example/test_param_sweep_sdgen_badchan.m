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
%                  @CTAP_blink2event,...
%                  @CTAP_generate_cseg
                }; 
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

method = 'variance';
%method = 'maha_fast';
SWPipeParams.detect_bad_channels.method = method;
SweepParams.funName = 'CTAP_detect_bad_channels';
values = num2cell(1.5:0.3:7);
switch method
%     case 'recufast'
%         bounds_value = num2cell(1.5:0.3:7);
%         iters_value = num2cell(1:5);
%         for m=1:numel(bounds_value)
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

%test_id = [method , '_o'];
test_id = [method , '_all6'];


%% Run preprocessing pipe
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
        
        %get injected channel name
        artifact_chanloc = strings(numel(EEGprepro.CTAP.artifact.variance), 1);
        for j=1:numel(EEGprepro.CTAP.artifact.variance)
            artifact_chanloc(j) = string(EEGprepro.chanlocs(EEGprepro.CTAP.artifact.variance(j).channel_idx).labels);
        end
        
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
    
    [EEG, EEGart, EEGclean] = param_sweep_sdload(k_synid, PARAM);
           
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
    
    dmmat = zeros(n_sweeps, 3);
    performance = zeros(n_sweeps, 3);
    performance1 = zeros(n_sweeps, 3);
    ep_win = [-1, 1]; %sec
    ch_inds = horzcat(78:83, 91:96); %frontal

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
        myReport(sprintf('mad: %1.2f, n_chans: %d\n', dmat(i,1), dmat(i,2))...
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
    %plot(cost_arr, '-o')

%     figH = figure();
%     plot(dmat(:,1), dmat(:,2), '-o');
%     xlabel('MAD multiplication factor');
%     ylabel('Number of artefactual channels');
%     saveas(figH, fullfile(PARAM.path.sweepresDir,...
%                     sprintf('sweep_N-bad-chan_%s_%s.png', k_id, SWPipeParams.detect_bad_channels.method)));
%     %sprintf('sweep_N-bad-  chan_%s_%s_%s.png', k_id, num2str(lowbound), SWPipeParams.detect_bad_channels.method)));
% 
%     close(figH);

    figH_2 = figure();
    plot(performance(:,1), performance(:,2),'--o',performance(:,1), performance(:,3),'--*')
    xlabel('MAD multiplication factor');
    ylabel('performance');
    legend('sensitivity','specificity')
    saveas(figH_2, fullfile(PARAM.path.sweepresDir,...
                        sprintf('sweep_N-bad-chan-performance_%s_%s.png', k_id,  SWPipeParams.detect_bad_channels.method)));
    close(figH_2);
    
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
    
    figH_1 = figure();
    plot(dmmat(:,1), dmmat(:,2),'--o',dmmat(:,1), dmmat(:,3),'--*')
    xlabel('MAD multiplication factor');
    ylabel('Number of artefactual channels');
    legend('The number of detected coincidence with generated badchan','badchan detected')
    saveas(figH_1, fullfile(PARAM.path.sweepresDir,...
                        sprintf('sweep_N-bad-chan-num-meets_%s_%s.png', k_id,  SWPipeParams.detect_bad_channels.method)));
    close(figH_1);
        %sprintf('sweep_N-bad-chan-num-meets_%s_%s_%s.png', k_id, num2str(lowbound), SWPipeParams.detect_bad_channels.method)));

    %% pick best bounds parameter

    %% Test quality of identifications
    %SweepParams.values
    %EEG.CTAP.artifact.variance.channel_idx
    %EEG.CTAP.artifact.variance.multiplier

    th_value = 2;
    th_idx = find( [values{:}] <= th_value , 1, 'last' );

    %SWEEG{th_idx}.CTAP.badchans.variance.chans

    % channels identified as artifactual which are actually clean
%     setdiff(SWEEG{th_idx}.CTAP.badchans.variance.chans, ...
%             EEG.CTAP.artifact.variance_table.name)
% 
%     % wrecked channels not identified
%     tmp2 = setdiff(EEG.CTAP.artifact.variance_table.name, ...
%             SWEEG{th_idx}.CTAP.badchans.variance.chans);
% 
%     chm = ismember(EEG.CTAP.artifact.variance_table.name, tmp2);
%     EEG.CTAP.artifact.variance_table(chm,:)   

    clear('SWEEG');
    
    
    
    
    
end
