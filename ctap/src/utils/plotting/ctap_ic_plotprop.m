function figH = ctap_ic_plotprop(EEG, ICidx, varargin)
%CTAP_IC_PLOTPROP refactoring of EEGLAB's pop_prop, plot the properties of an 
% independent component.
% 
% 
% Description:
%   Replaces EEGLAB's pop_prop() for this functionality because pop_prop
%   does not allow figures to be plotted invisibly, which steals the focus
%   during batch processing and disturbs the user. Plots only 1 IC.
%
% Syntax:
%   figH = ctap_ic_plotprop(EEG, ICidx, ...)
%
% Inputs:
%   'EEG'           struct, eeglab data struct
%   'ICidx'         interger, index of independent component to plot
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'topoplot'     	cell array, any arguments from topoplot.m, expressed in 
%                   'name' value pairs. For example, {'plotchans', [vector]}, 
%                   index list of channels to use making the head plot
%                   default = {}
%   'erpimage'     	cell array, any erpimage.m arguments as 'name' value pairs.
%                   default = {}
%   'spectopo'      cell array, any spectopo.m arguments as 'name' value pairs.
%                   E.g. {'plotchans', [vector]}, channel inds for spectra plot
%                   default = {}
%   'title'         string, whole figure title, 
%                   default = EEG.setname ICidx ' properties'
%   'visible'       'on' | 'off', set figure visibility, 
%                   default = 'off'
%   'freqrange'     vector, [min max] frequency values to plot, 
%                   default = [0 50]
%   'stats'         table, 1 row with named columns for each metric tested on
%                   this IC. 
% TODO(feature request)(BEN): Any or all metrics may classify an IC as bad, need to define it.
%
%   'figdims'       vector, sets figure 'Position' property
%                   default = screen [width height] ./ 2
% 
%
% Outputs:
%   'figH'          integer, figure handle
%
% NOTE:
%   The function allows invisible plotting from erpimage() and spectopo()
%   because it passes 'NoShow','on' and 'plot','off' respectively.
%   Therefore do not use the varargin 'topoplot' or
%
% See also: topoplot, erpimage, spectopo
%
% Version History:
% original code by Arnaud Delorme, CNL / Salk Institute, 2001
% 12.11.2015 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@title.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  
%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('ICidx', @isnumeric);

p.addParameter('topoplot', {}, @iscell);
p.addParameter('erpimage', {}, @iscell);
p.addParameter('spectopo', {}, @iscell);
p.addParameter('title', sprintf('%s IC%d properties', EEG.setname, ICidx), @ischar);
p.addParameter('visible', 'on', @ischar);
p.addParameter('freqrange', [0 50], @isnumeric);
p.addParameter('stats', table([]), @istable);

%fig dims based on half screen size. Alt: [1 1 501 501]?
tmp = get(0, 'ScreenSize');
tmp = ceil(tmp / 2);
p.addParameter('figdims', tmp, @isnumeric);

p.parse(EEG, ICidx, varargin{:});
Arg = p.Results;


%% setting up figure
% -------------------------
figH = figure('Name', Arg.title...
    , 'Position', Arg.figdims...
    , 'Color', 'w'...
    , 'Numbertitle', 'off'...
    , 'Visible', Arg.visible);


%% plotting statistics?
% ---------------------
if ~isempty(Arg.stats)
    subplot(2, 2, 4, 'Visible', 'off')
    %a crappy text display
    for i = 1:size(EEG.CTAP.badcomps.detect.src, 1)
        mtd = EEG.CTAP.badcomps.detect.src{i,1};
        idx = EEG.CTAP.badcomps.detect.src{i,2};
        tp = EEG.CTAP.badcomps.(mtd)(idx).scores(ICidx,:);
        yoff = 0.8 - (0.4 * i-1);
        h = text(0, yoff, sprintf('Method: %s', mtd), 'Interpreter', 'none');
%         set(h, 'rotation', 90)
        text(0.2, yoff, ...
            strrep(strrep(evalc('disp(tp)'), '<strong>', ''), '</strong>', '')...
            , 'Interpreter', 'none')
    end
%MAYBEDO (BEN) - MAKE A NICER KIND OF PLOTTING, E.G. SASICA bar chart of badness indices
%...but first need to standardise metrics of badness stored to CTAP struct
%     tp = Arg.stats;
%     summary(tp)
    %get data, types and names from table
%     data = table2array(tp);
%     vars = tp.Properties.VariableNames;
%     type = tp.(vars{1});
    
    %bar plot display of stats
%     bar(data, 'Visible', Arg.visible)%, 'Position', [0 0 1 0.5])
%     vars = strrep(vars, '_', ' ');
%     set(gca, 'XTickLabel', vars)
    
    %uitable display - too ugly
%     varstr = catcellstr(tp.Properties.VariableNames, 'sep', '    ');
%     uitable(gcf, 'Data', data, 'ColumnName', vars)

    %set the subplotting value for the remaining bottom row ERP image
    stat_inset = 3;
