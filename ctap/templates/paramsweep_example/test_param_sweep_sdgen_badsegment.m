% generate synthetic data and detect bad channels from it
clear all;

%% Setup
branch_name = 'ctap_hydra_badseg';
param_sweep_setup();

sweepresdir = fullfile(Cfg.env.paths.ctapRoot, 'sweepres_segments');
mkdir(sweepresdir);

% Pipe: functions and parameters
clear Pipe;

i = 1; 
Pipe(i).funH = {@CTAP_load_data}; 
Pipe(i).id = [num2str(i) '_loaddata'];

PipeParams = struct([]);

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;
Cfg = ctap_auto_config(Cfg, PipeParams);
%todo: cannot use this since it warns about stuff that are not needed here
%AND stops execution.

seed_fname = 'BCICIV_calib_ds1a.set';
syndata_dir = fullfile(Cfg.env.paths.ctapRoot, 'syndata');
mkdir(syndata_dir);
sweepresdir = fullfile(Cfg.env.paths.ctapRoot, 'sweepres_segments');
mkdir(sweepresdir);
%test using this!


i = 1; 
SWPipe(i).funH = { @CTAP_detect_bad_segments };
SWPipe(i).id = [num2str(i) '_blink_correction'];

SWPipeParams.detect_bad_segments.method = 'quantileTh';
SWPipeParams.detect_bad_segments.normalEEGAmpLimits = [-1, 1]; %disable
SWPipeParams.detect_bad_segments.coOcurrencePrc = 0.001; %disable

ampthChannels = setdiff(  {chanlocs.labels},...
                          {Cfg.eeg.reference{:},...
                           Cfg.eeg.heogChannelNames{:},...
                           Cfg.eeg.veogChannelNames{:},...
                           'VEOG1', 'VEOG2', 'C16', 'C29'});
SWPipeParams.detect_bad_segments.channels =  {'A4'};
%SWPipeParams.detect_bad_segments.normalEEGAmpLimits = [-75, 75]; %in muV

SweepParams.funName = 'CTAP_detect_bad_segments';
SweepParams.paramName = 'tailPercentage';
SweepParams.values = ...
   num2cell([5e-5,...
            1e-4, 2e-4, 5e-4, 7e-4,...
            1e-3, 2e-3, 5e-3, 7e-3,...
            0.01, 0.05, 0.1]);

%{
limit_arr = (1:50:350)';
limit_arr(:,2) = limit_arr;
limit_arr(:,1) = -limit_arr(:,1);
SweepParams.values = num2cell(limit_arr, 2);
%}

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

                
%% Sweep
% Note: This step does sweeping ONLY, preprocess using some other means
%inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
inpath = fullfile(Cfg.env.paths.analysisRoot,'1_loaddata');
infile = 'syndata_session_meas.set';
EEGprepro = pop_loadset(infile, inpath);
[SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Cfg, ...
                                          SweepParams);

                     
%% Analyze
%%{
%Number of blink related components
n_sweeps = numel(SWEEG);
%dmat = NaN(n_sweeps, 2);
varnames = {'sweep','tail_prc','inj_prc','det_prc','inj_cover','det_cover'};
dt = table(1, NaN, NaN, NaN, NaN, NaN,...
            'VariableNames', varnames, ...
            'RowNames', {'1'});
% dt2 = table(1, 99, 9, 999, ...
%     'VariableNames', {'sweep','ampth','injected_prc','detected_prc'},...
%     'RowNames', {'1'});
%cost_arr = NaN(n_sweeps, 1);


ranges_injected = zeros(numel(EEGprepro.CTAP.artifact.EMG), 2);
for k = 1:numel(EEGprepro.CTAP.artifact.EMG)
    ranges_injected(k,:) = EEGprepro.CTAP.artifact.EMG(k).time_window_smp;
end


for i = 1:n_sweeps
    i_ev_match = ismember({SWEEG{i}.event.type}, 'badSegment');
    i_ranges_detected = [SWEEG{i}.event(i_ev_match).latency]';
    
    if ~isempty(i_ranges_detected)
        i_ranges_detected(:,2) = i_ranges_detected(:,1) +...
                                [SWEEG{i}.event(i_ev_match).duration]' ;

        [i_overlap_idx, i_OVRi, i_OVRd] = range_overlap(ranges_injected,...
                                                        i_ranges_detected);

        dt(num2str(i),:) = table(i, SweepParams.values{i}(1),...
                            i_OVRi.overlapPrc, i_OVRd.overlapPrc, ...
                            i_OVRi.nIdxCovered/EEGprepro.pnts,...
                            i_OVRd.nIdxCovered/EEGprepro.pnts, ...
                            'VariableNames', varnames,...
                            'RowNames', {num2str(i)});
    else
        dt(num2str(i),:) = table(i, SweepParams.values{i}(1),...
                                NaN, NaN, NaN, NaN, ...
                                'VariableNames', varnames,...
                                'RowNames', {num2str(i)}); 
    end
    clear('i_*');
end
%plot(cost_arr, '-o')

%my_xlim = [1e-5, 0.01];
my_xlim = [SweepParams.values{1}, SweepParams.values{end}];

figH = figure();
semilogx(dt.tail_prc, dt.inj_prc, 'g-o', dt.tail_prc, dt.det_prc, 'b-o');
xlim(my_xlim);
xlabel('Tail precentage [0,1]');
ylabel('Overlap percentage [0,1]');
title('% of overlap between injected EMG and detected bad segs');
legend('EMG','badseg');
saveas(figH, fullfile(sweepresdir, 'sweep_segment-overlap.png'));
close(figH);


figH = figure();
semilogx(dt.tail_prc, dt.inj_cover, 'g-o', dt.tail_prc, dt.det_cover, 'b-o');
xlim(my_xlim);
xlabel('Tail precentage [0,1]');
ylabel('Cover [0,1]');
title('The percentage of A4 EEG data covered');
legend('EMG','badseg');
saveas(figH, fullfile(sweepresdir, 'sweep_segment-cover.png'));
close(figH);



%{
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
%}
