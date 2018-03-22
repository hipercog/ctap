%% Plot ERPs of saved .sets
function [ERPS, ERP] = ctap_manu2_oddball_erps(Cfg, varargin)

    p = inputParser;
    p.addRequired('Cfg', @isstruct)
    p.addParameter('loc_label', '', @ischar)
    p.addParameter('PLOT', true, @islogical)
    p.parse(Cfg, varargin{:});
    Arg = p.Results;
    
    setpth = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.runSets{end});
    
    fnames = dir(fullfile(setpth, '*.set'));
    fnames = {fnames.name};
    fnames = fnames(ismember(fnames, strcat(Cfg.pipe.runMeasurements, '.set')));
    if isempty(fnames)
        error('ctap_manu2_oddball_erps:no_data'...
            , 'None of the selected recordings exist at the end of the pipe')
    end
    
    %%%%%%%% define subject-wise ERP data structure: 
    %%%%%%%%  of known size for subjects,conditions
    ERPS = cell(numel(fnames), 4);
    cond = {'short' 'long'};
    codes = 100:50:250;
    for i = 1:numel(fnames)
        eeg = ctapeeg_load_data(fullfile(setpth, fnames{i}));
        loc = get_eeg_inds(eeg, {Arg.loc_label});
        eeg.event(isnan(str2double({eeg.event.type}))) = [];

        for c = 1:2
            stan = pop_epoch(eeg, cellstr(num2str(codes(3:4)' + (c-1))), [-1 1]);
            devi = pop_epoch(eeg, cellstr(num2str(codes(1:2)' + (c-1))), [-1 1]);

            ERPS{i, c * 2 - 1} = ctap_get_erp(stan, loc);
            ERPS{i, c * 2} = ctap_get_erp(devi, loc);
            if Arg.PLOT
                [~, fn, ~] = fileparts(strrep(fnames{i}, '_session_meas', ''));
                ctap_plot_basic_erp([ERPS{i, c * 2 - 1}; ERPS{i, c * 2}]...
                    , NaN...
                    , stan.pnts, eeg.srate...
                    , {[cond{c} ' standard'] [cond{c} ' deviant']}...
                    , fullfile(Cfg.env.paths.exportRoot, sprintf(...
                    'ERP%s_%s_%s-%s.png', Arg.loc_label, fn, cond{c}, 'tones')))
            end

        end
    end

    %%%%%%%% Obtain condition-wise grand average ERP and plot %%%%%%%%
    ERP = ctap_manu2_grdavg_oddball_erp(ERPS, cond, eeg.srate...
                    , Cfg.env.paths.exportRoot, 'all', Arg.loc_label, Arg.PLOT);

end
