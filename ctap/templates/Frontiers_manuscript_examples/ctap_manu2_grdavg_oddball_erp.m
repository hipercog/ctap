function ERP = ctap_manu2_grdavg_oddball_erp(...
                                ERPS, cond, eeg_srate, path, name, loclab, PLOT)
    
    if ~exist('PLOT', 'var'), PLOT = true; end
    
    ERP = cell(numel(cond), 1);
    %%%%%%%% Obtain condition-wise grand average ERP and plot %%%%%%%%
    for c = 1:2:4
        ERP_std = mean(cell2mat(ERPS(:, c)), 1);
        ERP_dev = mean(cell2mat(ERPS(:, c + 1)), 1);
        ccnd = cond{ceil(c / 2)};
        if PLOT
%           erp, src, pnts, zeropt, srate, tkoffset, lgnd, ttl, savename
            ttl = sprintf('ERP%s_%s_%s-tones', loclab, name, ccnd);
            ctap_plot_basic_erp([ERP_std; ERP_dev]...
                , round(numel(ERP_std) / 2), eeg_srate...
                , 'waves', {cell2mat(ERPS(:,c)); cell2mat(ERPS(:,c + 1))}...
                , 'lgnd', {[ccnd ' standard'] [ccnd ' deviant']}...
                , 'ttl', ttl...
                , 'savename', fullfile(path, [ttl '.png']))
        end
        ERP{ceil(c/2)} = [ERP_std; ERP_dev];
    end
end