function [figH, startSamp] = plot_raw(EEG, varargin)
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
%   'dataname'      string, what to call data, default = 'Channels'
%   'startSample'   integer, first sample to plot, default = NaN
%   'secs'          integer, seconds to plot, default = 16
%   'channels'      cell string array, labels, default = {EEG.chanlocs.labels}
%   'markChannels'  cell string array, labels of bad channels, default = {}
%   'plotEvents'    boolean, plot event labels & vertical marker lines,
%                   default = true
%   'figVisible'    on|off, default = off
%   'eegname'       string, default = EEG.setname
%   'fdims'         vector, default = get(0,'ScreenSize')
%   'shadingLimits' vector, beginning and end sample to be shaded, 
%                   default = [NaN NaN]
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


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);

p.addParameter('dataname', 'Channels', @isstr); %what is data called?
p.addParameter('startSample', NaN, @isnumeric); %start of plotting in samples
p.addParameter('secs', 16, @isnumeric); %how much to plot
p.addParameter('channels', {EEG.chanlocs.labels}, @iscellstr); %channels to plot
p.addParameter('markChannels', {}, @iscellstr); %channels to plot in red
p.addParameter('plotEvents', true, @islogical);
p.addParameter('figVisible', 'on', @isstr);
p.addParameter('eegname', EEG.setname, @isstr);
p.addParameter('fdims', get(0,'ScreenSize'), @isnumeric);
p.addParameter('shadingLimits', [NaN NaN], @isnumeric); % in samples

p.parse(EEG, varargin{:});
Arg = p.Results;


%% Initialize 
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


%% Setup Plot
%Epoched or continuous?
switch ndims(EEG.data)
    case 3
        [~, col, eps] = size(EEG.data);
        eegdata = EEG.data(CHANIDX, 1:col * eps);
        Arg.secs = min([Arg.secs (col * eps) / EEG.srate]);
    case 2
        eegdata = EEG.data(CHANIDX, :);
        Arg.secs = min([Arg.secs EEG.xmax]);
end

dur = floor(min([EEG.srate * Arg.secs,...
                 size(eegdata, 2) - min(Arg.shadingLimits)]));
if dur == 0
    warning('plot_raw:duration_zero', 'Duration was 0 - no plot made')
    return
end
if isnan(Arg.startSample)
    Arg.startSample = ceil(rand(1) * ((size(eegdata, 2) - dur) + 1));
elseif ~isinteger(Arg.startSample)
    %set Arg.startSample to integer, as EEG latencies are often double
    Arg.startSample = int64(Arg.startSample);
end

t = linspace(0, Arg.secs, dur);
sig = eegdata(:, Arg.startSample:Arg.startSample + dur - 1);
% calculate shift
mi = min(sig, [], 2);
match = abs(mi) < 1e-4;
mi(match) = mean(mi); %to get space around low variance channels

ma = max(sig, [], 2);
match = abs(ma) < 1e-4;
ma(match) = mean(ma); %to get space around low variance channels

shift = cumsum([0; abs(ma(1:end - 1)) + abs(mi(2:end))]);
shift = repmat(shift, 1, round(dur));
sig = sig + shift;


%% plot EEG data
figH = figure('Position', Arg.fdims, 'Visible', Arg.figVisible);
hold on;
for i = 1:size(eegdata, 1)
    % have to be plotted one by one, otherwise ordering information is lost!
    h = plot(t, sig(i, :), 'b');
    if ismember(CHANNELS{i}, Arg.markChannels)% color marked channels
        set(h, 'Color', [1 0 0]);
    end
end
hold off;
title( sprintf('%s \n raw data - samples=%d:%d - secs=%1.0f:%1.0f',...
    Arg.eegname, Arg.startSample,...
    Arg.startSample+dur, Arg.startSample / (EEG.srate),...
    (Arg.startSample+dur) / (EEG.srate)),...
    'Interpreter', 'none')


%% edit axes & prettify
set(gca, 'YTick', mean(sig, 2), 'YTickLabel', CHANNELS);
xlabel('Seconds')
ylabel(Arg.dataname)
grid on
ylim([mi(1) max(max(sig))])
xlim([0 Arg.secs])
xbds = double(get(gca, 'xlim'));
ybds = double(get(gca, 'ylim'));
 
%draw a y-axis scalebar at 10% of the total range of the y-axis
sbar = (ybds(2) - ybds(1)) / 10;
sbarh = ybds(1) + sbar;
line(xbds(2) .* [1.02 1.02], [ybds(1) sbarh], 'color', 'b', 'clipping', 'off')
line(xbds(2) .* [1 1.04], [ybds(1) ybds(1)], 'color', 'b', 'clipping', 'off')
line(xbds(2) .* [1 1.04], [sbarh sbarh], 'color', 'b', 'clipping', 'off')
text(xbds(2) * 1.022, ybds(1) + sbar / 2, sprintf('%d uV', round(sbar)))


set(figH, 'Color', 'w');

% make shaded area
if ~isnan(Arg.shadingLimits(1))
    x = (Arg.shadingLimits(1) - Arg.startSample) / EEG.srate;
    y = ybds(1);
    w = (Arg.shadingLimits(2) - Arg.shadingLimits(1)) / EEG.srate;
    h = ybds(2) - ybds(1);
    rectangle('Position', [x, y, w, h], 'EdgeColor', 'red', 'LineWidth', 2);
end


%% plot events
if Arg.plotEvents && ~isempty(EEG.event)
    peek = ['peek-at-' num2str(Arg.startSample)];
    evlat = int64(cell2mat({EEG.event.latency}));
    evlatidx = evlat > Arg.startSample & evlat < Arg.startSample + dur - 1;
    evplot = EEG.event(evlatidx);
    if sum(evlatidx)
        evplotlat = [[evplot.latency] Arg.startSample + 1];
        evplottyp = {evplot.type peek};
    else
        evplotlat = Arg.startSample + 1;
        evplottyp = peek;
    end
    evplotlat = double(evplotlat - Arg.startSample) ./ EEG.srate;
    for i = 1:numel(evplot)
        line([evplotlat(i) evplotlat(i)], ybds...
                , 'color', 'k', 'LineWidth', 1, 'LineStyle', '--')
        text(evplotlat(i), double(max(ybds)), evplottyp{i}...
                , 'BackgroundColor', [0.9 0.9 0.9], 'Interpreter', 'none')
    end
end
startSamp = Arg.startSample;

end % plot_raw()
