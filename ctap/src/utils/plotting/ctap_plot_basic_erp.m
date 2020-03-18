function figh = ctap_plot_basic_erp(...
    erp, src, pnts, zeropt, srate, tkoffset, lgnd, ttl, savename)

figh = figure;

%draw curves
plot(erp', 'Linewidth', 2)
hold on
if ismatrix(src) && iscell(src)
    cols = get(gca, 'colororder');
    for idx = 1:numel(src)
        plot(src{idx}', 'Linewidth', 1, 'color', [cols(idx, :) 0.2])
    end
    plot(erp', 'LineWidth', 3)
end
set(gca, 'ColorOrderIndex', 1)
plot(erp', 'Linewidth', 2)

%fancy stuff
line([zeropt zeropt], ylim, 'Color', 'k', 'LineStyle', '--')
axis([0 pnts -Inf Inf])
xticks(linspace(0, pnts, round(pnts / zeropt) + 1))
xtl = xticklabels;
xticklabels(num2str(round(...
                    (str2double(xtl) - zeropt) * (1 / srate), 2) - tkoffset))

%annotation
legend(lgnd)
title(ttl)

%save & close
print(figh, '-dpng', savename)
close(figh)


end%ctap_plot_basic_erp()