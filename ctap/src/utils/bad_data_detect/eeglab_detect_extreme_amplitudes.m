function [EEG, Rej] = eeglab_detect_extreme_amplitudes(EEG, varargin)
%EEGLAB_DETECT_EXTREME_AMPLITUDES - Detection of extreme amplitudes using simple thresholding 
%
% Description:
%   Performs distribution/histogram analysis for sample amplitudes for all 
%   channels specified using varargin 'rejectionChannels'. The default is
%   all channels.
%   Uses amplitude histogram quantiles and fixed thresholding to assign 
%   samples as bad. If enough channels are bad for a given sample then the
%   sample is marked bad for all channels i.e. an event is created into
%   EEG.event.  
%
% Algorithm:
%   1. Compute quantiles separately for each channel
%   2. Select which rejection threshold to use: use either default limits
%      or quantile limits, whichever is bigger
%   3. Assign samples as bad for all channels: if more than coOccurrencePrc
%      of the channels have marked the sample the sample is marked bad
%   4. Create events and return results
%
% Syntax:
%   [EEG, Rej] = eeglab_detect_extreme_amplitudes(EEG, varargin);
%
% Inputs:
%   EEG     struct, EEGLAB EEG dataset
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%
%
% Outputs:
%   EEG     struct, EEGLAB struct with bad segments inserted as events,
%           whose type is defined by varargin 'eventIdStr'.
%   Rej     struct, Details about the rejection. Only for channels listed
%           by varargin 'rejectionChannels'.
%       .th         [nchan, 2] numeric, Actually used lower and upper 
%                   rejection threshold in muV
%       .qntTh      [nchan, 2] numeric, Quantile based rejection threshold
%                   in muV
%       .defaultTh  [1,2] numeric, Default rejection threshold in muV
%       .match      [nchan, nsamples] logical, Bad segment matches for all 
%                   analyzed channels
%       .allChannelsMatch  [1, nsamples] logical, Final "all channel" bad segment
%                   matches
%       .allChannelsPrc    [1,1] numeric in [0...1], Percentage of samples marked 
%                   as belonging to a bad segment
%       .allChannelsCount      [1,1] integer, Number of bad segment events
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also:
%
% Copyright 2015- Jussi Korpela FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAYBEDO: Add the possibility to plot channel histograms and rejection
% thresholds. Appropriate code exists but the plotting function behaves
% badly when there are many channels.

%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true; %to avoid error due to non-matching varargin

p.addRequired('EEG', @isstruct);
p.addParameter('rejectionChannels', {EEG.chanlocs(:).labels}, @iscellstr);
p.addParameter('filter', false, @islogical);
p.addParameter('rejectionMaskWidth', 0.2, @isnumeric); %in seconds
p.addParameter('tailPercentage', 0.001, @isnumeric); %percentage in [0...1]
% Small probability on each channel but altogether might result in a high
% proportion of data marked as bad. See also normalEEGAmpLimits.
p.addParameter('normalEEGAmpLimits', [-75, 75], @isnumeric); %in muV
p.addParameter('coOcurrencePrc', 0.25, @isnumeric); %percentage in [0...1]
p.addParameter('eventIDStr', 'artefactAmpTh', @ischar);

p.parse(EEG, varargin{:});
Arg = p.Results;

filter_func = 'widmann';

%% Define rejection dataset
rejChanMatch = ismember({EEG.chanlocs.labels}, Arg.rejectionChannels);


%% Filter the data
if Arg.filter
    locutoff = 1;
    hicutoff = 0;
    filtorder = EEG.srate;
    
    switch filter_func
        case 'eeglab'
            revfilt = 0;
            firtype = 'fir1';
            epochframes = 0;
            eegdata = EEG.data(rejChanMatch,:);
            eegdata = eegfilt(eegdata, EEG.srate, locutoff, hicutoff,...
                              epochframes, filtorder, revfilt, firtype);

        case 'widmann'
            %
            TMP = pop_select(EEG, 'channel', rejChanMatch);
            m = pop_firwsord('hamming', filtorder, [locutoff hicutoff]);
            b = firws(m, [locutoff hicutoff] / (filtorder / 2), 'high'...
                , windows('hamming', m + 1));
            TMP = firfilt(TMP, b);
            eegdata = TMP.data;
    end
else
    eegdata = EEG.data(rejChanMatch,:); %unfiltered
end


%% Remove data baseline
eegdata = eegdata - repmat(mean(eegdata, 2), 1, size(eegdata, 2));


%% Plotting related setup
%{
nSamplesPerBin = 1000;
channelOrder = {EEG.chanlocs(:).labels};
plotGrid = [ceil(size(EEG.data,1)/2),2];
showPlot = false;
savePlot = false;
savePath = cd();
nSamplesPerBin = 50;
[N_chan, N_samples] = size(eegdata);
chan_names = {EEG.chanlocs(:).labels};
N_hist_bins = round(N_samples/nSamplesPerBin);
ydata = NaN(N_chan, 1, N_hist_bins);
xdata = NaN(N_chan, N_hist_bins);
plotorder = NaN(1,N_chan);

%   ydata   dim1 = r = n*m = subplots
%           dim2 = k = traces in subplot (i)
%           dim3 = p = samples of trace(k_i) in subplot (i)
%}


