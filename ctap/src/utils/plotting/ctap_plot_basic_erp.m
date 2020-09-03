function figh = ctap_plot_basic_erp(erp, zeropt, srate, varargin)


%% parse input
P = inputParser;

P.addRequired('erp', @(x) isnumeric(x) & ismatrix(x))
P.addRequired('zeropt', @isscalar)
P.addRequired('srate', @isscalar)

P.addParameter('waves', {}, @(x) iscell(x) & ismatrix(x))
P.addParameter('areas', [], @isnumeric)
P.addParameter('vlines', [], @isvector)
P.addParameter('testps', [], @(x) isnumeric(x) & numel(x) == 2)
P.addParameter('tkoffset', 0, @isscalar)
P.addParameter('tkjump', 100, @isscalar)
P.addParameter('lgnd', '', @(x) iscellstr(x) | ischar(x)) %#ok<ISCLSTR>
P.addParameter('lgndloc', 'northwest', @ischar)
P.addParameter('ttl', '', @ischar)
P.addParameter('xlbl', 'Time (sec)', @ischar)
P.addParameter('ylbl', 'amplitude (\muV)', @ischar)
P.addParameter('ylimits', [NaN NaN], @(x) isnumeric(x) & numel(x) == 2)
P.addParameter('timeunit', 'sec', @ischar)
P.addParameter('overploterp', [], @(x) isnumeric(x) & ismatrix(x))

P.parse(erp, zeropt, srate, varargin{:})
P = P.Results;

pnts = size(erp, 2);


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
if ~any(isnan(P.ylimits))
    ylim(P.ylimits)
end
hold on

cols = get(gca, 'colororder');
if ~isempty(P.waves)
    for idx = 1:numel(P.waves)
        plot(P.waves{idx}', 'Linewidth', 1, 'color', [cols(idx, :) 0.35])
    end
    plot(erp', 'LineWidth', 3)
elseif ~isempty(P.areas)
    x = 1:pnts;
    for idx = 1:size(P.areas, 1)
        y1 = P.areas(idx, :, 1);
        y2 = P.areas(idx, :, 2);
        patch([x fliplr(x)], [y1 fliplr(y2)], cols(idx, :)...
            , 'FaceAlpha', 0.25 ...
            , 'LineStyle', 'none'...
            , 'EdgeColor', 'none'...
            , 'HandleVisibility', 'off')
    end
    plot(erp', 'LineWidth', 3)
end
set(gca, 'ColorOrderIndex', 1)


%% test window areas
ylmt = get(gca, 'ylim');
if ~isempty(P.vlines)
    x = ones(numel(P.vlines) / 2, 2);
    for v = 1:2:numel(P.vlines)
        x(ceil(v / 2), :) = (P.vlines(v:v+1) / t) + zeropt;
        ar = area(x(ceil(v / 2), :), [ylmt(2) ylmt(2)], ylmt(1)...
                                                        , 'LineStyle', 'none');
        ar.FaceAlpha = 0.4;
        ar.FaceColor = [0.8 0.8 0.8];
    end
end

%% overplotting
line([zeropt zeropt], ylmt, 'Color', 'k', 'LineStyle', '--')
p(1) = plot(erp(1, :)', 'Linewidth', 2, 'Color', 'b');
p(2) = plot(erp(2, :)', 'Linewidth', 2, 'Color', 'r');

if ~isempty(P.overploterp)
    p(3) = plot(P.overploterp(1, :)'...
                            , 'Linewidth', 2, 'LineStyle', ':', 'Color', 'c');
    p(4) = plot(P.overploterp(2, :)'...
                            , 'Linewidth', 2, 'LineStyle', ':', 'Color', 'y');
end


%% axis stuff
axis([0 pnts ylmt])
xticks(unique(round([zeropt:-srate / P.tkjump:0 zeropt:srate / P.tkjump:pnts])))
xtl = xticklabels;
xticklabels(num2str(round((str2double(xtl) - zeropt) * t, r) - P.tkoffset))


%% annotate and save
if ~isempty(P.lgnd)
    legend(p(1:(2 + size(P.overploterp, 1))), P.lgnd, 'Location', P.lgndloc)
end
title(P.ttl)
xlabel(P.xlbl)
ylabel(P.ylbl)

if ~isempty(P.testps)
    asterii = {'.' '*' '**' '***' '****'};
    alphas = [0.1 0.05 0.01 0.001 0.0001];
    ytxt = ylmt(1) + (ylmt(2) - ylmt(1)) / 30;
    
    for p = 1:numel(P.testps)
        ix = find(P.testps(p) < alphas, 1, 'last');
        text(x(p, 1), ytxt, asterii{ix})
    end
    
end

figh = gca;

end%ctap_plot_basic_erp()