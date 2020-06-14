function [figh, startSamp] = plot_raw(EEG, varargin)
%PLOT_RAW - Plot EEG data to a static 2D figure
%
% Description:
%   Plots raw data, can be channels or components depending on what is passed
% 
% Syntax:
%   [figH, startSamp] = plot_raw(EEG, varargin)
% 
% Input:
%   'EEG'       struct, EEGLAB structured data
% 
% varargin:
%   'dataname'      string, what to call data rows, default = 'Channels'
%   'startSample'   integer, first sample to plot, default = NaN
%   'secs'          integer, a window time to plot relative to the startSample,
%                            given in seconds from min to max, default = [0 16]
%   'epoch'         numeric, if >0 then plot all given data as an epoch/frame,
%                   NB! will look very bad if not given a true frame, default = 0
%   'timeResolution'string, time resolution to plot, sec or ms, default = 'sec'
%   'channels'      cell string array, labels, default = {EEG.chanlocs.labels}
%   'markChannels'  cell string array, labels of bad channels, default = {}
%   'plotEvents'    boolean, add labels & vertical dash lines, default = true
%   'figVisible'    on|off, default = off
%   'eegname'       string, default = EEG.setname
%   'paperwh'       vector, output dimensions in cm - if set to 0,0 uses screen 
%                           dimensions, if either dimension is negative then
%                           calculates from data, default = [0 0]
%   'boxLimits' vector, beginning and end sample to be shaded, 
%                           default = [0 0]
% 
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

% Set dummy outputs
figh = [];
startSamp = -1;


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('EEG', @isstruct)

p.addParameter('dataname', 'Channels', @isstr) %what is data called?
p.addParameter('startSample', 1, @isnumeric) %start of plotting in samples
p.addParameter('secs', [0 16], @isnumeric) %how much to plot
p.addParameter('epoch', 0, @isnumeric) %plot the numbered frame; 0 = continuous
p.addParameter('timeResolution', 'sec', @ischar) %time res to plot, sec or ms
p.addParameter('channels', {EEG.chanlocs.labels}, @iscellstr) %channels to plot
p.addParameter('markChannels', {}, @iscellstr) %channels to plot in red
p.addParameter('plotEvents', true, @islogical)
p.addParameter('figVisible', 'off', @isstr)
p.addParameter('eegname', EEG.setname, @isstr)
p.addParameter('paperwh', [0 0], @isnumeric)
p.addParameter('boxLimits', [0 0], @isnumeric) % in samples

p.parse(EEG, varargin{:})
Arg = p.Results;


%% Initialize CHANNELS
% get rid of missing channels
missingChannels = setdiff(Arg.channels, {EEG.chanlocs.labels});
if ~isempty(missingChannels)
    % some channels could not be found
    fprintf('plot_raw: %s ''%s'' are missing...',...
            Arg.dataname, strjoin(missingChannels,'; '));   
end
CHANNELS = intersect(Arg.channels, {EEG.chanlocs.labels}); 
Arg.markChannels = intersect(CHANNELS, Arg.markChannels);

% Find channel indices (order matters!)
[~, CHANIDX] = ismember(CHANNELS, {EEG.chanlocs.labels});

% sort channels such that rows of 'eegdata' and CHANNELS match
[CHANIDX, si] = sort(CHANIDX);
CHANNELS = CHANNELS(si);


%% Initialize TIME
if strcmp(Arg.timeResolution, 'sec')
    SECS = true;
elseif strcmp(Arg.timeResolution, 'ms')
    SECS = false;
else
    error('plot_raw:badparam'...
        , 'Value of parameter ''timeResolution'' not recognised: %s'...
        , Arg.timeResolution)
end
if Arg.epoch
    Arg.startSample = 1;
    LastSample = EEG.pnts;
    dur = LastSample;
    Arg.secs = [EEG.xmin EEG.xmax];
    if ~SECS
        Arg.secs = Arg.secs * 1000;
    end
    eegdata = EEG.data(CHANIDX, :);
