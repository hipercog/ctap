function figh = ctap_plot_basic_erp(erp, pnts, zeropt, srate, varargin)


%% parse input
P = inputParser;

P.addRequired('erp', @isnumeric)
P.addRequired('pnts', @isscalar) %TODO : can't this be inferred from data?
P.addRequired('zeropt', @isscalar)
P.addRequired('srate', @isscalar)

P.addParameter('waves', {}, @(x) iscell(x) & ismatrix(x))
P.addParameter('areas', {}, @iscell)
P.addParameter('vlines', [], @isvector)
P.addParameter('tkoffset', 0, @isscalar)
P.addParameter('tkjump', 100, @isscalar)
P.addParameter('lgnd', '', @(x) iscellstr(x) | ischar(x)) %#ok<ISCLSTR>
P.addParameter('ttl', '', @ischar)
P.addParameter('xlbl', 'Time (sec)', @ischar)
P.addParameter('ylbl', 'amplitude (\muV)', @ischar)
P.addParameter('timeunit', 'sec', @ischar)

P.parse(erp, pnts, zeropt, srate, varargin{:})
P = P.Results;


%% Sort out time
P.tkjump = 1000 / P.tkjump; % convert milliseconds to fractions of a second
if ismember(lower(P.timeunit), {'ms' 'millis' 'millisec' 'msec' 'millisecond'})
    t = 1000 / srate;
    r = -2;
else
    t = 1 / srate;
    r = 2;
end


%% initial curve plots
plot(erp', 'Linewidth', 2)
hold on

cols = get(gca, 'colororder');
if ~isempty(P.waves)
    for idx = 1:numel(P.waves)
        plot(P.waves{idx}', 'Linewidth', 1, 'color', [cols(idx, :) 0.35])
    end
    plot(erp', 'LineWidth', 3)
elseif ~isempty(P.areas)
    x = 1:pnts;
    for idx = 1:numel(P.areas)
        y1 = P.areas{idx}(1, :);
        y2 = P.areas{idx}(2, :);
        plot(x,y1)
        plot(x,y2)
        patch([x fliplr(x)], [y1 fliplr(y2)], cols(idx, :))
    end
    plot(erp', 'LineWidth', 3)
end
set(gca, 'ColorOrderIndex', 1)


%% test window areas
ylim = get(gca, 'ylim');
if ~isempty(P.vlines)
    for v = 1:2:numel(P.vlines)
        x = (P.vlines(v:v+1) / t) + zeropt;
        ar = area(x, [ylim(2) ylim(2)], ylim(1), 'LineStyle', 'none');
        ar.FaceAlpha = 0.4;
        ar.FaceColor = [0.8 0.8 0.8];
    end
end

%% overplotting
line([zeropt zeropt], ylim, 'Color', 'k', 'LineStyle', '--')
plot(erp(1, :)', 'Linewidth', 2, 'Color', 'b')
plot(erp(2, :)', 'Linewidth', 2, 'Color', 'r')


%% axis stuff
axis([0 pnts ylim])
xticks(unique(round([zeropt:-srate / P.tkjump:0 zeropt:srate / P.tkjump:pnts])))
xtl = xticklabels;
xticklabels(num2str(round((str2double(xtl) - zeropt) * t, r) - P.tkoffset))


%% annotate and save
if ~isempty(P.lgnd)
    legend(P.lgnd, 'Location', 'northwest')
end
title(P.ttl)
xlabel(P.xlbl)
ylabel(P.ylbl)

figh = gca;

end%ctap_plot_basic_erp()