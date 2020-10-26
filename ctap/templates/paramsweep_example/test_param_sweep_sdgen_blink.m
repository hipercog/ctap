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
REPO_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'ctap', 'templates', 'paramsweep_example', 'batch_psweep_datagen')) - 1);


BRANCH_NAME = 'ctap_hydra_blink';

RERUN_PREPRO = false;
RERUN_SWEEP = false;
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

SWPipeParams.detect_bad_comps.method = 'blink_template';

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
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Cfg, ...
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
    resmat = NaN(n_sweeps, 2);
    resAmat = NaN(n_sweeps, 2);
    resSmat = NaN(n_sweeps, 2);

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
    EEG_trust = EEGprepro;
    EEG_trust.data = EEGclean.data + EEGart.wrecks + EEGart.myo + EEGart.blinks;
    EEG_trust = pop_epoch(EEG_trust, {'blink'}, ep_win);
    %Create epoched blink data only
    EEG_blink_ep = EEGprepro;
    EEG_blink_ep.data = EEGart.blinks;
    EEG_blink_ep = pop_epoch(EEG_blink_ep, {'blink'}, ep_win);

     %weight calculation

    nose_loc = [1 0 0];
    chc = [[EEGprepro.chanlocs.X]' [EEGprepro.chanlocs.Y]' [EEGprepro.chanlocs.Z]'];
    chd = eucl(chc, nose_loc);
    
    % This is the "propagation template"
    % linear might not be good though
    x = linspace(0, 2, 100);
    c = [linspace(1, 0, 60) zeros(1, 40)];
    weight = interp1(x, c, chd)/sum(interp1(x, c, chd));
    
    blink_epoch = zeros(134,181);
    for i = 1:134
        [a,j,v] = find(EEG_blink_ep.data(i,:,:));
        blink_p = [];
        count = 1;
        if(length(j)>1 && j(1)>1)
            blink_p(count) = j(1);
            count=count+1; 
        end
        for b=2:length(j)
            if(abs(j(b)-j(b-1))>1)
                blink_p(count) = j(b);
                count=count+1;
            end
        end
        blink_epoch_ = zeros(181,1);
        for m = 1:2:length(blink_p)
            p2 = fix(blink_p(m+1)/1024);
            p1 = ceil(blink_p(m)/1024);
            if p1==p2
                if p1*1024-blink_p(m) > blink_p(m+1)-p2
                    blink_epoch_(p1) = blink_epoch_(p1) + 1;
                else
                    blink_epoch_(p1+1) = blink_epoch_(p1+1) + 1;
                end
            elseif p1<p2
                blink_epoch_(p2) = blink_epoch_(p2) + 1;
            else
                blink_epoch_(p1) = blink_epoch_(p1) + 1;
            end
        end
        blink_epoch(i,:) = blink_epoch_;
    end
    
    blink_epoch= sum(blink_epoch.*weight);
    for i = 1: 181
        if blink_epoch(i) > 1
            blink_epoch(i)=1;
        else
            blink_epoch(i) = 0;
        end
    end
    
  
    
    
    %     output directory for blink-ERPs
    blinkerp_dir = fullfile(PARAM.path.sweepresDir, 'blink-ERP', k_id);
    mkdir(blinkerp_dir);
 
    ss_table = zeros(n_sweeps,4);
    ss_mat = zeros(n_sweeps,4);
    dd_mat = zeros(n_sweeps,181);
    rr_mat = zeros(n_sweeps,181);
    for i = 1:n_sweeps
        dmat(i,:) = [SweepParams.values{i},...
                    numel(SWEEG{i}.CTAP.badcomps.blink_template.comps) ];
        fprintf('\nangle_rad: %1.2f, n_B_comp: %d\n\n', dmat(i,1), dmat(i,2));

        EEG_sweep_ep = pop_epoch( SWEEG{i}, {'blink'}, ep_win);
%         cost_arr(i) = sum(sum(sum(abs( EEG_basis_ep.data(ch_inds,:,:) - ...
%                                         SWEEG{i}.data(ch_inds,:,:)))));    
        %UTILITY FUNCTION AS PER HYDRA PAPER - continuous
        Blink_est = EEG_sweep_ep.data - EEG_trust.data;
%         Blink_est = pop_epoch( Blink_est, {'blink'}, ep_win);
        detected_blink = zeros(134,181);
        [tp, fp, tn, fn] = deal(0);
        for m = 1:181
            for n = 1:134
                if sum(abs(Blink_est(n,:,m)-EEG_blink_ep.data(n,:,m)))<sum(abs(EEG_basis_ep.data(n,:,m) - Blink_est(n,:,m)))
                    detected_blink(n,m) = 1;
                else
                    detected_blink(n,m) = 0;
                end
            end
            detected_blink(:,m) = detected_blink(:,m).*weight;
        end
        detected_blink =  sum(detected_blink);
        dd_mat(i,:) = detected_blink;
        detected_blink = round(detected_blink);
        rr_mat(i,:) = detected_blink;
        
        for m = 1:181
            if detected_blink(m) == blink_epoch(m)
                if detected_blink(m) == 1
                    tp = tp+1;
                else
                    tn = tn+1;
                end
            else
                if detected_blink(m) == 1
                    fp = fp+1;
                else
                    fn = fn+1;
                end
            end
        end

        ss_table(i,:) = [tp, fp, tn, fn];
        %Sensitivity
        TPR = tp/(tp+fn);
        %Specificity
        TNR = tn/(tn+fp);
        
        FPR = fp/(fp+tn);
        
        ss_mat(i,:) = [SweepParams.values{i}, TPR, TNR, FPR];
        
%         diffS(i) = sum(sum(abs(...
%                 EEG_basis_ep.data(ch_inds,:) -...%signal S
%                 SWEEG{i}.data(ch_inds,:) ...%signal estimate S'
%                 )));
%             
%         diffA(i) = sum(sum(abs(...
%                 EEG_blink_ep.data(ch_inds,:) -...%artefacts A
%                 (EEGprepro.data(ch_inds,:) - SWEEG{i}.data(ch_inds,:)) ...%artefact estimate A'
%                 )));
%         U(i) = diffS(i) + diffA(i);
%         resmat(i,:)=[SweepParams.values{i},...
%                      U(i)];
%         resAmat(i,:)=[SweepParams.values{i},...
%                      diffA(i)];   
%         resSmat(i,:)=[SweepParams.values{i},...
%                      diffS(i)];
        %%{
        %PLOT BLINK ERP PER SWEEP
        subplot(n_sweeps, 1, i);
        fh_tmp = ctap_eeg_compare_ERP(EEGprepro,SWEEG{i}, {'blink'},...
                    'idArr', {'before rejection','after rejection'},...
                    'channels', {'C21'},...
                    'visible', 'off');
        savename = sprintf('sweep_blink-ERP_%d.png', i);
        savefile = fullfile(blinkerp_dir, savename);
        print(fh_tmp, '-dpng', savefile);
        close(fh_tmp);
        %}
    end
%     plot(cost_arr)
    save(fullfile(PARAM.path.sweepresDir,...
                    sprintf('sweep_blink_ss_table10noabs.mat' )),'ss_table');
    save(fullfile(PARAM.path.sweepresDir,...
                    sprintf('sweep_blink_ss_mat10noabs.mat' )),'ss_mat');            
    figH = figure();
    plot(dmat(:,1), dmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('Number of blink related IC components');
    saveas(figH, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink-IC_unWeighted1abs_s.fig')));
    close(figH);
    
    figH_3 = figure();
    x = linspace(0,1);
    y = x;
    p = ss_mat(:,1);
    plot(ss_mat(:,2), ss_mat(:,4),'o',x,y,'--')
    xlabel('FPR');
    ylabel('TPR');
    for i=1:length(p)
        text(ss_mat(i,2), ss_mat(i,4),num2str(i));
    end
    title('ROC Space');
    saveas(figH_3, fullfile(PARAM.path.sweepresDir,...
        sprintf('sweep_blinkROC_unWeighted1abs_s.fig')));
    close(figH_3);
    
        figH = figure(); 
    semilogx(ss_mat(:,2), ss_mat(:,1), 'g-o', ss_mat(:,3), ss_mat(:,2), 'b-o');
    xlabel('threshold');
    ylabel('Sensitivity and Specificity');
    title('Sensitivity and Specificity');
    legend('Sensitivity','Specificity');
    saveas(figH, fullfile(PARAM.path.sweepresDir,...
        sprintf('sweep_blinkSensitivitySpecificity_unWeighted1abs_s.fig')));
    close(figH);
%     figH1 = figure();
%     plot(resmat(:,1), resmat(:,2), '-o');
%     xlabel('Angle threshold in (rad)');
%     ylabel('distance between original EEG data and blink rejected data');
%     saveas(figH1, fullfile(PARAM.path.sweepresDir, ...
%                           sprintf('sweep_N-blink_%s.png', k_id)));
%     close(figH1);
%     
%     figH2 = figure();
%     plot(resAmat(:,1), resAmat(:,2), '-o');
%     xlabel('Angle threshold in (rad)');
%     ylabel('distance between original EEG data and blink rejected data');
%     saveas(figH2, fullfile(PARAM.path.sweepresDir, ...
%                           sprintf('sweep_N-blink_A_%s.png', k_id)));
%     close(figH2);
    
%     figH3 = figure();
%     plot(resSmat(:,1), resSmat(:,2), '-o');
%     xlabel('Angle threshold in (rad)');
%     ylabel('distance between original EEG data and blink rejected data');
%     saveas(figH3, fullfile(PARAM.path.sweepresDir, ...
%                           sprintf('sweep_N-blink_S_%s.png', k_id)));
%     close(figH3);
    %SweepParams.values
    %SWEEG{1}.CTAP.badcomps.blink_template.comps
    [Min, I] = min(U);
    res = SweepParams.values(I);
    pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
    SWPipeParams.(pipeFun).(SweepParams.paramName) = [res{:}];
    Cfg.ctap.(pipeFun) = SWPipeParams.(pipeFun)
    %clear('SWEEG');
end
