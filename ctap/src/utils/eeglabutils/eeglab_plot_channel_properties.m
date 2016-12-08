function figh = eeglab_plot_channel_properties(EEG, chans, fixplots, varargin)
% eeglab_plot_channel_properties - Plots EEG dataset channel properties (histogram)


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('chans', @isnumeric);
p.addRequired('fixplots', @isnumeric);

p.addParameter('paperwh', [42 42], @isnumeric);
p.addParameter('figVisible', 'off', @isstr);
xlimArr = [max(-150, min(min(EEG.data))),...
           min(150, max(max(EEG.data)))];
p.addParameter('xlim', xlimArr, @isnumeric);

p.parse(EEG, chans, fixplots, varargin{:});
Arg = p.Results;

if nargin < 2
    nchan = size(EEG.data,1);
    chans = 1:nchan;
else
    nchan = numel(chans);
end

if nargin < 3 || fixplots < nchan
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
    h = subplot(nv, nh, i);
    bottomleftplot = nh * (nv - 1) + 1;
    if i == bottomleftplot
        plot_histogram( EEG.data(chans(i),:,:),...
                    'plotTitle', false,...
                    'xlim', Arg.xlim,...
                    'plotLabels', true,...
                    'xlabel', 'Amplitude (\muV)');

    elseif i == nchan
        plot_histogram(  EEG.data(chans(i),:,:),...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim,...
                    'plotLegend', true);
                
    else
        plot_histogram(  EEG.data(chans(i),:,:),...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim);

    end

   % Add channel name as overlayed text
    text(0.95, 0.95,...
        EEG.chanlocs(chans(i)).labels,...
        'units', 'normalized',...
        'FontName', 'FixedWidth', 'FontWeight', 'bold', 'FontSize', 12,...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
end
