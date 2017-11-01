function plotNsave_raw(EEG, savepath, plotname, varargin)
%PLOTNSAVE_RAW - Plot and save raw EEG data
%
% Description:
%   Plots raw data, can be channels or components depending on what is passed
% 
% Syntax:
%   plotNsave_raw(EEG, savepath, varargin)
% 
% Input:
%   'EEG'       struct, EEGLAB structured data
%   'savepath'  string, path to directory for plot png to save
%   'plotname'  string, what to call output image - required to be unique
%                       to keep new outputs from overwriting older ones.
% 
% varargin:
%   'dataname'      string, what to call data rows, default = 'Channels'
%   'startSample'   integer, first sample to plot, 
%                   default = NaN
%   'secs'          integer, seconds to plot from min to max, 
%                   default = [0 16]
%   'channels'      cell string array, labels, 
%                   default = {EEG.chanlocs.labels}
%   'markChannels'  cell string array, labels of bad channels, 
%                   default = {}
%   'plotEvents'    boolean, plot event labels & vertical marker lines,
%                   default = true
%   'figVisible'    on|off, 
%                   default = off
% 
%
% See also: plot_raw, struct2varargin
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('savepath', @ischar);
p.addRequired('plotname', @ischar);

p.addParameter('dataname', 'channels', @isstr); %what is data called?
p.addParameter('chunksize', 32, @isnumeric); %a handy # channels per figure
p.addParameter('startSample', 1, @isnumeric); %start of plotting in samples
p.addParameter('secs', [0 16], @isnumeric); %how much time to plot
p.addParameter('channels', {EEG.chanlocs.labels}, @iscellstr); %channels to plot
p.addParameter('markChannels', {}, @iscellstr); %channels to plot in red
p.addParameter('plotEvents', true, @islogical); 
p.addParameter('figVisible', 'off', @ischar);
p.addParameter('paperwh', [-1 -1], @isnumeric); %paper [width, height] in cm

p.parse(EEG, savepath, plotname, varargin{:});
Arg = p.Results;
CHANNELS = Arg.channels;


%% Set up chunks
nchan = length(CHANNELS);
if Arg.chunksize > numel(Arg.channels)
%     nchunks = 1;
    chchunks = [1, nchan + 1];
else
    nchunks = Arg.chunksize;
    chchunks = horzcat(1:nchunks:nchan, nchan + 1);
end



%{
% if there will be multiple plots, we should save them to own new dir
if length(chchunks) > 2
    savepath = fullfile(savepath, saveid);
    saveid = '';
else
    saveid = [saveid '_'];
end
%}

%% Plot
% Remove fields not applicable to plot_raw (or otherwise misleading)
Arg = rmfield(Arg,{'EEG', 'savepath', 'plotname', 'chunksize', 'channels'});
plotVarargin = struct2varargin(Arg);
if ~exist(savepath, 'dir'), mkdir(savepath); end

for i = 1:(length(chchunks) - 1)
    figh = plot_raw(EEG,...
            'paperwh', Arg.paperwh,... %original [-1, -1]
            'channels', CHANNELS(chchunks(i):chchunks(i + 1) - 1),...
            plotVarargin{:});
    % savename concats the file id with the channel information
    savename = sprintf('%s-chs%d-%d.png',...
                       plotname, chchunks(i), chchunks(i + 1) - 1);
    % save and close figure
    print(figh, '-dpng', fullfile(savepath, savename)); 
    close(figh);
end
