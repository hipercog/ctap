function figh = ctap_stat_hists(stab, varargin)
%CTAP_STAT_HISTS create grid of histograms of a CTAP stats table
% 
% Description:
%   takes a statistic table produced by ctapeeg_stats_table(), 
%   and print histograms of each stat in a grid


%% INIT
p = inputParser;
p.addRequired('stab', @istable)

p.addParameter('fixplots', 12, @isnumeric)
p.addParameter('rowi', stab.Properties.RowNames, @iscellstr)
p.addParameter('paperwh', [42 42], @isnumeric)
p.addParameter('figVisible', 'off', @isstr)
p.addParameter('xlim', [-Inf Inf], @isnumeric) %fixed size makes comparison easier
p.addParameter('xlab', 'Amplitude (\muV)', @ischar)

p.parse(stab, varargin{:})
Arg = p.Results;

vnmi = [stab.Properties.VariableNames '-'];
nvars = size(stab, 2);


%% FIX PAPER
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


%% Plot
nh = floor(sqrt(Arg.fixplots));
nv = ceil(Arg.fixplots/nh);

% loop
% TODO : make barcolors more visible.
for i = 1:nvars + 1
    subplot(nv, nh, i);
    bottomleftplot = nh * (nv - 1) + 1;
    switch i
        case bottomleftplot
            plot_histogram( stab{:, i},...
                    'plotTitle', false,...
                    'xlim', Arg.xlim,...
                    'xlabel', Arg.xlab,...
                    'plotPDFs', false,...
                    'BarFaceColor', [150, 100, 120]);
        case nvars
            bar( stab{:, i} );
%TODO - WHAT IS THE POINT OF PASSING NaN???!! DOESN'T WORK AT ALL!!!
        case nvars + 1
%             plot_histogram( NaN,...
%                     'plotTitle', false,...
%                     'plotLabels', false,...
%                     'plotXTickLabels', false,...
%                     'plotYTickLabels', false,...
%                     'plotBox', false,...
%                     'plotLegend', true,...
%                     'plotPDFs', false,...
%                     'BarFaceColor', [150, 100, 120]);
        otherwise
            plot_histogram( stab{:, i},...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim,...
                    'plotPDFs', false,...
                    'BarFaceColor', [150, 100, 120]);
    end

   % Add statistic name as overlaid text
    text(0.95, 0.95,...
        strrep(vnmi{i}, '_', ' '),...
        'units', 'normalized',...
        'FontName', 'FixedWidth', 'FontWeight', 'bold', 'FontSize', 12,...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
end

end