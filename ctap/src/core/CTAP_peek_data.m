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
%       .logStats       logical, compute stats for whole data, default: true
%       .peekStats      logical, compute stats for each peek, default: false
%       .secs           numeric, seconds to plot from min to max, default: 0 16
%       .peekevent      cellstring array, event name(s) to base peek windows on
%       .peekindex      vector, index of such events to use, default (only if 
%                       .peekevent is defined): uniform distribution of 10
%       .hists          scalar, square number histograms per figure, default: 16
%       .channels       cellstring array, chanlocs labels or type, default: 'EEG'
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
Arg.peekStats = false;
Arg.secs = [0 16];
Arg.hists = 16; %number of histograms per figure, should be square
Arg.channels = 'EEG';

% Override defaults with user parameters...
if isfield(Cfg.ctap, 'peek_data')
    Arg = joinstruct(Arg, Cfg.ctap.peek_data); %override with user params
end
%...but ICs must be present
Arg.plotICA = Arg.plotICA && ~isempty(EEG.icaweights);
%...and seconds must be a relative [min max] pair
if isscalar(Arg.secs), Arg.secs = [0 Arg.secs]; end
Arg.secs = sort(Arg.secs);
duration = diff(Arg.secs);
if ~isscalar(duration) || (duration < 1)
    error('CTAP_peek_data:inputError', 'Arg.secs must be [min max], max-min>1.'); 
end
%...and we treat only EEG channels
if ismember('EEG', Arg.channels)
    idx = get_eeg_inds(EEG, {'EEG'});
else
    idx = find(ismember({EEG.chanlocs.labels}, Arg.channels));
end
if numel(idx) == 0
   error('CTAP_peek_data:inputError', 'Channels not found. Check Arg.channels'); 
end
nchan = numel(idx);


