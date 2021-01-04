function [EEG,Cfg] = CTAP_hydra_blink(EEG, Cfg)

% sweep the provided value range and decide the best parameter
%
% Note:
%   * assumes ctap root to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
%   * all parameter need should attached to Cfg.ctap.detect_bad_comps and pass Cfg as function parameter.
%
% Syntax:
%   [EEG, Cfg] = CTAP_test_blink(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_comps:
%   .method       string/char
%   .values       numerical array
%   Other arguments as in ctapeeg_detect_bad_comps().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%   Cfg.ctap.detect_bad_comps:
%   .(paramName)   paramName see ctapeeg_detect_bad_comps, each
%                  methods have the corresponding paramName, and it's value
%                  should be the best parameter picked.
% ;

%% General setup
if ~Cfg.HYDRA.ifapply
    return
end

BRANCH_NAME = 'ctap_synthetic_pre_blinks';

RERUN_PREPRO = true;
RERUN_SWEEP = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = Cfg.HYDRA.PARAM;
PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_blinks');
mkdir(PARAM.path.sweepresDir);


%% CTAP config
CH_FILE = Cfg.HYDRA.chanloc;

Arg.env.paths = cfg_create_paths(PARAM.path.projectRoot, BRANCH_NAME, {''}, 1);
Arg.eeg.chanlocs = CH_FILE;
chanlocs = readlocs(CH_FILE);

Arg.eeg.reference = Cfg.eeg.reference;
Arg.eeg.veogChannelNames = Cfg.eeg.veogChannelNames; %'C17' has highest blink amplitudes
Arg.eeg.heogChannelNames = Cfg.eeg.heogChannelNames;
Arg.grfx.on = false;

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(PARAM.path.synDataRoot, '*_bad_comps_syndata.set');
Arg.MC = MC;

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1; 
Pipe(i).funH = {@CTAP_load_data,...
                @CTAP_blink2event,...
                @CTAP_generate_cseg,...
                @CTAP_run_ica};
Pipe(i).id = [num2str(i) '_loaddata'];

PipeParams.run_ica.method = 'fastica';
PipeParams.run_ica.overwrite = true;
PipeParams.run_ica.channels = {'EEG' 'EOG'};

Arg.pipe.runSets = {'all'};
Arg.pipe.stepSets = Pipe;

Arg = ctap_auto_config(Arg, PipeParams);


%% Sweep config



i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_comps,... %detect blink related ICs
                    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_blink_correction'];

SWPipeParams.detect_bad_comps.method =  Cfg.ctap.detect_bad_comps.method;

SweepParams.funName = 'CTAP_detect_bad_comps';
SweepParams.paramName = 'thr';
SweepParams.values = num2cell(linspace(1.3, 1.5, 30));



%% Run preprocessing pipe for all datasets in Cfg.MC
if RERUN_PREPRO
    
    Arg.pipe.runMeasurements = {Arg.MC.measurement.casename};
    
    if (isempty(dir(fullfile(Arg.env.paths.analysisRoot, '1_loaddata'))))
        CTAP_pipeline_looper(Arg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
    end
end
% TODO: possible bug if RECOMPUTE_SYNDATA & RERUN_PREPRO == 0, as resulting
% datasets might have mismatched dimensions

                
%% Sweep (all files in Cfg.MC)

if RERUN_SWEEP
    for k = 1:numel(Arg.MC.measurement)

        k_id = Arg.MC.measurement(k).casename;

        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        %inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
        inpath = fullfile(Arg.env.paths.analysisRoot, '2_ICA');
        infile = sprintf('%s.set', k_id);

        EEGprepro = pop_loadset(infile, inpath);

        % Note: This step does sweeping ONLY, preprocess using some other means
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Arg, ...
                                          SweepParams);
        sweepres_file = fullfile(PARAM.path.sweepresDir, ...
                                 sprintf('sweepres_%s.mat', k_id));
        save(sweepres_file, 'SWEEG', 'PARAMS','SWPipe','PipeParams', 'SweepParams',...
        '-v7.3');
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
    
    [EEG1, EEGart, EEGclean] = param_sweep_sdload(k_synid, PARAM);
           
    % CTAP data that the sweep was based on
    CTAP_inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
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


    % TODO: PARAMETERIZE THESE VALUES??
    ep_win = [-1, 1]; %sec
    ch_inds = horzcat(78:83, 91:96); %frontal

    %Create epoched observed/input data
    %Create comparison basis EEG as combo of clean synth EEG + non-blink artifacts
    EEG_basis_ep = EEGprepro;
    EEG_basis_ep.data = EEGclean.data + EEGart.wrecks + EEGart.myo;
    %EEG_basis_ep = pop_epoch(EEG_basis_ep, {'blink'}, ep_win);
    %Create epoched blink data only
    EEG_blink_ep = EEGprepro;
    EEG_blink_ep.data = EEGart.blinks;
    %EEG_blink_ep = pop_epoch(EEG_blink_ep, {'blink'}, ep_win);

    % output directory for blink-ERPs
    blinkerp_dir = fullfile(PARAM.path.sweepresDir, 'blink-ERP', k_id);
    mkdir(blinkerp_dir);

    for i = 1:n_sweeps
        dmat(i,:) = [SweepParams.values{i},...
                    numel(SWEEG{i}.CTAP.badcomps.blink_template.comps) ];
        fprintf('\nangle_rad: %1.2f, n_B_comp: %d\n\n', dmat(i,1), dmat(i,2));

        cost_arr(i) = sum(sum(abs( EEG_basis_ep.data(ch_inds,:) - ...
                                        SWEEG{i}.data(ch_inds,:)  )));    

        diffS(i) = sum(sum(abs(...
                EEG_basis_ep.data(ch_inds,:) -...%signal S
                SWEEG{i}.data(ch_inds,:) ...%signal estimate S'
                )));
        diffA(i) = sum(sum(abs(...
                EEG_blink_ep.data(ch_inds,:) -...%artefacts A
                (EEGprepro.data(ch_inds,:) - SWEEG{i}.data(ch_inds,:)) ...%artefact estimate A'
                )));
        U(i) = diffS(i) + diffA(i);
        resmat(i,:)=[SweepParams.values{i},...
                     U(i)];
        resAmat(i,:)=[SweepParams.values{i},...
                     diffA(i)];   
        resSmat(i,:)=[SweepParams.values{i},...
                     diffS(i)];
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
    plot(cost_arr)

    figH = figure();
    plot(dmat(:,1), dmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('Number of blink related IC components');
    saveas(figH, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink-IC_%s.png', k_id)));
    close(figH);
    
    figH1 = figure();
    plot(resmat(:,1), resmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('distance between original EEG data and blink rejected data');
    saveas(figH1, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink_%s.png', k_id)));
    close(figH1);
    
    figH2 = figure();
    plot(resAmat(:,1), resAmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('distance between original EEG data and blink rejected data');
    saveas(figH2, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink_A_%s.png', k_id)));
    close(figH2);
    
    figH3 = figure();
    plot(resSmat(:,1), resSmat(:,2), '-o');
    xlabel('Angle threshold in (rad)');
    ylabel('distance between original EEG data and blink rejected data');
    saveas(figH3, fullfile(PARAM.path.sweepresDir, ...
                          sprintf('sweep_N-blink_S_%s.png', k_id)));
    close(figH3);

    
    index = find(U==min(U));
    
    res = SweepParams.values(max(index));
    pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
    Cfg.ctap.(pipeFun).(SweepParams.paramName) = [res{:}];
    msg = myReport(sprintf('the best parameter: %f', [res{:}])...
        , Cfg.env.logFile);
    EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, SWPipeParams.(pipeFun));
    
    
    clear('SWEEG');
    
end   
end