function figH = ctap_ic_topoplot(EEG, comps, varargin)
%CTAP_IC_TOPOPLOT plots a number of Independent Components. 
% 
% Description:
%   Replaces EEGLAB's pop_topoplot() for this functionality because pop_topoplot
%   does not allow figures to be plotted invisibly, which steals the focus
%   during batch processing and disturbs the user.
%   Also plots enough figures to allow each topoplot at least 200x200 pixels
%
% Syntax:
%   figH = ctap_ic_topoplot(EEG, comps, chans, topotitle)
%
% Inputs:
%   'EEG'           struct, eeglab data struct
%   'comps'         vector, index list of components to plot
%                  
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'topoplot'     	cell array, any arguments from topoplot.m, expressed in 
%                   'name' value pairs. For example, {'plotchans', [vector]}, 
%                   index list of channels to use making the head plot
%                   default = {}
%   'topotitle' 	string, title for internal figure display, not a filename
%                   default = ''
%   'visible'       string, set figure 'Visible' property 'on' or 'off'
%                   default = 'on'
%   'figdims'       vector, sets figure 'Position' property
%                   default = get(0, 'ScreenSize') / 6 * 5
%   'savepath'      string, path to directory to save figures, if saving
%                   default = ''
%   'savepath'      string, root name of figures, if saving
%                   default = ''
%
% Outputs:
%   'figH'          integer, figure handle
%
%
% See also: topoplot
%
% Version History:
% 12.08.2015 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('comps', @isnumeric);

p.addParameter('topoplot', {}, @iscell);
p.addParameter('topotitle', '', @ischar);
p.addParameter('visible', 'on', @ischar);
p.addParameter('figdims', [], @isnumeric);
p.addParameter('savepath', '', @ischar);
p.addParameter('savename', '', @ischar);

p.parse(EEG, comps, varargin{:});
Arg = p.Results;

%% PLOT
if isempty(Arg.figdims)
    Arg.figdims = get(0, 'ScreenSize');
    Arg.figdims = ceil(Arg.figdims / 6 * 5);
end

%find number of ICs per figure that can have 200x200 pixels each
ICx200 = ceil((Arg.figdims(3) / 200) * (Arg.figdims(4) / 200));
numIC = numel(comps);

ICs = horzcat(1:ICx200:numIC, numIC + 1);

%     id = sprintf('%s_%s', EEG.CTAP.measurement.casename, Arg.method);
%     if numel(comps) > 1
%         savepath = fullfile(savepath, id);
%         if ~isdir(savepath), mkdir(savepath); end
%         id = '';
%     end

%fix output directory scheme
if ~isempty(Arg.savepath) && ~isempty(Arg.savename)
    if ICx200 < numIC %if more ICs than available display space for 1 image => 
                      %many figs => make own dir for this subject
        savepath = fullfile(Arg.savepath, Arg.savename);
        saveid = '';
    else %else just put the subject name in the fig file name
        savepath = Arg.savepath;
        saveid = sprintf('%s_', Arg.savename);
    end
    output = true;
else
    output = false;
end
if ~isdir(savepath), mkdir(savepath); end

for i = 1:length(ICs) - 1
    %subset ICs for a figure
    figICs = comps(ICs(i):ICs(i + 1) - 1);
    
    figH = figure('Visible', Arg.visible, ...
        'Position', Arg.figdims, ...
        'Name', sprintf('%s-ICs-%d-%d', Arg.topotitle, ICs(i), ICs(i + 1) - 1));
    
    %find most square subplot dimensions
    [r, c] = min_bound_rect(numel(figICs));
    
    %draw IC subplots
    for idx = 1:numel(figICs)
        subplot(r, c, idx)
        tp = topoplot( EEG.icawinv(:, figICs(idx)), EEG.chanlocs...
            , Arg.topoplot{:}...
            , 'chaninfo', EEG.chaninfo...
            , 'whitebk', 'on', 'verbose', 'off', 'conv', 'on');%#ok<NASGU>
        title(sprintf('IC%d', figICs(idx)));
    end
    
    %draw colorbar
    cbar('vert', 0, get(gca, 'clim'));
    
    %draw '+' and '-' instead of numbers for colorbar tick labels
    tmp = get(gca, 'ytick');
    set(gca, 'ytickmode', 'manual', 'yticklabelmode', 'manual',...
        'ytick', [tmp(1) tmp(end)], 'yticklabel', { '-' '+' });
    
    %set title text at bottom of figure
    a = textsc(0.5, 0.05, Arg.topotitle); 
    set(a, 'fontweight', 'bold');
    
    %save out
    if output
        pic_name = sprintf('%d_ICs-%d-%d', i, ICs(i), ICs(i + 1) - 1);
        saveas(figH, fullfile(savepath, [saveid pic_name]), 'png' )
    end
    close(figH);
end

end %ctap_ic_topoplot()