else
    %GET METHOD NAMES
    mtd = catcellstr(EEG.CTAP.badcomps.detect.src(:,1)');
    text(0, 0, sprintf('Bad IC by method(s): %s', mtd))
    %set the subplotting value for the remaining bottom row ERP image
    stat_inset = [3 4];
end



%% plotting component topoplot
% ----------------------------
subplot(2, 2, 1, 'Visible', Arg.visible)

tp = topoplot( EEG.icawinv(:, ICidx), EEG.chanlocs...
    , Arg.topoplot{:}...
    , 'chaninfo', EEG.chaninfo...
    , 'whitebk', 'on', 'verbose', 'off', 'conv', 'on'); %#ok<*NASGU>

basename = sprintf('IC%d', ICidx);
title(basename, 'fontsize', 14); 


%% plotting spectrum
% ------------------
subplot(2, 2, 2, 'Visible', Arg.visible)

try 
    if ~isempty(Arg.spectopo)
        tmp = cell2struct(Arg.spectopo(2:2:end), Arg.spectopo(1:2:end-1), 2);
        if ismember(fieldnames(tmp), 'freqrange')
            freqs = tmp.freqrange;
        else
            freqs = [1 50];
        end
    end
    [spectra, freq_outs] = spectopo(EEG.icaact(ICidx, :), EEG.pnts, EEG.srate...
        , Arg.spectopo{:}...
        , 'mapnorm', EEG.icawinv(:, ICidx)...
        , 'plot', 'off');
	plot(freq_outs(freqs(1):freqs(2)), spectra(freqs(1):freqs(2)))
%     plot(freq_outs(freqs(1)*2:freqs(2)*2), spectra(freqs(1)*2:freqs(2)*2))
    xlabel('Frequency (Hz)')
	ylabel('Power: 10*log_{10}(\muV^{2}/Hz)')
	title('Activity power spectrum')

catch err
    text(0.1, 0.3, ['Error: no spectrum plotted' 10 err.message 10])
end


%% plotting erpimage (EI)
% -----------------------
subplot(2, 2, stat_inset, 'Visible', Arg.visible)

if EEG.trials > 1
    EEG.times = linspace(EEG.xmin, EEG.xmax, EEG.pnts);
    if EEG.trials < 6
      ei_smooth = 1;
    else
      ei_smooth = 3;
    end
    % get IC activation
    icaact = eeg_getdatact(EEG, 'component', ICidx);
    offset = nan_mean(icaact(:));
    era    = nan_mean(squeeze(icaact)') - offset;
    mn = min(era);
    mx = max(era);
    era_lim =...
        [10 ^ floor(log10(abs(mn))) * round(mn / 10 ^ floor(log10(abs(mn)))) ...
    	10 ^ floor(log10(abs(mx))) * round(mx / 10 ^ floor(log10(abs(mx))))];
    % get erpimage data
    [outdata, ~, ~, limits, ~, erp] = erpimage(...
    	icaact - offset...
        , ones(1, EEG.trials) * 10000 ...
        , EEG.times * 1000 ...
        , ''...
        , ei_smooth...
        , 1 ...
        , Arg.erpimage{:}, 'NoShow', 'on', 'erp', 'on');
    % plot component erpimage
    ploterp(outdata, erp...
        , sprintf('%s activity (global offset %3.3f)', basename, offset)...
        , limits(1:2), era_lim)
else
    EI_LINES = 200; % show 200-line erpimage
    while size(EEG.data, 2) < EI_LINES * EEG.srate
        EI_LINES = 0.9 * EI_LINES;
    end
    EI_LINES = round(EI_LINES);
    if EI_LINES > 2   % give up if data too small
        if EI_LINES < 10
            ei_smooth = 1;
        else
            ei_smooth = 3;
        end
        EI_frames = floor(size(EEG.data,2) / EI_LINES);
        EI_framestot = EI_frames * EI_LINES;
        eegtimes = linspace(0, EI_frames-1, length(EI_frames));
        %get IC activation
        icaact = eeg_getdatact(EEG, 'component', ICidx);
        offset = nan_mean(icaact(:));
        % get erpimage data
        [outdata, ~, ~, limits, ~, erp] = erpimage(...
            reshape(icaact(:, 1:EI_framestot), EI_frames, EI_LINES) - offset...
            , ones(1, EI_LINES) * 10000 ...
            , eegtimes...
            , ''...
            , ei_smooth...
            , 1 ...
            , Arg.erpimage{:}, 'NoShow', 'on', 'erp', 'on');
        % plot component
        ploterp(outdata, erp, 'Continous data', limits(1:2))
    else
        text(0.1, 0.3, ['No erpimage plotted' 10 'for small continuous data'])
    end
end

    %Internal function plots ERP trials and trace
    function ploterp(datamat, erpvect, ei_title, xlims, erpylims)
        %get the std. dev. of the data
        datstd = std(reshape(datamat, numel(datamat), 1)) * 4;
        %plot the core +/-4SD of data: time x trials
        imagesc(flipud(datamat'), [datstd*-1 datstd])
        title(ei_title)
        gcapos = get(gca, 'Position');
        set(gca, 'Position', [gcapos(1) gcapos(2) gcapos(3) 0.9 * gcapos(4)])
        set(gca, 'Xticklabel', []) %remove tick labels from bottom of image
        ylabel('Trials')
        cbar;
        %plot ERP trace below the matrix
        axes('Position',...
            [gcapos(1) gcapos(2) - (0.1 * gcapos(4)) gcapos(3) 0.2 * gcapos(4)])
        plot(erpvect)
        if nargin > 3, set(gca, 'XLim', xlims); end
        if nargin > 4, set(gca, 'YLim', erpylims); end
        xlabel('Time (ms)')
    end

end % ctap_ic_plotprop()