else

    %Time in seconds
    if isscalar(Arg.secs), Arg.secs = [0 Arg.secs]; end
    Arg.secs = sort(Arg.secs);

    %Epoched or continuous?
    switch ndims(EEG.data)
        case 3
            [~, col, eps] = size(EEG.data);
            eegdata = EEG.data(CHANIDX, 1:col * eps);
            Arg.secs(2) = min([Arg.secs(2) (col * eps) / EEG.srate]);
        case 2
            eegdata = EEG.data(CHANIDX, :);
            Arg.secs(2) = min([Arg.secs(2) EEG.xmax]);
    end

    %Time in samples, set to integer, as EEG latencies are often double
    Arg.startSample = int64(max(Arg.startSample + (Arg.secs(1) * EEG.srate), 1));
    
    %get the data duration in samples
    dur = floor(min([EEG.srate * diff(Arg.secs), EEG.pnts - Arg.startSample]));
    if dur <= 0
        warning('plot_raw:duration_zero', 'Duration was 0 - no plot made')
        return
    end
    
    LastSample = min(Arg.startSample + dur - 1, EEG.pnts);
    
    if SECS
        Arg.secs = single(round([Arg.startSample / EEG.srate, LastSample / EEG.srate]));
    else
        % for ms-resolution time windows (now think of Arg.secs as milliseconds)!!
        Arg.secs = Arg.secs * 1000;
    end
end


%% Setup Plot
sig = eegdata(:, Arg.startSample:LastSample);

% get x-axis tick values
xt = linspace(Arg.secs(1), Arg.secs(2), dur);

%Build y-shifted data matrix so channels cannot overlap
mi = min(sig, [], 2);
match = abs(mi) < 1e-4;
mi(match) = mean(mi); %to get space around low variance channels

ma = max(sig, [], 2);
match = abs(ma) < 1e-4;
ma(match) = mean(ma); %to get space around low variance channels

shift = cumsum([0; abs(ma(1:end - 1)) + abs(mi(2:end))]);
shift = repmat(shift, 1, dur);
sig = sig + shift;


%% fix page size and associated dimensions
% IF paper width+height has been specified as 0,0 then use screen dims
if sum(Arg.paperwh) == 0
    %ScreenSize is a four-element vector: [left, bottom, width, height]:
    figh = figure('Position', get(0,'ScreenSize'),...
                  'Visible', Arg.figVisible);
else
    %IF paper width or height is set as negative, estimate from data dimensions
    t_width = diff(Arg.secs);
    if ~SECS %if showing milliseconds, give 5x as much space as for secs
        t_width = t_width / 200;
    end
    if Arg.paperwh(1) < 0
        Arg.paperwh(1) = ceil((log2(t_width) + 1) .* 4);
    end
    if Arg.paperwh(2) < 0
        Arg.paperwh(2) = numel(CHANNELS) * 0.8;
    end
    figh = figure('PaperType', '<custom>',...
                  'PaperUnits', 'centimeters',...
                  'PaperPositionMode', 'manual',...
                  'PaperPosition', round([0 0 Arg.paperwh]),...
                  'Visible', Arg.figVisible);
end


%% plot EEG data
% rows must be plotted one by one, otherwise ordering information is lost!
hold on;
for i = 1:size(eegdata, 1)
    ploh = plot(xt, sig(i, :), 'b');
    if ismember(CHANNELS{i}, Arg.markChannels)% color marked channels
        set(ploh, 'Color', [1 0 0]);
    end
end
hold off;


%% edit axes & prettify
set(gca, 'YTick', mean(sig, 2), 'YTickLabel', CHANNELS)
if SECS
    set(gca, 'XTick', Arg.secs(1):Arg.secs(2), 'XTickLabel', cellfun(@(x)...
        sprintf('%d',x), num2cell(Arg.secs(1):Arg.secs(2)), 'Un', false)...
        , 'XTickLabelRotation', 45)
end
grid on
if Arg.plotEvents && ~isempty(EEG.event)
    ylim([mi(1) 1.1*max(max(sig))])
else
    ylim([mi(1) max(max(sig))])
end
xlim(Arg.secs)
xbds = double(get(gca, 'xlim'));
ybds = double(get(gca, 'ylim'));
top = ybds(2);
 
