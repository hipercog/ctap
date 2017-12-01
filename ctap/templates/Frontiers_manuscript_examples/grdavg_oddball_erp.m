function ERP = grdavg_oddball_erp(ERPS, cond, eeg_srate, path, name, PLOT)
    
    if nargin < 6, PLOT = true; end
    
    ERP = cell(numel(cond), 1);
    %%%%%%%% Obtain condition-wise grand average ERP and plot %%%%%%%%
    for c = 1:2:4
        ERP_std = mean(cell2mat(ERPS(:,c)), 1);
        ERP_dev = mean(cell2mat(ERPS(:,c + 1)), 1);
        ccnd = cond{ceil(c/2)};
        if PLOT
            ctaptest_plot_erp([ERP_std; ERP_dev]...
                , {cell2mat(ERPS(:,c)); cell2mat(ERPS(:,c + 1))}...
                , numel(ERP_std), eeg_srate...
                , {[ccnd ' standard'] [ccnd ' deviant']}...
                , fullfile(path...
                    , sprintf('ERP%s-%s_%s.png', name, ccnd, 'tones')))
        end
        ERP{ceil(c/2)} = [ERP_std; ERP_dev];
    end
end