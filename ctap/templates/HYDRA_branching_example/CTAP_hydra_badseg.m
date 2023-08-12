function [EEG,Cfg] = CTAP_hydra_badseg(EEG, Cfg)

% sweep the provided value range and decide the best parameter
%
% Note:
%   * assumes ctap root to be in workspace
%   * run batch_psweep_datagen.m prior to running this script!
%   * all parameter need should attached to Cfg.ctap.detect_bad_segments and pass Cfg as function parameter.
%
% Syntax:
%   [EEG, Cfg] = CTAP_test_badseg(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_segments:
%   .method       string/char
%   .values       numerical array
%   Other arguments as in ctapeeg_detect_bad_segments().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%   Cfg.ctap.detect_bad_segments:
%   .(paramName)   paramName see ctapeeg_detect_bad_segments, each
%                  methods have the corresponding paramName, and it's value
%                  should be the best parameter picked.
% ;

%% IF execution HYDRA or not
if ~Cfg.HYDRA.ifapply
    return
end

%% General setup

BRANCH_NAME = 'ctap_synthetic_pre_badseg';

RERUN_PREPRO = true;
RERUN_SWEEP = true;

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

PARAM = Cfg.HYDRA.PARAM;
PARAM.path.sweepresDir = fullfile(PARAM.path.projectRoot, 'sweepres_segments');
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
MC = path2measconf(PARAM.path.synDataRoot, '*_bad_segments_syndata.set');
Arg.MC = MC;

%--------------------------------------------------------------------------
% Pipe: functions and parameters
clear Pipe;

i = 1;
Pipe(i).funH = {@CTAP_load_data};
Pipe(i).id = [num2str(i) '_loaddata'];

PipeParams = Cfg.HYDRA.ctapArgs;

Arg.pipe.runSets = {'all'};
Arg.pipe.stepSets = Pipe;
Arg = ctap_auto_config(Arg, PipeParams);
%todo: cannot use this since it warns about stuff that are not needed here
%AND stops execution.


%% Sweep config
i = 1;
SWPipe(i).funH = { @CTAP_detect_bad_segments };
SWPipe(i).id = [num2str(i) '_segment_detection'];

SWPipeParams.detect_bad_segments.method = Cfg.ctap.detect_bad_segments.method;

SWPipeParams.detect_bad_segments.channels =  {'A4'};


SweepParams.funName = 'CTAP_detect_bad_segments';
SweepParams.paramName = 'tailPercentage';
SweepParams.values = ...
    num2cell([5e-5,...
    1e-4, 2e-4, 5e-4, 7e-4,...
    1e-3, 2e-3, 5e-3, 7e-3,...
    0.01, 0.05, 0.1]);


%% Run preprocessing pipe for all datasets in Cfg.MC
if RERUN_PREPRO
    

    Arg.pipe.runMeasurements = {Arg.MC.measurement.casename};
    
    if (isempty(dir(fullfile(Arg.env.paths.analysisRoot, '1_loaddata'))))
        CTAP_pipeline_looper(Arg,...
            'debug', STOP_ON_ERROR,...
            'overwrite', OVERWRITE_OLD_RESULTS);
    end
end



%% Sweep for each file in Cfg.MC
if RERUN_SWEEP
    for k = 1:numel(Arg.MC.measurement)
        k_id = Arg.MC.measurement(k).casename;
        
        %% Sweep
        % Note: This step does sweeping ONLY, preprocess using some other means
        inpath = fullfile(Arg.env.paths.analysisRoot, '1_loaddata');
        infile = sprintf('%s.set', k_id);
        
        EEGprepro = pop_loadset(infile, inpath);
        %
        MyStruct = EEGprepro.event;
        fn = fieldnames(MyStruct);
        tf = cellfun(@(c) isempty(MyStruct.(c)), fn);
        EEG.event = rmfield(MyStruct, fn(tf));
        %
        
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
    
    % Load needed datasets
    % Original data (for synthetic datasets)
        
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
    varnames = {'sweep','tail_prc','inj_prc','det_prc','inj_cover','det_cover'};
    dt = table(1, NaN, NaN, NaN, NaN, NaN,...
        'VariableNames', varnames, ...
        'RowNames', {'1'});
    
    
    
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
    
    
    %% plot
    my_xlim = [SweepParams.values{1}, SweepParams.values{end}];
    
    figH = figure();
    semilogx(dt.tail_prc, dt.inj_cover, 'g-o', dt.tail_prc, dt.det_cover, 'b-o');
    xlim(my_xlim);
    xlabel('Tail precentage [0,1]');
    ylabel('Cover [0,1]');
    title('The percentage of A4 EEG data covered');
    legend('EMG','badseg','Location','southeast');
    saveas(figH, fullfile(PARAM.path.sweepresDir,...
        sprintf('sweep_segment-cover_%s.png', k_id)));
    close(figH);
    
    figH = figure();
    semilogx(dt.tail_prc, dt.inj_prc, 'g-o', dt.tail_prc, dt.det_prc, 'b-o');
    xlim(my_xlim);
    xlabel('Tail precentage [0,1]');
    ylabel('Overlap percentage [0,1]');
    title('% of overlap between injected EMG and detected bad segs');
    legend('EMG','badseg','Location','southeast');
    saveas(figH, fullfile(PARAM.path.sweepresDir,...
        sprintf('sweep_segment-overlap_%s.png', k_id)));
    close(figH);
    
    %% pick the best parameter within given range
    dis = abs(dt.inj_prc - dt.det_prc);
    [M,I] = min(dis);
    if(M == 0 || I == numel(dis))
        bp = dt.tail_prc(I);
    else
        if(((dt.inj_prc(I - 1) > dt.det_prc(I - 1) && dt.inj_prc(I + 1) > dt.det_prc(I + 1)) && dt.inj_prc(I) > dt.det_prc(I)) ||...
                ((dt.inj_prc(I - 1) < dt.det_prc(I - 1) && dt.inj_prc(I + 1) < dt.det_prc(I + 1)) && dt.inj_prc(I) < dt.det_prc(I))   )
            bp = dt.tail_prc(I);
        elseif((dt.det_prc(I - 1) > dt.inj_prc(I - 1) && dt.inj_prc(I + 1) > dt.det_prc(I + 1) && dt.inj_prc(I) > dt.det_prc(I)) ||...
                (dt.det_prc(I - 1) < dt.inj_prc(I - 1) && dt.inj_prc(I + 1) < dt.det_prc(I + 1) && dt.inj_prc(I) < dt.det_prc(I)))
            syms b k
            equ1 = [k*dt.tail_prc(I)+b==dt.det_prc(I), k*dt.tail_prc(I-1)+b==dt.det_prc(I-1)];
            S1 = solve(equ1,[b,k]);
            equ2 = [k*dt.tail_prc(I)+b==dt.inj_prc(I),k*dt.tail_prc(I-1)+b==dt.inj_prc(I-1)];
            S2 = solve(equ2,[b,k]);
            syms x
            equ = S1.k*x + S1.b == S2.k*x + S2.b;
            S = solve(equ,x);
            bp = S;
        elseif((dt.inj_prc(I - 1) > dt.det_prc(I - 1) && dt.det_prc(I + 1) > dt.inj_prc(I + 1) && dt.inj_prc(I) > dt.det_prc(I)) ||...
                (dt.inj_prc(I - 1) < dt.det_prc(I - 1) && dt.det_prc(I + 1) < dt.inj_prc(I + 1) && dt.inj_prc(I) < dt.det_prc(I)))
            syms b k
            equ1 = [k*dt.tail_prc(I)+b-dt.det_prc(I)==0,k*dt.tail_prc(I+1)+b-dt.det_prc(I+1)==0];
            S1 = solve(equ1,[b,k]);
            equ2 = [k*dt.tail_prc(I)+b==dt.inj_prc(I), k*dt.tail_prc(I+1)+b==dt.inj_prc(I+1)];
            S2 = solve(equ2,[b,k]);
            syms x
            equ = S1.k*x + S1.b == S2.k*x + S2.b;
            S = solve(equ,x);
            bp = S;
        elseif((dt.det_prc(I - 1) > dt.inj_prc(I - 1) && dt.det_prc(I + 1) > dt.inj_prc(I + 1) && dt.inj_prc(I) > dt.det_prc(I)) ||...
                ( dt.det_prc(I - 1) < dt.inj_prc(I - 1) && dt.det_prc(I + 1) < dt.inj_prc(I + 1) && dt.inj_prc(I) < dt.det_prc(I)) )
            syms b k
            equ11 = [k*dt.tail_prc(I)+b-dt.det_prc(I)==0,k*dt.tail_prc(I+1)+b-dt.det_prc(I+1)==0];
            S11 = solve(equ11,[b,k]);
            equ12 = [k*dt.tail_prc(I)+b==dt.inj_prc(I), k*dt.tail_prc(I+1)+b==dt.inj_prc(I+1)];
            S12 = solve(equ12,[b,k]);
            equ21 = [k*dt.tail_prc(I)+b==dt.det_prc(I), k*dt.tail_prc(I-1)+b==dt.det_prc(I-1)];
            S21 = solve(equ21,[b,k]);
            equ22 = [k*dt.tail_prc(I)+b==dt.inj_prc(I),k*dt.tail_prc(I-1)+b==dt.inj_prc(I-1)];
            S22 = solve(equ22,[b,k]);
            syms x
            equ1 = S11.k*x + S11.b == S12.k*x + S12.b;
            S1 = solve(equ1,x);
            equ2 = S21.k*x + S21.b == S22.k*x + S22.b;
            S2 = solve(equ2,x);
            if(S1 > S2)
                bp = S1;
            else
                bp = S2;
            end
        end
    end
    
    pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
    Cfg.ctap.(pipeFun).(SweepParams.paramName) = double(bp);
    %[EEG.chanlocs.type] = deal('EEG');
    msg = myReport(sprintf('the best parameter: %f', double(bp))...
        , Cfg.env.logFile);
    EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, SWPipeParams.(pipeFun));
    

    clear('SWEEG');

end
end