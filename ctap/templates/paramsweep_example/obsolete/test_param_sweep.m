% do sweeping for some existing dataset

%% Setup
resultRoot = '/home/jkor/work_local/projects/hydra';

%analysisdir = '/home/jkor/work_local/projects/ctap/ctap_pipeline/example-project/ctapmanu/';
analysisdir = '/home/jussi/work_local/projects/ctap/ctap_pipeline/example-project/ctapmanu/';

srcdir = fullfile(analysisdir, '3_ICA');
srcname = 'BCICIV_calib_ds1a_syndata_session_meas.set';


% Pipe: functions and parameters
clear Pipe;
i = 1; 
Pipe(i).funH = { @CTAP_detect_bad_comps,... %detect blink related ICs
                 @CTAP_filter_blink_ica}; %correct ICs using FIR filter
Pipe(i).id = [num2str(i) '_blink_correction'];
PipeParams.detect_bad_comps = struct(...
    'method', 'blink_template');

SweepParams.funName = 'CTAP_detect_bad_comps';
SweepParams.paramName = 'thr';
SweepParams.values = num2cell(linspace(1.1, 1.6, 10));


projectRoot = fullfile(resultRoot,'hydra');
ctapRoot = fullfile(projectRoot, 'projtmp');
Cfg.env.paths = cfg_create_paths(ctapRoot, 'projtmp', 'dummy');
%Cfg.eeg.chanlocs = 'chanlocs128_biosemi.elp';
%Channels = readlocs(Cfg.eeg.chanlocs);
Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
Cfg.eeg.veogChannelNames = {'C17'}; %'C17' has highest blink amplitudes
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};
Cfg.grfx.on = false;
Cfg.pipe.runSets = {'all'};
Cfg.pipe.stepSets = Pipe;

Cfg = ctap_auto_config(Cfg, PipeParams);
%todo: cannot use this since it warns about stuff that are not needed here
%AND stops execution.


%% Load data
EEG = pop_loadset(srcname, srcdir);
%ctap_eegplot(EEG);


%% Sweep
 [ALLEEG, PARAMS] = CTAP_pipeline_sweeper(EEG, Pipe, PipeParams, Cfg, ...
                                          SweepParams);


                          
%% Analyze

% Number of blink related components
dmat = NaN(numel(ALLEEG), 2);
for i=1:numel(ALLEEG)
    dmat(i,:) = [SweepParams.values{i},...
                numel(ALLEEG{i}.CTAP.badcomps.blink_template.comps) ];
    fprintf('angle_rad: %1.2f, n_B_comp: %d\n', dmat(i,1), dmat(i,2));     
end

figH = figure();
plot(dmat(:,1), dmat(:,2), '-o');
xlabel('Angle threshold in (rad)');
ylabel('Number of blink related IC components');
saveas(figH, './tmp/sweep_N-blink-IC.png');
close(figH);

%SweepParams.values
%ALLEEG{1}.CTAP.badcomps.blink_template.comps


%% Analyze