%% draw a y-axis scalebar at 10% of the total range of the y-axis
sbar = ybds(1) + (diff(ybds) / 10);
sbr100 = ybds(1) + 100; %plus another one at 100 uV
xw = xbds(1) + diff(xbds) * 1.02;
line([xw xw], [ybds(1) sbar], 'color', 'b', 'clipping', 'off')
text(xw, sbar, '\muV', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
text(xw, sbar, num2str(round(sbar)), 'VerticalAlignment', 'top')
if sbar < 90 || sbar > 110
    text(xw, ybds(1) + 100, '100', 'color', 'r'...
        , 'VerticalAlignment', 'bottom')
end
xw = xbds(1) + diff(xbds) * 1.04;
line([xbds(2) xw], [ybds(1) ybds(1)], 'color', 'b', 'clipping', 'off')
line([xbds(2) xw], [sbar sbar], 'color', 'b', 'clipping', 'off')
line([xbds(2) xw], [sbr100 sbr100], 'color', 'r', 'clipping', 'off')


%% make shaded area
set(figh, 'Color', 'w')
if all(Arg.boxLimits > 0)
    tr = 1;
    if ~SECS
        tr = 1000;
    end
    x = xbds(1) + (Arg.boxLimits(1) - Arg.startSample) / EEG.srate * tr;
    y = ybds(1);
    w = (Arg.boxLimits(2) - Arg.boxLimits(1)) / EEG.srate * tr;
    h = ybds(2) - ybds(1);
    rectangle('Position', [x, y, w, h], 'EdgeColor', 'red', 'LineWidth', 1);
end


%% plot events
if Arg.plotEvents && ~isempty(EEG.event) 
    evlat = int64(cell2mat({EEG.event.latency}));
    evlatidx = (evlat >= Arg.startSample) & ...
               (evlat <= LastSample);

    if any(evlatidx) %note: to plot, we need events in range to plot
        t = NaN;
        evplot = EEG.event(evlatidx);
        
        peekidx = ismember({evplot.type}, 'ctapeeks');
        blinkidx = ismember({evplot.type}, 'blink');
        
        % plot original events
        if any(~(peekidx | blinkidx))
            evs = evplot(~(peekidx | blinkidx));
            t = sbf_plotevt([evs.latency], {evs.type}, [0.5 0.5 0.5]);
        end
        % plot detected blinks
        if any(blinkidx)
            blinks = evplot(blinkidx);
            sbf_plotevt([blinks.latency], {blinks.type}, 'r', [0.9 0.9 0.9 0.5]);
        end
        % plot any peeks
        if any(peekidx)
            pk = evplot(peekidx);
            t = sbf_plotevt([pk.latency], {pk.label}, 'g', [0.9 0.9 0.9 0.5]);
        end
        if isa(t, 'matlab.graphics.primitive.Text')
            top = t.Extent;
            top = top(2) + top(4);
        end
    end
end
%return output value
startSamp = Arg.startSample;


%% TITLE
title( sprintf('%s -\n raw %s', Arg.eegname, Arg.dataname),...
    'Position', [xbds(1) + diff(xbds) / 2 top],...
    'VerticalAlignment', 'bottom', ...
    'Interpreter', 'none');


%% FONT ELEMENTS
%only need to fix font sizes if there is more than one channel to plot
if length(CHANIDX) > 1
    %Determine y-axis-relative proportion & fix size of everything
    fsz = 0.5 * (1 / figh.PaperPosition(4) - figh.PaperPosition(2));
    set(findall(figh, '-property', 'FontUnits'), 'FontUnits', 'normalized')
    set(findall(figh, '-property', 'FontSize'), 'FontSize', fsz)

    % do the axis tick-labels so there is no overlap
    fsz = 1 / (diff(ybds) / min(diff(mean(sig, 2))));
    set(gca, 'FontSize', fsz)
end
%ONLY IN r2016:: do the Y-AXIS tick-labels so there is no overlap
% ax = ancestor(ploh, 'axes');
% yrule = ax.YAxis;
% yrule.FontSize = fsz;

%AXIS LABELS
if SECS
    xlabel( sprintf('Time\n[samples=%d:%d - seconds=%1.0:%1.0f]'...
        , Arg.startSample, LastSample...
        , Arg.secs(1) / EEG.srate, LastSample / EEG.srate) )
else
    ep = '';
    if Arg.epoch, ep = sprintf('Epoch=%d - ', Arg.epoch); end
    xlabel( sprintf('Time\n[%ssamples=%d:%d - milliseconds=%d:%d]'...
        , ep, Arg.startSample, LastSample...
        , Arg.secs(1), Arg.secs(2)) )
end
ylabel(Arg.dataname)


    function txt = sbf_plotevt(evlats, evplottyp, lnclr, bgclr)
        if nargin < 4, bgclr = 'none'; end
        if nargin < 3, lnclr = 'k'; end
        
        evplotlat = double(evlats) ./ EEG.srate;
        
        for idx = 1:numel(evplotlat)
            line([evplotlat(idx) evplotlat(idx)], ybds...
                , 'color', lnclr, 'LineWidth', 0.5, 'LineStyle', '--')
            txt = text(evplotlat(idx), double(max(ybds)), evplottyp{idx}...
                , 'BackgroundColor', bgclr...
                , 'Rotation', -90 ...
                , 'Interpreter', 'none'...
                , 'VerticalAlignment', 'bottom'...
                , 'HorizontalAlignment', 'left');
        end
    end

end % plot_raw()
