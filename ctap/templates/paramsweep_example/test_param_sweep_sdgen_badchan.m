% generate synthetic data and detect bad channels from it

%% Setup
branch_name = 'ctap_hydra_badchan';
param_sweep_setup();

sweepresdir = fullfile(Cfg.env.paths.ctapRoot, 'sweepres_channels');
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

i = 1; 
SWPipe(i).funH = {  @CTAP_detect_bad_channels,... %detect blink related ICs
                    @CTAP_reject_data}; % reject ICs
SWPipe(i).id = [num2str(i) '_blink_correction'];

SWPipeParams.detect_bad_channels.method = 'variance';

SweepParams.funName = 'CTAP_detect_bad_channels';
SweepParams.paramName = 'bounds';
SweepParams.values = num2cell(1.5:0.1:7);



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
%{

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(syndata_dir, '*.set');
Cfg.MC = MC;

clear('Filt')
Filt.subjectnr = 1;
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);

%Cfg.pipe.runSets = {Cfg.pipe.stepSets(3).id}; %/3_tmp/

CTAP_pipeline_looper(Cfg,...
                    'debug', STOP_ON_ERROR,...
                    'overwrite', OVERWRITE_OLD_RESULTS);
%}

                
%% Sweep
% Note: This step does sweeping ONLY, preprocess using some other means
inpath = fullfile(Cfg.env.paths.analysisRoot,'2_ICA');
infile = 'syndata_session_meas.set';
EEGprepro = pop_loadset(infile, inpath);

[SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Cfg, ...
                                          SweepParams);

                     
%% Analyze

%Number of blink related components
n_sweeps = numel(SWEEG);
dmat = NaN(n_sweeps, 2);
cost_arr = NaN(n_sweeps, 1);

ep_win = [-1, 1]; %sec
ch_inds = horzcat(78:83, 91:96); %frontal
EEGclean.event = EEGprepro.event;
EEG_clean_ep = pop_epoch( EEGclean, {'blink'}, ep_win);

for i = 1:n_sweeps
    dmat(i,:) = [SweepParams.values{i},...
                numel(SWEEG{i}.CTAP.badchans.variance.chans) ];
    fprintf('mad: %1.2f, n_chans: %d\n', dmat(i,1), dmat(i,2));
    
    %EEG_tmp_ep = pop_epoch( SWEEG{i}, {'blink'}, ep_win);
    %cost_arr(i) = sum(sum(sum(abs(  EEG_tmp_ep.data(ch_inds,:,:) - ...
    %                                EEG_clean_ep.data(ch_inds,:,:)  ))));
    %cost_arr(i) = sum(sum(abs( SWEEG{i}.data - EEGclean.data  )));
    
    %{
    subplot(n_sweeps, 1, i);
    fh_tmp = ctap_eeg_compare_ERP(EEGprepro,SWEEG{i}, {'blink'},...
                'idArr', {'before rejection','after rejection'},...
                'channels', {'C17'},...
                'visible', 'off');
    savename = sprintf('blink_ERP_sweep%d.png', i);
    savefile = fullfile(sweepresdir, savename);
    print(fh_tmp, '-dpng', savefile);
    close(fh_tmp);
    %}
end
%plot(cost_arr, '-o')

figH = figure();
plot(dmat(:,1), dmat(:,2), '-o');
xlabel('MAD multiplication factor');
ylabel('Number of artefactual channels');
saveas(figH, fullfile(sweepresdir, 'sweep_N-bad-chan.png'));
close(figH);




%% Test quality of identifications
%SweepParams.values
%EEG.CTAP.artifact.variance.channel_idx
%EEG.CTAP.artifact.variance.multiplier

th_value = 2;
th_idx = max(find( [SweepParams.values{:}] <= th_value ));

%SWEEG{th_idx}.CTAP.badchans.variance.chans

% channels identified as artifactual which are actually clean
setdiff(SWEEG{th_idx}.CTAP.badchans.variance.chans, ...
        EEG.CTAP.artifact.variance_table.name)

% wrecked channels not identified
tmp2 = setdiff(EEG.CTAP.artifact.variance_table.name, ...
        SWEEG{th_idx}.CTAP.badchans.variance.chans)

chm = ismember(EEG.CTAP.artifact.variance_table.name, tmp2);
EEG.CTAP.artifact.variance_table(chm,:)   

