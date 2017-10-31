% generate synthetic data, detect blink related ICs from it and remove them
%clear;

%% Setup
branch_name = 'ctap_hydra_blink';
param_sweep_setup();

sweepresdir = fullfile(Cfg.env.paths.ctapRoot, 'sweepres_blinks');
mkdir(sweepresdir);

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

PipeParams.run_ica.method = 'fastica';
PipeParams.run_ica.overwrite = true;
PipeParams.run_ica.channels = {'EEG' 'EOG'};
PipeParams.detect_bad_comps.method = 'blink_template';

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;

Cfg = ctap_auto_config(Cfg, PipeParams);

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


%% Generate synthetic data
if RECOMPUTE_SYNDATA
    param_sweep_sdgen;
else
    param_sweep_sdload;
end


%% Run preprocessing pipe
if RERUN_PREPRO
    param_sweep_prepro;
end

% TODO: possible bug if RECOMPUTE_SYNDATA & RERUN_PREPRO == 0, as resulting
% datasets might have mismatched dimensions

                
%% Sweep
sweepres_file = fullfile(sweepresdir, 'sweepres.mat');

if RERUN_SWEEP
    % Note: This step does sweeping ONLY, preprocess using some other means
    inpath = fullfile(Cfg.env.paths.analysisRoot, '2_ICA');
    infile = 'syndata_session_meas.set';
    EEGprepro = pop_loadset(infile, inpath);

    [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, PipeParams, Cfg, ...
                                              SweepParams); 
    save(sweepres_file, 'SWEEG', 'PARAMS','SWPipe','PipeParams', 'SweepParams',...
        '-v7.3');   
 
else 
    S = load(sweepres_file);
end


                     
%% Analyze

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
blinkerp_dir = fullfile(sweepresdir, 'blink-ERP');
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
saveas(figH, fullfile(sweepresdir, 'sweep_N-blink-IC.png'));
close(figH);

SweepParams.values
SWEEG{1}.CTAP.badcomps.blink_template.comps
