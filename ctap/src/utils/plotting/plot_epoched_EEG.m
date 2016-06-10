function figH = plot_epoched_EEG(EEG_list, varargin)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG_list', @iscell);
p.addParameter('idArr', {}, @iscellstr);
p.addParameter('channels', {EEG_list{1}.chanlocs.labels}, @iscellstr);
p.addParameter('useGridLegend', false, @islogical);
p.addParameter('visible', 'on', @ischar);
p.addParameter('equalYLimits', true, @islogical);

p.parse(EEG_list, varargin{:});
Arg = p.Results;


%% Assign variables
M = length(EEG_list);
nrow = 1;
ncol = M;


%% Plot
figH = figure('Visible',Arg.visible);

for m=1:M
    sp(m) = subplot(nrow, ncol, m); %#ok<*AGROW>
    chMatch = ismember({EEG_list{m}.chanlocs.labels}, Arg.channels);
    
    m_pdata = mean(EEG_list{m}.data(chMatch,:,:),3)';
    lineHArr = plot(EEG_list{m}.times, m_pdata);
    hold on;
    line([EEG_list{m}.times(1), EEG_list{m}.times(end)],[0, 0],...
        'Color','k',...
        'LineStyle','--');
    hold off;
    legend_strs = {EEG_list{m}.chanlocs(chMatch).labels};
    legend(sp(m), legend_strs, 'Location', 'Best');
    
    if Arg.useGridLegend
        gridLegend(lineHArr,4,'Orientation','Horizontal');
    end
    
    xlabel(sp(m), 'Time (ms)');
    ylabel(sp(m), 'Voltage (\muV)');
    
    titlestr = sprintf('[# of trials: %d]',size(EEG_list{m}.data,3));
    if ~isempty(Arg.idArr)
       titlestr = [Arg.idArr{m},' ', titlestr];
    end
    title(titlestr); 
    
    if Arg.equalYLimits && (m==1)
        axp = get(sp(m));
        YLIM = axp.YLim;
    end
    
    if Arg.equalYLimits
       ylim(YLIM); 
    end
    
    
    clear('m_*');
end