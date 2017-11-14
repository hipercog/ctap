function figh = ctaptest_plot_erp(erp, pnts, srate, lgnd, savename)

    figh = figure;
    plot(erp', 'Linewidth', 2);
    line([round(pnts/2) round(pnts/2)], ylim, 'Color','black','LineStyle','--')
    axis([0 pnts -Inf Inf])
    xticks(linspace(0, pnts, 9))
    xtl = xticklabels;
    xticklabels(num2str(round(str2double(xtl) * (1 / srate), 2) - 1))
    legend(lgnd)

    print(figh, '-dpng', savename)
    close(figh)