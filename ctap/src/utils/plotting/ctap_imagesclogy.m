% ctap_imagesclogy()
% 
% Description:
%   make an imagesc(0) plot with log y-axis values (ala semilogy())
%
% Syntax:
%   figureHandle = ctap_imagesclogy(times, freqs, data);
%   figureHandle = ctap_imagesclogy(times, freqs, data...
%                                                   , 'clim', [min max]...
%                                                   , 'xticks', [--]...
%                                                   , 'yticks', [--]...
%                                                   , 'key', 'val', ...);
%
% Inputs:
%   times           vector, x-axis values
%   freqs           vector, y-axis values (LOG spaced)
%   data            matrix [freqs, times], values to plot
%
% Optional inputs:
%   clim            vector [min max], optional color limit
%   xticks          vector, graduation for x axis
%   yticks          vector, graduation for y axis
%   ...also any other 'key', 'val' properties for figure
%
%
% Outputs:
%   figureHandle    struct, handle to figure axis
%
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function h = ctap_imagesclogy(times, freqs, data, varargin)


    %% Parse input
    p = inputParser;
    p.KeepUnmatched = true;
    
    p.addRequired('times', @isvector)
    p.addRequired('freqs', @isvector)
    p.addRequired('data', @ismatrix)
    
    p.addParameter('clim', [NaN NaN], @(x) isvector(x) & numel(x) == 2)
    p.addParameter('xticks', [], @isvector)
    p.addParameter('yticks', [], @isvector)

    p.parse(times, freqs, data, varargin{:})
    u = p.Unmatched;
    p = p.Results;
    
    
    %% Run checks
  if size(data,1) ~= length(freqs)
      fprintf('imagesclogy(): data matrix must have %d rows!\n'...
          , length(freqs));
      return
  end
  if size(data,2) ~= length(times)
      fprintf('imagesclogy(): data matrix must have %d columns!\n'...
          , length(times));
      return
  end
  if min(freqs)<= 0
      fprintf('imagesclogy(): frequencies must be > 0!\n');
      return
  end
  
  
  %% Find y-log axis
  % problem with log images in Matlab: border are automatically added
  % to account for half of the width of a line: but they are added as
  % if the data was linear. The commands below compensate for this effect
  
  steplog = log(freqs(2)) - log(freqs(1)); % same for all points
  realbrdrs = [exp(log(freqs(1)) - steplog/2) exp(log(freqs(end)) + steplog / 2)];
  newfrqs = linspace(realbrdrs(1), realbrdrs(2), length(freqs));
  
  % regressing 3 times
  % 'border' is automatically added to the borders in imagesc
  bordr  = mean(newfrqs(2:end) - newfrqs(1:end - 1)) / 2; 
  newfrqs = linspace(realbrdrs(1) + bordr, realbrdrs(2) - bordr, length(freqs));
  bordr  = mean(newfrqs(2:end) - newfrqs(1:end - 1)) / 2; 
  newfrqs = linspace(realbrdrs(1) + bordr, realbrdrs(2) - bordr, length(freqs));
  bordr  = mean(newfrqs(2:end) - newfrqs(1:end - 1)) / 2;
  newfrqs = linspace(realbrdrs(1) + bordr, realbrdrs(2) - bordr, length(freqs));
  
  
  %% Draw color-scaled image
  if ~any(isnan(p.clim))
      h = imagesc(times, newfrqs, data, p.clim);
  else 
      h = imagesc(times, newfrqs, data);
  end
  set(gca, 'yscale', 'log')
  
  % puting ticks
  % ------------
  if ~isempty(p.xticks)
      set(gca, 'xtick', p.xticks)
  end
  if ~isempty(p.yticks)
      divs = yticks;
  else 
      divs = linspace(log(freqs(1)), log(freqs(end)), 10);
      divs = ceil(exp(divs)); % ceil is critical here, round might misalign...
      divs = unique_bc(divs); % out-of border label with within border ticks
  end
  set(gca, 'ytickmode', 'manual')
  set(gca, 'ytick', divs)
  
  % additional properties
  % ---------------------
  set(gca...
      , 'yminortick', 'off'...
      , 'xaxislocation', 'bottom'...
      , 'box', 'off'...
      , 'ticklength', [0.03 0]...
      , 'tickdir','out'...
      , 'color', 'none')
  if ~isempty(fieldnames(u))
      set(gca, u)
  end
  
