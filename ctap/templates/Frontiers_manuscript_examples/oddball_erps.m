%% Plot ERPs of saved .sets
function [erps, ERP] = oddball_erps(Cfg, PLOT)

    if nargin < 2, PLOT = true; end
    
    setpth = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.runSets{end});
    
    fnames = strcat(Cfg.pipe.runMeasurements, '.set');
    
    %%%%%%%% define subject-wise ERP data structure: 
    %%%%%%%%  of known size for subjects,conditions
    erps = cell(numel(fnames), 4);
    cond = {'short' 'long'};
    codes = 100:50:250;
    for i = 1:numel(fnames)
        eeg = ctapeeg_load_data(fullfile(setpth, fnames{i}) );
        eeg.event(isnan(str2double({eeg.event.type}))) = [];

        for c = 1:2
            stan = pop_epoch(eeg, cellstr(num2str(codes(3:4)' + (c-1))), [-1 1]);
            devi = pop_epoch(eeg, cellstr(num2str(codes(1:2)' + (c-1))), [-1 1]);

            erps{i, c * 2 - 1} = ctap_get_erp(stan);
            erps{i, c * 2} = ctap_get_erp(devi);
            if PLOT
                ctaptest_plot_erp([erps{i, c * 2 - 1}; erps{i, c * 2}]...
                    , NaN...
                    , stan.pnts, eeg.srate...
                    , {[cond{c} ' standard'] [cond{c} ' deviant']}...
                    , fullfile(Cfg.env.paths.exportRoot, sprintf(...
                        'ERP%s-%s_%s.png', fnames{i}, cond{c}, 'tones')))
            end

        end
    end

    %%%%%%%% Obtain condition-wise grand average ERP and plot %%%%%%%%
    ERP = grdavg_oddball_erp(ERPS, cond, eeg.srate...
                            , Cfg.env.paths.exportRoot, 'all', PLOT);
%     for c = 1:2:4
%         ERP_std = mean(cell2mat(erps(:,c)), 1);
%         ERP_dev = mean(cell2mat(erps(:,c + 1)), 1);
%         ccnd = cond{ceil(c/2)};
%         if PLOT
%             ctaptest_plot_erp([ERP_std; ERP_dev]...
%                 , {cell2mat(erps(:,c)); cell2mat(erps(:,c + 1))}...
%                 , numel(ERP_std), eeg.srate...
%                 , {[ccnd ' standard'] [ccnd ' deviant']}...
%                 , fullfile(Cfg.env.paths.exportRoot...
%                     , sprintf('ERP%s-%s_%s.png', 'all', ccnd, 'tones')))
%         end
%     end

end