function figh = ctaptest_plot_bad_chan(EEGprepro,chinds,varargin)
        
        p = inputParser;
        p.addRequired('EEGprepro', @isstruct);
        p.addRequired('chinds', @isnumeric);
        p.addParameter('context', '', @ischar);
        p.addParameter('savepath', '', @isfolder);
        p.parse(EEGprepro, chinds, varargin{:});
        Arg = p.Results;
        
        %badness = [EEGprepro.CTAP.artifact.variance.channel_idx];
        chind = get_eeg_inds(EEGprepro, 'EEG');

        if isempty(Arg.savepath)
            figvis = 'on';
        else
            figvis = 'off';
        end
        
        figh = figure('Position', get(0,'ScreenSize'), 'Visible', figvis);
        
        topoplot([], EEGprepro.chanlocs...
            , 'style', 'blank'...
            , 'electrodes', 'on'...
            , 'headrad', 0 ...
            , 'plotrad', 1 ...
            , 'plotchans',  setdiff(chind, chinds) ...
            , 'emarker', {'.','k',7,1} ...
            , 'chaninfo', EEGprepro.chaninfo);
        
        if ~isempty(chinds)
            hold on
            topoplot([], EEGprepro.chanlocs...
                , 'style', 'blank'...
                , 'plotrad', 1 ...
                , 'electrodes', 'labelpoint'...
                , 'plotchans', chinds...
                , 'emarker', {'x','r',8,3} ...
                , 'chaninfo', EEGprepro.chaninfo);
        end
        
        %% Save plots if given a savepath
        if ~isempty(Arg.savepath)
            savename = sprintf('%s-badChan-%s.png'...
                , EEGprepro.CTAP.measurement.casename, Arg.context);
            print(figh, '-dpng', fullfile(Arg.savepath, savename)); 
            close(figh);
        end
        
end
