% pop_compeeg() - Basic plotting of multiple continuous data files for
%                 comparison
%
% Usage:
%   >> pop_compeeg(ALLEEG, 'parameter1', value1, 'parameter2', value2, ...
%                  'parametern', valuen);
%
% Inputs:
%   ALLEEG    - vector of EEGLAB EEG structures to plot
%
% Optional inputs:
%   'dc'      - string dc correction 'mean', 'start', or 'off' {default
%                   'mean'}
%   'xscale'  - abscissa scaling in s {default 5}
%   'yscale'  - ordinate scaling in uV {default 100}
%   'avg'     - flag average epoched data file {default false}
%
% Author: Andreas Widmann, University of Leipzig, 2011

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2011 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function pop_compeeg(EEG, varargin)

Arg = struct(varargin{:});

% Defaults
if ~isfield(Arg, 'dc') || isempty(Arg.dc)
    Arg.dc = 'mean';
end
if ~isfield(Arg, 'yscale') || isempty(Arg.yscale)
    Arg.yscale = 100;
end
if ~isfield(Arg, 'avg') || isempty(Arg.avg)
    Arg.avg = 0;
end
if ~isfield(Arg, 'xscale') || isempty(Arg.xscale)
    if size(EEG(1).data, 3) > 1 % Epoched
        if Arg.avg
            Arg.xscale = size(EEG(1).data, 2) / EEG(1).srate; % 1 epochs
        else
            Arg.xscale = size(EEG(1).data, 2) / EEG(1).srate * 5; % 5 epochs
        end
    else
        Arg.xscale = 5; % 5 seconds
    end
end

Arg.colArray = {'Color', [0 0 0], 'LineStyle', '-'; 'Color', [0.5 0 0]...
    , 'LineStyle', '-'; 'Color', [0 0.5 0], 'LineStyle', '-'};

% Basics
Arg.srate = EEG(1).srate;
Arg.xscalePnts = Arg.srate * Arg.xscale;
Arg.chanLabels = {EEG(1).chanlocs.labels};
Arg.event = EEG(1).event;

% Cat datasets
Arg.data = [];
for iSet = 1:length(EEG)
    if Arg.avg
        Arg.data = cat(3, Arg.data, mean(EEG(iSet).data, 3));
    else
        Arg.data = cat(...
            3, Arg.data, reshape(EEG(iSet).data, size(EEG(iSet).data, 1), []));
    end
end
[Arg.nChans, Arg.nPnts, Arg.nSets] = size(Arg.data);

% Y axis offset
Arg.yOffsetArray = (1:Arg.nChans)' * Arg.yscale - Arg.yscale / 2;

f = figure;

% Axis
Arg.axisH = axes;
Arg.axisPos = get(Arg.axisH, 'Position');
Arg.axisPos =...
    [Arg.axisPos(1) Arg.axisPos(2) + 0.05 Arg.axisPos(3) Arg.axisPos(4) - 0.05];
set(Arg.axisH, 'Position', Arg.axisPos, 'YDir', 'reverse', 'NextPlot', 'add')

% X axis slider
Arg.xSliderMax = floor(Arg.nPnts / Arg.xscalePnts) * Arg.xscalePnts + 1;
Arg.xSliderStep = min(0.2, (Arg.xscalePnts / 5) / (Arg.xSliderMax - 1));
Arg.xSliderStep = [Arg.xSliderStep 5 * Arg.xSliderStep];
Arg.xSliderPos = [Arg.axisPos(1) Arg.axisPos(2) - 0.1 Arg.axisPos(3) 0.05];
Arg.xSliderH = uicontrol('Style', 'slider', 'Units', 'normalized'...
    , 'Position', Arg.xSliderPos, 'Callback', @cbslider, 'Min', 1,...
    'Max', Arg.xSliderMax, 'Value', 1, 'SliderStep', Arg.xSliderStep);

set(f, 'UserData', Arg)

updateplot(Arg, 1)

end

function cbslider(src, ~)

    f = get(src, 'Parent');
    Arg = get(f, 'UserData');

    xMin = floor((get(src, 'Value') - 1) / (Arg.xscalePnts / 5)) *...
        (Arg.xscalePnts / 5) + 1;
    set(src, 'Value', xMin);
    
    updateplot(Arg, xMin)
    
end

function updateplot(Arg, xMin)

    xPntArray = xMin:min(xMin + Arg.xscalePnts - 1, Arg.nPnts);

    evtArray = find([Arg.event.latency] >= xMin &...
        [Arg.event.latency] < xMin + Arg.xscalePnts);

    for iSet = Arg.nSets:-1:1

        data = Arg.data(:, xPntArray, iSet);

        % Correct DC offset
        if strcmp(Arg.dc, 'start'), dcArray = data(:, 1);
        elseif strcmp(Arg.dc, 'mean'), dcArray = mean(data, 2);
        else dcArray = zeros(Arg.nChans, 1);
        end
        data = data + repmat(Arg.yOffsetArray - dcArray, [1 size(data, 2)]);

        % Plot data
        plot(Arg.axisH, (xPntArray - 1)/Arg.srate, data, Arg.colArray{iSet, :});
        set(Arg.axisH, 'NextPlot', 'Add')
        
        % Plot events
        for iEvt = 1:length(evtArray)
            plot(([Arg.event(evtArray([iEvt iEvt])).latency] - 1) / Arg.srate...
                , [0 Arg.yscale * Arg.nChans], 'r')
            text((Arg.event(evtArray(iEvt)).latency - 1) / Arg.srate, 0,...
                num2str(Arg.event(evtArray(iEvt)).type),...
                'VerticalAlignment', 'Bottom')
        end

    end
    
    set(Arg.axisH, 'YTick', Arg.yOffsetArray, 'YTickLabel', Arg.chanLabels...
        , 'YLim', [0 Arg.yscale * Arg.nChans]...
        , 'XLim', ([xMin xMin + Arg.xscalePnts - 1] - 1) / Arg.srate...
        , 'NextPlot', 'ReplaceChildren')

end
