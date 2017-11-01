function figh = ctaptest_plot_bad_chan(EEG, varargin)
% CTAPTEST_PLOT_BAD_CHAN plots a head map of channel locations from EEG
% (points only), with bad channels marked in red Xs and labelled.
%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addParameter('sweep_i', 0, @isnumeric);
p.addParameter('savepath', '', @isdir);
p.addParameter('badness', [EEG.CTAP.artifact.variance.channel_idx], @isnumeric);
p.parse(EEG, varargin{:});
Arg = p.Results;

% define indices of EEG channels as numeric
chinds = get_eeg_inds(EEG, {'EEG'});


%% Make plots
if isempty(Arg.savepath)
    figvis = 'on';
else
    figvis = 'off';
end
%ScreenSize is a four-element vector: [left, bottom, width, height]:
figh = figure('Position', get(0,'ScreenSize'), 'Visible', figvis);

topoplot([], EEG.chanlocs...
    , 'style', 'blank'...
    , 'electrodes', 'on'...
    , 'headrad', 0 ...
    , 'plotrad', 1 ...
    , 'plotchans', setdiff(chinds, Arg.badness) ...
    , 'emarker', {'.','k',7,1} ...
    , 'chaninfo', EEG.chaninfo);
%     , 'emarker2', {Arg.badness, 'x','r',8,3} ...

hold on
topoplot([], EEG.chanlocs...
    , 'style', 'blank'...
    , 'plotrad', 1 ...
    , 'electrodes', 'labelpoint'...
    , 'plotchans', Arg.badness...
    , 'emarker', {'x','r',8,3} ...
    , 'chaninfo', EEG.chaninfo);


%% Save plots if given a savepath
if ~isempty(Arg.savepath)
    savename = sprintf('%s-badChan-sweep-%d.png'...
        , EEG.CTAP.measurement.casename, Arg.sweep_i);
    print(figh, '-dpng', fullfile(Arg.savepath, savename)); 
    close(figh);
end

end