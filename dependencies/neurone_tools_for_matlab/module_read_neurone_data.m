function data = module_read_neurone_data(binDataFiles, channelCount, samplingRate, varargin)
%MODULE_READ_NEURONE_DATA   Read NeurOne binary data
%
%  Read binary NeurOne data and display a progress bar.
%
%  This is a helper function intended for use together with
%  module_read_neurone. 
%
%  Inputs
%         bindataFiles : cell array of string with full paths to files to
%                        be read
%         channelCount    : integer defining how many channels are present in
%                        the measurement.
%         samplingRate : the sampling rate of the measurement in Hz.
%
%  Optional input arguments:
%         channels     : Numeric array with channel indices to be read.
%         channelnames : Cell string with names of channels being read.
%
%  Output : Matrix with all the data from the recordings, with data from
%           each channel in the columns of the matrix.
%
%  Dependencies : textprogressbar
%
%  Module_read_neurone_data is part of NeurOne Tools for Matlab.
%
%  The NeurOne Tools for Matlab consists of the functions:
%       module_read_neurone.m, module_read_neurone_data.m,
%       module_read_neurone_events.m, module_read_neurone_xml.m
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2009 - 2013
%  Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  and
%  Mega Electronics Ltd (mega@megaemg.com, http://www.megaemg.com)
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
%  Version x.y.z.k (08.03.2013)
%  See version_history.txt for details.
%  ========================================================================

%% Parse input arguments and replace default values if given as input
p = inputParser;
p.addRequired('binDataFiles', @iscellstr);
p.addRequired('channelCount', @isnumeric);
p.addRequired('samplingRate', @isnumeric);
p.addParamValue('channels', [], @isnumeric);
p.addParamValue('channelnames', [], @iscellstr);

p.parse(binDataFiles, channelCount, samplingRate, varargin{:});
Arg = p.Results;


% =======================================================================
% Determine how many channels that should be read
% =======================================================================
if isempty(Arg.channels)
    channelCountToRead = Arg.channelCount;
    readAllChannels = 1;
else
    channelCountToRead = numel(Arg.channels);
    readAllChannels = 0;
end

% =======================================================================
% Store all file sizes
% =======================================================================
% Number of data files to be read
nDataFiles  = numel(binDataFiles);

% Get all file sizes
fSize = zeros(nDataFiles, 1);

for k = 1:nDataFiles
    tmp  = dir(binDataFiles{k});
    fSize(k) = tmp.bytes;
end

fSizes = cumsum(fSize);

% Total size of the data
totalSize = sum(fSize);

% Total number of data points (per channel)
dataPntsTotal = (totalSize / 4) / Arg.channelCount;

% Number of data points in each binary file (per channel)
dataPnts = (fSize ./ 4) ./ Arg.channelCount;

% =======================================================================
% Read data from files
% -----------------------------------------------------------------------
% Alternative 1 : Read all channels at once (faster method)
% -----------------------------------------------------------------------
if (readAllChannels)
    % Vector to hold the data
    data = zeros(channelCountToRead * dataPntsTotal, 1);

    % Keep track of the sample indices in each file
    sample_index = cumsum([0 ; dataPnts*channelCountToRead]);
    
    fprintf('Reading NeurOne data [all channels]...');

    for n = 1:nDataFiles
        fid = fopen([binDataFiles{n}], 'rb');
        data((1 + sample_index(n)):sample_index(n+1), 1) = fread(fid, fSize(n)/4, 'int32');
        fclose(fid);
    end
    
    data = reshape(data, channelCount, dataPntsTotal);
    fprintf('Done.\n');

end

% -----------------------------------------------------------------------
% Alternative 2: Read only specific channels
% -----------------------------------------------------------------------
if (~ readAllChannels)
    % Matrix to hold the data
    data = zeros(channelCountToRead, dataPntsTotal);

    % Keep track of the sample indices in each file
    sample_index = cumsum([0 ; dataPnts]);
    
    % Initialise progress bar
    textprogressbar('Reading NeurOne data [selected channels]: ');
    
    % Read selected channels, one by one from each file
    for k = 1:channelCountToRead
        for n = 1:nDataFiles
            fid = fopen([binDataFiles{n}], 'rb');
            fseek(fid, 4 * (Arg.channels(k) - 1), 'bof');
            data(k, (1+sample_index(n)):sample_index(n+1)) = fread(fid, dataPnts(n), 'int32', 4 * (channelCount-1))';
            fclose(fid);
        end
        
        % Show progress bar
        ii = floor(k / numel(Arg.channels) * 100);
        textprogressbar(ii);
    end
    
    textprogressbar('   Done.')
    
    % Show info on which channels that were read, if the names of the channels
    % were provided.
    if ~(isempty(Arg.channelnames))
        channel_list_str = sprintf('%s, ', Arg.channelnames{:});
        channel_list_str = [channel_list_str(1:end-2)];
        
        fprintf('Read channels: ');
        fprintf([channel_list_str '\n\n']);
    end
    
end

% =======================================================================
% Convert data to microvolts from nanovolts
% =======================================================================

data = data ./ 1000;
data = data';

% =======================================================================
end % end of module_read_neurone.data.m
