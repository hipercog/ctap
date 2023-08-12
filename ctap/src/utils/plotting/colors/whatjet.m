% ----------------------------------------------------------------------- %
% FUNCTION "whatjet": defines a new colormap, starting with the colors
% of the "jet" colormap, but replacing green tones with "what" ones.
% The DEFAULT color structure is the following:
%
%           DR  R       Y       W      C      B   DB
%           |---|-------|-------|------|------|---|
%           0  0.1    0.35     0.5   0.65    0.9  1
% where:
%       - DR:   Deep Red    (RGB: 0.5 0 0)
%       - R:    Red         (RGB: 1 0 0)
%       - Y:    Yellow      (RGB: 1 1 0)
%       - W:    White       (RGB: 1 1 1)
%       - C:    Cyan        (RGB: 0 1 1)
%       - B:    Blue        (RGB: 0 0 1)
%       - DB:   Deep Blue   (RGB: 0 0 0.5)
%
%   Input parameters:
%       - what: vector [1 3], defines central stop color,
%               OR
%               matrix [7 3], defines all seven stop colors,
%               DEFAULT shown above
% 
%       - rez:  scalar, Number of points, default = 
%                       (recommended: m > 64, min value: m = 7)
% 
%       - stops: vector, 7 numbers summing to 1, default shown above
%
%   Output variables:
%       - J:    Colormap in RGB values (dimensions [mx3])
% 
% Copyright(c) 2020:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS CODE INSPIRED BY THE FILEEXCHANGE SUBMISSION 'WHITEJET' BY:
%       - Author:   V�ctor Mart�nez-Cagigal                               %
%       - Date:     16/05/2018                                            %
%       - Version:  1.0                                                   %
%       - E-mail:   victor.martinez (at) gib (dot) tel (dot) uva (dot) es %
%                                                                         %
%       Biomedical Engineering Group (University of Valladolid), Spain    %
% ----------------------------------------------------------------------- %
function J = whatjet(varargin)


%% Parse Input
f = get(groot,'CurrentFigure');
if isempty(f)
  m = size(get(groot, 'DefaultFigureColormap'), 1);
else
  m = size(f.Colormap, 1);
end

p = inputParser;

p.addParameter('what', [1 1 1]...
    , @(x) ismatrix(x) & size(x, 2) == 3 & (size(x, 1) == 1 | size(x, 1) == 7))
p.addParameter('rez', m, @ismatrix)
p.addParameter('stops', [0 0.1 0.25 0.15 0.15 0.25 0.1]...
                        , @(x) isvector(x) & numel(x) == 7 & sum(x) == 1)

p.parse(varargin{:})
p = p.Results;


%% Set values
% Colors
color_palette = [1/2 0 0;   % Deep red
                 1 0 0;     % Red
                 1 1 0;     % Yellow
                 1 1 1;     % White
                 0 1 1;     % Cyan
                 0 0 1;     % Blue
                 0 0 1/2];  % Deep blue
if isvector(p.what)
    color_palette(4, :) = p.what;
else
    color_palette = p.what;
end
             
% Compute distributions along the samples
color_dist = cumsum(p.stops);
color_samples = round((m - 1) * color_dist) + 1;


%% Make the gradients
J = zeros(p.rez, 3);
J(color_samples, :) = color_palette(1:7, :);
diff_samples = diff(color_samples) - 1;
for d = 1:1:length(diff_samples)
    if diff_samples(d) ~= 0
        color1 = color_palette(d, :);
        color2 = color_palette(d+1, :);
        G = zeros(diff_samples(d), 3);
        for ix_rgb = 1:1:3
            g = linspace(color1(ix_rgb), color2(ix_rgb), diff_samples(d) + 2);
            g([1, length(g)]) = [];
            G(:, ix_rgb) = g';
        end
        J(color_samples(d) + 1:color_samples(d + 1) - 1, :) = G;
    end
end

J = flipud(J);




