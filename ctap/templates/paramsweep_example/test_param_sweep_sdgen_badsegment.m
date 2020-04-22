% generate synthetic data and detect bad channels from it
%
% Note:
%   * assumes PROJECT_ROOT to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
% PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra';

%% General setup
FILE_ROOT = mfilename('fullpath');
PROJECT_ROOT = FILE_ROOT(1:strfind(FILE_ROOT, fullfile(...
    'test_param_sweep_sdgen_badsegment')) - 1);

BRANCH_NAME = 'ctap_hydra_badseg';

RERUN_PREPRO = true;
RERUN_SWEEP = true;

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = param_sweep_setup(PROJECT_ROOT);

PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_segments');
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
Pipe(i).funH = {@CTAP_load_data}; 
Pipe(i).id = [num2str(i) '_loaddata'];

PipeParams = struct([]);

Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;
Cfg = ctap_auto_config(Cfg, PipeParams);
%todo: cannot use this since it warns about stuff that are not needed here
%AND stops execution.


%% Sweep config
i = 1; 
SWPipe(i).funH = { @CTAP_detect_bad_segments };
SWPipe(i).id = [num2str(i) '_segment_detection'];

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

          
%% Sweep for each file in Cfg.MC
if RERUN_SWEEP
    for k = 1:numel(Cfg.MC.measurement)

        k_id = Cfg.MC.measurement(k).casename;

        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        %inpath = '/tmp/hydra/projtmp/projtmp/this/3_tmp';
        inpath = fullfile(Cfg.env.paths.analysisRoot,'1_loaddata');
        infile = sprintf('%s.set', k_id);

        EEGprepro = pop_loadset(infile, inpath);
        [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGprepro, SWPipe, SWPipeParams, Cfg, ...
                                                  SweepParams);
        sweepres_file = fullfile(PARAM.path.sweepresDir,...
                sprintf('sweepres_%s.mat', k_id));
        save(sweepres_file, 'SWEEG', 'PARAMS','SWPipe','SWPipeParams', 'SweepParams');   


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
        for i = 1:numel(EEGprepro.CTAP.artifact.EMG)
            ranges_injected(i,:) = EEGprepro.CTAP.artifact.EMG(i).time_window_smp;
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
        semilogx(dt.tail_prc, dt.inj_cover, 'g-o', dt.tail_prc, dt.det_cover, 'b-o');
        xlim(my_xlim);
        xlabel('Tail precentage [0,1]');
        ylabel('Cover [0,1]');
        title('The percentage of A4 EEG data covered');
        legend('EMG','badseg');
        saveas(figH, fullfile(PARAM.path.sweepresDir,...
            sprintf('sweep_segment-cover_%s.png', k_id)));
        close(figH);

        figH = figure();
        semilogx(dt.tail_prc, dt.inj_prc, 'g-o', dt.tail_prc, dt.det_prc, 'b-o');
        xlim(my_xlim);
        xlabel('Tail precentage [0,1]');
        ylabel('Overlap percentage [0,1]');
        title('% of overlap between injected EMG and detected bad segs');
        legend('EMG','badseg');
        saveas(figH, fullfile(PARAM.path.sweepresDir,...
            sprintf('sweep_segment-overlap_%s.png', k_id)));
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

    end
end