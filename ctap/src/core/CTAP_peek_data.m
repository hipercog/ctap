function [EEG, Cfg] = CTAP_peek_data(EEG, Cfg)
%CTAP_peek_data - Take a peek at the data and save it as an image
%
% Description:
%   Generate EEG data stats. Make a histogram thereof. Make eegplot of a random
%   (or user-specified) window of raw EEG data, and raw IC data. 
%   Save stats in tables, and figures to disk for later viewing.
%
% Syntax:
%   [EEG, Cfg] = CTAP_peek_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.peek_data:
%       .plotEEGHist    logical, Plot EEG histogram?, default: Cfg.grfx.on
%       .plotEEG        logical, Plot EEG data?, default: Cfg.grfx.on
%       .plotEEGset     logical, Plot several EEG segments?, default: true
%       .plotICA        logical, Plot ICA components?, default: Cfg.grfx.on
%       .secs           numeric, How many seconds to plot?, default: 16
%       .peekevent      string, name of event to base peek windows on
%       .peekindex      vector, index of such events to use, default (only if 
%                       .peekevent is defined): uniform distribution of 10
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%   To check raw EEG latencies, we create new peeks, options are:
%   1. explicitly user guided by 
% 2. use the events user has defined for selecting data (because we know
%    such latencies won't be deleted, except by bad segment/epoch reject)
% 3. select random set of 10 latencies (or less if data is short)
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
% plot settings follow the global flag, unless specified by user!
Arg.plotEEGHist = Cfg.grfx.on;
Arg.plotEEG = Cfg.grfx.on;
Arg.plotEEGset = true;
Arg.plotICA = Cfg.grfx.on;
Arg.logStats = true;
Arg.secs = 16;
Arg.hists = 16; %number of histograms per figure, should be square

% Override defaults with user parameters...
if isfield(Cfg.ctap, 'peek_data')
    Arg = joinstruct(Arg, Cfg.ctap.peek_data); %override with user params
end
%...but ICs must be present
Arg.plotICA = Arg.plotICA && ~isempty(EEG.icaweights);

% Treat only EEG channels
idx = get_eeg_inds(EEG, {'EEG'});
nchan = numel(idx);


%% Define directory to save stuff to
if Arg.plotEEGHist || Arg.plotEEG || Arg.plotICA || Arg.logStats
    outdir = get_savepath(Cfg, mfilename);
    plotz = {'Histogram' 'Raw EEG' 'Independent Components'};
    plotz = sprintf('''%s''\t'...
        , plotz{logical([Arg.plotEEGHist Arg.plotEEG Arg.plotICA])});
    myReport(sprintf('\n'), Cfg.env.logFile);
    msg = myReport(sprintf('Plotting Diagnostics to ''%s''\nFor %s'...
        , outdir, plotz), Cfg.env.logFile);
    savepath = fullfile(outdir, EEG.CTAP.measurement.casename);
    if ~isdir(savepath), mkdir(savepath); end
else
    return;
end


%% make and save stats to log file
% basic_stats() outputs:
%   rng         - range: signal maximum minus minimum
%   M           - mean
%   med         - median
%   SD          - standard deviation
%   vr          - variance
% STAT_stats() outputs:
%   sk          - skewness 
%   k           - kurtosis
%   lopc        - low 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   hipc        - high 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   tM          - trimmed mean, removing data < lopc and data > hipc
%   tSD         - trimmed standard dev, removing data < lopc and data > hipc
%   tidx        - index of the data retained after trimming - NOT USED
%   ksh         - output flag of the Kolmogorov-Smirnov test at level 'alpha' 
%                 0: data could be normally dist'd; 1: data not normally dist'd 
%                 -1: test could not be executed
if Arg.logStats
    % get stats of each channel in the file, build a matrix of stats
    % basic = [rng, M, med, SD, ~]
    % STATs = [sk, k, lopc, hipc, tM, tSD, ~, ksh]
    t = NaN(nchan, 11);
    dountil = nchan;
    for i = 1:dountil
        [t(i,1), t(i,2), t(i,3), t(i,4), ~] = basic_stats(EEG.data(idx(i), :, :));
    end
    try kurtosis(rand(1,10)); catch, dountil = 0; end
    for i = 1:dountil
        [t(i,5), t(i,6), t(i,7), t(i,8), t(i,9), t(i,10), ~, t(i,11)] =...
            STAT_stats(EEG.data(idx(i), :, :), 'tailPrc', 0.05, 'alpha', 0.05);
    end
    
    % create a table from the stats
    colnames = {'range' 'M' 'med' 'SD'...
        'skew' 'kurt' 'lo_pc', 'hi_pc' 'trim_mean', 'trim_stdv', 'ks_norm'};
    statab = array2table(t, 'RowNames', {EEG.chanlocs(idx).labels}'...
        , 'VariableNames', colnames); %#ok<*NASGU>
    
    % save table to per subject mat file, in peek directory
	save(fullfile(savepath, 'signal_stats.mat'), 'statab');
    
    % Write the stats for each peek for each subject to 1 log file
    stalog = fullfile(Cfg.env.paths.logRoot, 'peek_stats_log.txt');
    myReport(sprintf('\n%s peek channel statistics at step set %d, function %d'...
        , EEG.CTAP.measurement.casename, Cfg.pipe.current.set...
        , Cfg.pipe.current.funAtSet), stalog);
    myReport(['Row' statab.Properties.VariableNames], stalog);
    celtab = [statab.Properties.RowNames table2cell(statab)];
    for r = 1:size(statab, 1)
        myReport(celtab(r, :), stalog);
    end

end


%% Plot histograms of all channels
if Arg.plotEEGHist
    % Loop the channels so not all plots are forced onto one page
    fx = Arg.hists;
    for i = 1:fx:nchan
        fh = eeglab_plot_channel_properties(EEG, idx(i:min(i+fx-1, nchan)), fx);
        %named after channels shown
        savename = sprintf('EEGHIST_chan%d-%d.png', i, min(i+fx-1, nchan));
        print(fh, '-dpng', fullfile(savepath, savename));
        close(fh);
    end
end


%% Define latencies to peek at
peekidx = ismember({EEG.event.type}, 'peeks'); 
if sum(peekidx) > 0
    %peek events present - use them
    starts = [EEG.event(peekidx).latency];
else
    %create new peeks
    if isfield(Arg, 'peekevent')
        peekidx = ismember({EEG.event.type}, Arg.peekevent);
        if isfield(Arg, 'peekindex')
            peekidx = peekidx(Arg.peekindex);
        else
            numpkdx = numel(peekidx);
            if numpkdx > 10
                peekidx = peekidx(1:round(numpkdx / 10):end);
            end
        end
        starts = [EEG.event(peekidx).latency] + 1;
        
    elseif isfield(Cfg.ctap, 'select_evdata') &&...
            isfield(Cfg.ctap.select_evdata, 'evtype')
        peekidx = ismember({EEG.event.type}, Cfg.ctap.select_evdata.evtype);
        starts = [EEG.event(peekidx).latency] + 1;
    else
        [~, ~, epochs] = size(EEG.data);
        eegdur = EEG.xmax * epochs; %length in seconds
        starts = NaN(min(10, round(eegdur / Arg.secs)), 1);
    end
    
    % add peek positins as events
    EEG.event = eeglab_merge_event_tables(EEG.event,...
                eeglab_create_event(starts, 'peeks'),...
                'ignoreDiscontinuousTime');
end

if ~Arg.plotEEGset
   starts = starts(1); 
end


%% Plot raw data from channels
if Arg.plotEEG
    idx = strcmp({EEG.chanlocs.type}, 'EEG');

    % set channels to plot in red
    if isfield(EEG.CTAP, 'badchans') &&...
       isfield(EEG.CTAP.badchans, 'detect')
        markChannels = EEG.CTAP.badchans.detect.chans;
    else
        markChannels = {};
    end

    % plot a number of "peek" windows and save as png(s)
    for i = 1:numel(starts)
        saveid = sprintf('rawEEG_peek%d', i);
        % plot n save one peek window over 'idx' EEG channels, 32 chans/png
        plotNsave_raw(EEG, savepath, saveid ...
                 , 'channels', {EEG.chanlocs(idx).labels}...
                 , 'markChannels', markChannels...
                 , 'startSample', starts(i)...
                 , 'secs', Arg.secs);
    end
    
end


%% Plot raw data from ICA components
if Arg.plotICA
    % Make a dataset to plot
    activations = icaact(EEG.data(EEG.icachansind,:),...
                         EEG.icaweights*EEG.icasphere, 0);
    labels = cellfun(@num2str, num2cell(1:size(activations,1))',...
                'uniformOutput',false);
    labels = strcat('IC', labels);
    ICAEEG = create_eeg(activations,...
                        'fs', EEG.srate,...
                        'channel_labels', labels');
                    
    % plot data in "peek" windows and save as png(s)
    for i = 1:numel(starts)
        saveid = sprintf('rawICA_peek%d', i);
        % plot and save
        plotNsave_raw(ICAEEG, savepath, saveid ...
                 , 'channels', {ICAEEG.chanlocs.labels}...
                 , 'startSample', starts(i)...
                 , 'secs', Arg.secs);
    end

end


%% ERROR/REPORT
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

end %CTAP_peek_data()