%% Define directory to save stuff to
args = logical([Arg.plotEEGHist Arg.plotEEG Arg.plotICA Arg.logStats]);
if any(args)
    savepath = get_savepath(Cfg, mfilename, 'qc');
    savepath = fullfile(savepath, EEG.CTAP.measurement.casename);
    prepare_savepath(savepath);
    
    plotz = {'Histogram' 'Raw EEG' 'Independent Components' 'Channel stats'};
    myReport(sprintf('\n'), Cfg.env.logFile);
    msg = myReport(sprintf('Saving Diagnostics to ''%s''\nFor %s'...
        , savepath, sprintf('''%s'', ', plotz{args})), Cfg.env.logFile);

else
    return;
end


%% make and save stats to log file
if Arg.logStats
    
%     % get stats of each channel in the file, build a matrix of stats
%     % basic = [rng, M, med, SD, ~]
%     % STATs = [sk, k, lopc, hipc, tM, tSD, ~, ksh]
%     t = NaN(nchan, 11);
%     for i = 1:nchan
%         [t(i,1), t(i,2), t(i,3), t(i,4), ~] = basic_stats(EEG.data(idx(i), :, :));
%         [t(i,5), t(i,6), t(i,7), t(i,8), t(i,9), t(i,10), ~, t(i,11)] =...
%             STAT_stats(EEG.data(idx(i), :, :), 'tailPrc', 0.05, 'alpha', 0.05);
%     end
%     %todo: for jkor this raises:
% %   Assignment has more non-singleton rhs dimensions than non-singleton subscripts
% % 
% %   Error in CTAP_peek_data (line 121)
% %       [t(i,5), t(i,6), t(i,7), t(i,8), t(i,9), t(i,10), ~, t(i,11)] =...
%     
%     % create a table from the stats
%     colnames = {'range' 'M' 'med' 'SD'...
%         'skew' 'kurt' 'lo_pc', 'hi_pc' 'trim_mean', 'trim_stdv', 'ks_norm'};
%     statab = array2table(t, 'RowNames', {EEG.chanlocs(idx).labels}'...
%         , 'VariableNames', colnames); %#ok<*NASGU>
%     
%     % save table to per subject mat file, in peek directory
% 	save(fullfile(savepath, 'signal_stats.mat'), 'statab');
    
    [~, ~, statab] = ctapeeg_stats_table(EEG, 'channels', idx...
        , 'outdir', savepath, 'id', 'peekall');
    
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
peekmatch = ismember({EEG.event.type}, 'peeks'); 
if sum(peekmatch) > 0
    %peek events present - use them
    starts = [EEG.event(peekmatch).latency];
else
    %create new peeks
    if isfield(Arg, 'peekevent')
        % based on events
        peekidx = find(ismember({EEG.event.type}, Arg.peekevent));
        if isfield(Arg, 'peekindex')
            peekidx = peekidx(Arg.peekindex);
            % todo: is this really useful?
        else
            numpkdx = numel(peekidx);
            if numpkdx > 10
                peekidx = peekidx(1:round(numpkdx / 10):end);
            end
        end
        % starts = [EEG.event(peekidx).latency] + 1;
        % make start 5 sec before event
        starts = [EEG.event(peekidx).latency] - 5 * EEG.srate;
        starts = starts(0 < starts); %remove possible negative values
        
    elseif isfield(Cfg.ctap, 'select_evdata') &&...
            isfield(Cfg.ctap.select_evdata, 'evtype')
        peekmatch = ismember({EEG.event.type}, Cfg.ctap.select_evdata.evtype);
        starts = [EEG.event(peekmatch).latency] + 1;
    else
        % todo: what does NaN as latency stand for? This option causes
        % funny effects if peek latencies are NaN...
        [~, ~, epochs] = size(EEG.data);
        eegdur = EEG.xmax * epochs; %length in seconds
        starts = NaN(min(10, round(eegdur / duration)), 1);
    end
    
    % add peek positions as events
    labels = cellfun(@(x) sprintf('peek%d',x), num2cell(1:numel(starts)),...
                      'UniformOutput', false);
    %ns = numel(starts);
    %n = num2str(1:ns)';
    %labels = strcat(repmat({'peek'},ns,1), n(~cellfun(@isempty, cellstr(n))));
    EEG.event = eeglab_merge_event_tables(EEG.event,...
                eeglab_create_event(starts, 'peeks', 'label', labels),...
                'ignoreDiscontinuousTime');
            
    peekmatch = ismember({EEG.event.type}, 'peeks'); %assumed to exist later on
end

if ~Arg.plotEEGset
   starts = starts(1); 
end


%% calculate stats for each peek separately
if Arg.peekStats
    % grab stats for a number of "peek" windows and save tables as mat files
    for i = 1:numel(starts)
        ctapeeg_stats_table(EEG, 'channels', idx...
            , 'latency', starts(i) + Arg.secs(1) * EEG.srate...
            , 'duration', duration * EEG.srate...
            , 'outdir', savepath, 'id', sprintf('peek%d', i));
    end
end


%% Plot raw data from channels
if Arg.plotEEG

    % set channels to plot in red
    if isfield(EEG.CTAP, 'badchans') &&...
       isfield(EEG.CTAP.badchans, 'detect')
        markChannels = EEG.CTAP.badchans.detect.chans;
    else
        markChannels = {};
    end
    
    % Find labels for peeks
    if isfield(EEG.event, 'label')
        labels = {EEG.event(peekmatch).label};
    else
        % todo: dangerous to resort to this, make sure labels always exist!
        labels = cellfun(@(x) sprintf('peek%d',x), num2cell(1:sum(peekmatch)),...
                    'UniformOutput', false);
    end
    
    % plot a number of "peek" windows and save as png(s)
    for i = 1:numel(starts)
        % plot n save one peek window over 'idx' EEG channels, max 32 chans/png
        plotNsave_raw(EEG, savepath, sprintf('rawEEG_%s', labels{i})...
                , 'channels', {EEG.chanlocs(idx).labels}...
                , 'markChannels', markChannels...
                , 'startSample', starts(i)...
                , 'secs', Arg.secs...
                , 'paperwh', [-1 -1]);
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
    ICAEEG.setname = sprintf('%s_ICA', EEG.setname);
                    
    % plot data in "peek" windows and save as png(s)
    for i = 1:numel(starts)
        % plot and save
        plotNsave_raw(ICAEEG, savepath, sprintf('rawICA_peek%d', i)...
                , 'dataname', 'IC activations'...
                , 'channels', {ICAEEG.chanlocs.labels}...
                , 'startSample', starts(i)...
                , 'secs', Arg.secs...
                , 'paperwh', [-1 -1]...
                , 'plotEvents', false);
    end

end


%% ERROR/REPORT
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

end %CTAP_peek_data()
