function [EEG, command] = pop_readneurone(dataPath, varargin)
%POP_READNEURONE Read data from a Mega NeurOne device using a GUI
%
% This function is intended to be used as a plugin for
% EEGLab (http://sccn.ucsd.edu/eeglab/).
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2012 - 
%  Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  and
%  Mikko Venäläinen, Mega Electronics Ltd
%  (mega@megaemg.com, http://www.megaemg.com)
%  ========================================================================
%  This file is part of NeurOne EEGLab Plugin.
% 
%  NeurOne EEGLab Plugin is free software: you can redistribute it
%  and/or modify it under the terms of the GNU General Public License as
%  published by the Free Software Foundation, either version 3 of the
%  License, or (at your option) any later version.
%
%  NeurOne EEGLab Plugin is distributed in the hope that it will be
%  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with NeurOne EEGLab Plugin.
%  If not, see <http://www.gnu.org/licenses/>.
%  ========================================================================
%  See version_history.txt for details.
%  ========================================================================


%% Initialize empty structure for the data
command = '';
EEG     = [];

%% ====================================================================
% Check the number of input arguments
% =====================================================================
% get the current Matlab Version
vertmp = ver('matlab');
if str2num(vertmp.Version) >= 7.13;
    % narginchk replaces nargchk in MATLAB 7.13 (R2011b)
    narginchk(0, nargin);
else
    nargchk(0, 3, nargin);
end

%% ====================================================================
% Use GUI
% =====================================================================
if nargin == 0
    if isfield(evalin('base', 'EEG'), 'history')
        history = evalin('base', 'EEG.history');
        if  ~(isempty(strfind(history,'dataPath')))
            dataPathIndex = strfind(history,'dataPath=''');
            idx = strfind(history,'''');
            idx = idx(idx>dataPathIndex);
            dataPath = history(idx(1)+1:idx(2)-1);
            dataPath = fileparts(dataPath);
            [dataPath folder] = fileparts(dataPath);
        else
            dataPath = cd;
        end
    else
        dataPath = cd;
    end
    
    dataPath = uigetdir(dataPath, 'Load NeurOne Data File');
    
    % Verify that one or more files were selected
    if dataPath == 0
        return
    end
    
    % Allow the user to set some parameters using a GUI
    settings = gui_load_neurone('dataPath', dataPath);
    
    % Check if the user wishes to stop at this time
    % or if no channel was selected, then quit.
    if ((settings.cancel) | isempty(settings.channel_list))
        return
    end
    
    
    %% ====================================================================
    %  Do not use a GUI
    % =====================================================================
else
    % Parse input arguments
    p = inputParser;
    p.addRequired('dataPath', @ischar);
    p.addParamValue('channels', {}, @iscellstr);
    
    p.parse(dataPath, varargin{:});
    Arg = p.Results;
    
    % Make sure that dataPath ends with filesep
    if ~strcmpi(dataPath(end), filesep)
        dataPath = [dataPath filesep];
    end
    
    if isfield(Arg, 'channels')
        if isempty(Arg.channels)
            settings.read_all_channels = 1;
        else
            settings.read_all_channels = 0;
            settings.channel_list = Arg.channels;
        end
        
    end
    
end % do not use a GUI

% =========================================================================
% Read the NeurOne data
% =========================================================================
if(settings.read_all_channels)
    
    recording = module_read_neurone(dataPath);
    
    comline = sprintf('''%s''', dataPath);
    command = sprintf('[EEG, COM] = pop_readneurone(%s);', comline);
    
else
    % convert cell string array to plain string
    channel_list_str = sprintf('''%s'', ', settings.channel_list{:});
    channel_list_str = ['{' channel_list_str(1:end-2) '}'];

    recording = module_read_neurone(dataPath, 'channels', settings.channel_list);

    comline = sprintf('''%s''', dataPath);
    comline = sprintf('%s, ''channels'', %s', comline, channel_list_str);
    command = sprintf('[EEG, COM] = pop_readneurone(%s);', comline);
end

% =========================================================================
% Convert recording structure to EEGLab data format
% =========================================================================

EEG = recording_neurone_to_eeglab(recording);

% =========================================================================

return

end % pop_readneurone.m
