function vers = eegplugin_neurone(fig, try_strings, catch_strings)
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2012 - 
%  Mikko Venäläinen, Mega Electronics Ltd
%  (mega@megaemg.com, http://www.megaemg.com)
%  ========================================================================
%  This file is part of NeurOne Tools for Matlab.
% 
%  NeurOne Tools for Matlab is free software: you can redistribute it
%  and/or modify it under the terms of the GNU General Public License as
%  published by the Free Software Foundation, either version 3 of the
%  License, or (at your option) any later version.
%
%  NeurOne Tools for Matlab is distributed in the hope that it will be
%  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with NeurOne Tools for Matlab.
%  If not, see <http://www.gnu.org/licenses/>.
%  ========================================================================
%  See version_history.txt for details.
%  ========================================================================
vers = 'NeurOne Data Import 1.0';

%% Verify input arguments
if nargin < 3
    error('Not enough input arguments.');
end

%% Add plugin folder to the path
if  ~exist('pop_readneurone.m')
    path            = which('eegplugin_neurone.m');
    [path filename] = fileparts(path);
    path            = [path filesep];
    addpath([path version]);
end

%% Find the 'Import data' -menu
importmenu=findobj(fig,'tag','import data');

%% Construct command
cmd = [try_strings.no_check '[EEG LASTCOM]=pop_readneurone;' catch_strings.new_and_hist];

%% Create the menu for NeurOne import
uimenu(importmenu, 'label', 'From a Mega NeurOne device', 'Callback', cmd, 'separator', 'on');
