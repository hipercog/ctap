function figh = ctaptest_plot_bad_chan(EEGprepro,chinds,varargin)
        
        p = inputParser;
        p.addRequired('EEGprepro', @isstruct);
        p.addRequired('chinds', @isnumeric);
        p.addParameter('context', '', @ischar);
        p.addParameter('savepath', '', @isfolder);
        p.parse(EEGprepro, chinds, varargin{:});
        Arg = p.Results;
        
        badness = [EEGprepro.CTAP.artifact.variance.channel_idx];
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
            , 'plotchans', setdiff(chinds, badness) ...
            , 'emarker', {'.','k',7,1} ...
            , 'chaninfo', EEGprepro.chaninfo);
        
        %% Save plots if given a savepath
        if ~isempty(Arg.savepath)
            savename = sprintf('%s-badChan-%s.png'...
                , EEGprepro.CTAP.measurement.casename, Arg.context);
            print(figh, '-dpng', fullfile(Arg.savepath, savename)); 
            close(figh);
        end
        
end


