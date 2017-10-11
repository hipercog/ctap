function figh = eeglab_plot_channel_properties(EEG, fixplots, varargin)
% eeglab_plot_channel_properties - Plots EEG dataset channel properties (histogram)


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('fixplots', @isnumeric);

p.addParameter('chans', get_eeg_inds(EEG, {'EEG'}), @isnumeric);
p.addParameter('paperwh', [42 42], @isnumeric);
p.addParameter('figVisible', 'off', @isstr);
p.addParameter('xlim', [-150 150], @isnumeric);%fixed size makes comparison easier

p.parse(EEG, fixplots, varargin{:});
Arg = p.Results;

nchan = numel(Arg.chans);

if nargin < 2 || fixplots < nchan
    fixplots = nchan;
end

nh = floor(sqrt(fixplots));
nv = ceil(fixplots/nh);


%% Plot
% IF paper width+height has been specified as 0,0 then use screen dims
if sum(Arg.paperwh) == 0
    %ScreenSize is a four-element vector: [left, bottom, width, height]:
    figh = figure('Position', get(0,'ScreenSize'),...
                  'Visible', Arg.figVisible);
else
    figh = figure('PaperType', '<custom>',...
                  'PaperUnits', 'centimeters',...
                  'PaperPosition', [0 0 Arg.paperwh],...
                  'Visible', Arg.figVisible);
end

% loop
for i = 1:nchan
    subplot(nv, nh, i);
    bottomleftplot = nh * (nv - 1) + 1;
    if i == bottomleftplot
        plot_histogram( EEG.data(Arg.chans(i),:,:),...
                    'plotTitle', false,...
                    'xlim', Arg.xlim,...
                    'plotLabels', true,...
                    'xlabel', 'Amplitude (\muV)');

    elseif i == nchan
        plot_histogram(  EEG.data(Arg.chans(i),:,:),...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim,...
                    'plotLegend', true);
                
    else
        plot_histogram(  EEG.data(Arg.chans(i),:,:),...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim);

    end

   % Add channel name as overlayed text
    text(0.95, 0.95,...
        EEG.chanlocs(Arg.chans(i)).labels,...
        'units', 'normalized',...
        'FontName', 'FixedWidth', 'FontWeight', 'bold', 'FontSize', 12,...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
end