%% Analyze data amplitudes for each channel
rej_match = true(size(eegdata));
qnt_th = NaN(size(rej_match,1),2);
rej_th = NaN(size(rej_match,1),2);

fprintf('Analyzing channels: %s...', strjoin(Arg.rejectionChannels, ', '))
for i = 1:size(rej_match,1) %over channels
    % Compute quantiles
    qnt_th(i,:) = [ quantile(eegdata(i,:), (Arg.tailPercentage/2)),...
                    quantile(eegdata(i,:), 1-(Arg.tailPercentage/2))];
                    %[low, high]
    
    % Select default or quantile based limit (more extreme selected)
    i_rej_low = min(Arg.normalEEGAmpLimits(1), qnt_th(i,1));
    i_rej_high = max(Arg.normalEEGAmpLimits(2), qnt_th(i,2));
    
    rej_match(i,:) = ((eegdata(i,:) <= i_rej_low) | ...
                      (eegdata(i,:) >= i_rej_high));
   
    rej_th(i,:) = [i_rej_low i_rej_high];

    %{
    % Plotting related
    %hist(eegdata(i,:), N_hist_bins);
    N_hist_bins = 100;
    rej_prc = sum(rej_match(i,:))/EEG.pnts*100;
    [i_n, i_binc] = hist(eegdata(i,:), N_hist_bins);
    ydata(i,1,:) = i_n;
    xdata(i,:) = i_binc;
    
    vert_line_pos(i) = {rej_th(i,:)}; 
    legendstrs{i} = {[Arg.rejectionChannels{i} ': rejected ' num2str(rej_prc,'%2.3f') ' %']};
    plotorder(i) = find(ismember(channelOrder, Arg.rejectionChannels{i}));
    ylabels(i) = {'Hist bin count'};
    xlabels = {'Amplitude muV'};
    %}
    
    clear('i_*');
end


%% Refine segments found
rej_match = double(rej_match); % convert to numeric

% Make rejection a bit wider around artefacts
rejmask = ones(1, round(EEG.srate*Arg.rejectionMaskWidth));
for i=1:size(rej_match,1)
    rej_match(i,:) = conv(rej_match(i,:), rejmask, 'same');
    rej_match(i,:) = rej_match(i,:) > 0; %conversion to logical
end


%% Combine rejection match from all rejection channels
% Needed as channels cannot have separate boundary events in EEGLAB
chCountTh = max(1, floor(Arg.coOcurrencePrc * size(rej_match, 1)));
rej_counts = sum(rej_match, 1);
samprej_match = rej_counts >= chCountTh; %[1,EEG.pnts] logical
% Expand overlaps
samprej_match = conv(single(samprej_match), rejmask, 'same'); %make wider
samprej_match = samprej_match > 0; %conversion to logical


%% Add as events
if sum(samprej_match)~=0
    % found something to reject
    rej_inds = find_contiguous_range(samprej_match, 1);
    durat = rej_inds(:,2)-rej_inds(:,1);

    % create th rejection events
    th_event = eeglab_create_event(rej_inds(:,1),Arg.eventIDStr,...
                                    'duration', num2cell(durat));
    %th_event2 = eeglab_create_event(rej_inds(:,2),'artefact_amplitudeth_end');

    EEGtmp = EEG;
    EEGtmp = rmfield(EEGtmp, 'data');
    EEGtmp.event = th_event;

    if ~isempty(EEG.event)
        EEG.event = eeglab_merge_event_tables(EEG.event, EEGtmp.event,...
                                                    'ignoreDiscontinuousTime');
    else
        EEG.event = eeglab_merge_event_tables(EEGtmp.event,...
                                                    'ignoreDiscontinuousTime');
    end

    clear('EEGtmp*');
else
    rej_inds = [];
    disp('No artefactual segments found.')
end  


%% Set output
% Channel specific 
Rej.th = rej_th;
Rej.defaultTh = Arg.normalEEGAmpLimits;
Rej.qntTh = qnt_th;
Rej.match = rej_match;

% Concerning all channels
Rej.allChannelsMatch = samprej_match;
Rej.allChannelsPrc = sum(samprej_match)/EEG.pnts;
Rej.allChannelsCount = size(rej_inds, 1);


%% Plot and save
%{
if Arg.showPlot
    fh = figure();
else
    fh = figure('Visible','off');
end  
%this allows for the creation of an invisible figure. But calling plot
makes the figure visible again.... pläh...


if Arg.savePlot
    fh = plot_nxm(xdata, ydata, plotGrid,...
        'plotorder', plotorder,...
        'xlinePos', vert_line_pos,...
        'plotlegend', 'all',...
        'legendstrs', legendstrs,...
        'ylabels', ylabels,...
        'xlabels', xlabels,...
        'xlimits', repmat([-500,500],size(ydata,1),1),...
        'titlestr','Channel amplitude histograms');
        %set(gcf, 'Position',  [0 0.0244 0.5000 0.8701]);

    [status,message,messageid] = mkdir(Arg.savePath);
    savename = ['channel-histograms_' EEG.ttl.ssc.measurement.casename '.png'];
    saveas(fh, fullfile(Arg.savePath, savename));
    close(fh);
end
%}