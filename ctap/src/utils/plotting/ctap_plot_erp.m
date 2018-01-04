function figh = ctap_plot_erp(erp, src, pnts, srate, lgnd, savename)

    figh = figure;
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
    line([round(pnts/2) round(pnts/2)], ylim, 'Color', 'k', 'LineStyle', '--')
    axis([0 pnts -Inf Inf])
    xticks(linspace(0, pnts, 9))
    xtl = xticklabels;
    xticklabels(num2str(round(str2double(xtl) * (1 / srate), 2) - 1))
    legend(lgnd)

    print(figh, '-dpng', savename)
    close(figh)