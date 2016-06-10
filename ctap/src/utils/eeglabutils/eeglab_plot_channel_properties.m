function figh = eeglab_plot_channel_properties(EEG, chans, fixplots, varargin)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);  
p.addRequired('chans', @isnumeric);  
p.addRequired('fixplots', @isnumeric);  
p.addParameter('figVisible', 'off', @isstr);
xlimArr = [max(-100, min(min(EEG.data))),...
           min(100, max(max(EEG.data)))];
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

%ScreenSize is a four-element vector: [left, bottom, width, height]:
scrsz = get(0,'ScreenSize');
figh = figure('Position',[1 scrsz(4) scrsz(3) scrsz(4)],...
              'Visible', Arg.figVisible);

% loop
for i = 1:nchan
   h = subplot(nv, nh, i);
%    if mod(i, nv) == 0
%        leftedge = true;
%    end
   plot_histogram(  EEG.data(chans(i),:),...
                    'plotTitle', false,...
                    'plotLabels', false,...
                    'xlim', Arg.xlim);
%                     'plotYLabels', leftedge,...

   % Add channel name as overlayed text
   x_lim = get(h, 'XLim');
   xdiff = x_lim(2)-x_lim(1);
   y_lim = get(h, 'YLim');
   ydiff = y_lim(2)-y_lim(1);
   text(double(x_lim(2)-0.25*xdiff),...
        double(y_lim(2)-0.1*ydiff),...
        EEG.chanlocs(chans(i)).labels,...
        'FontName', 'FixedWidth', 'FontWeight', 'bold', 'FontSize', 12);
end
