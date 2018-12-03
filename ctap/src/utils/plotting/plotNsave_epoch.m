function plotNsave_epoch(EEG, IDX, savepath, plotname, varargin)
%PLOTNSAVE_EPOCH - Plot and save raw EEG data
%
% Description:
%   Plots frames of data from EEG indexed by IDX
% 
% Syntax:
%   plotNsave_epoch(EEG, IDX, savepath, plotname, varargin)
% 
% Input:
%   EEG         struct, EEGLAB structured data
%   IDX         vector, index of epochs to plot, e.g. bad epochs
%   savepath    string, path to directory for plot png to save
%   plotname    string, basis part of output image name - epoch-wise plots
%                       are given unique suffixes to prevent overwriting
%   ctapMethod  string, method used in CTAP_detect_bad_epochs, and field in
%                       EEG.CTAP.badepochs with info on channels to mark red
% 
% varargin:
%   'dataname'      string, what to call data rows, 
%                           default = 'Channels'
%   'chunksize'     scalar, number of channels per figure,
%                           default = 32
%   'channels'      cell string array, labels, 
%                           default = {EEG.chanlocs.labels}
%   'markChannels'  cell string array, labels of bad channels, 
%                           default = {}
%   'plotEvents'    boolean, plot event labels & vertical marker lines,
%                           default = true
%   'figVisible'    string, sets figure visibility on|off, 
%                           default = off
%   'paperwh'       vector 2x1, sets figure paper [width, height] in cm
%                           default = [-1 -1] (base size on data)
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
p.addRequired('IDX', @(x) isnumeric(x) && isvector(x));
p.addRequired('savepath', @ischar);
p.addRequired('plotname', @ischar);

p.addParameter('dataname', 'channels', @isstr); %what is data called?
p.addParameter('chunksize', 32, @isnumeric); %a handy # channels per figure
p.addParameter('channels', {EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels}...
                                            , @iscellstr); %channels to plot
p.addParameter('markChannels', {}, @iscellstr); %channels to plot in red
p.addParameter('plotEvents', true, @islogical); 
p.addParameter('figVisible', 'off', @ischar);
p.addParameter('paperwh', [-1 -1], @isnumeric); %paper [width, height] in cm

p.parse(EEG, IDX, savepath, plotname, varargin{:});
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
Arg = rmfield(Arg,{'EEG', 'IDX', 'savepath', 'plotname', 'chunksize', 'channels'});
plotVarargin = struct2varargin(Arg);
if ~exist(savepath, 'dir'), mkdir(savepath); end

for ix = 1:numel(IDX)
    for i = 1:(length(chchunks) - 1)
        pleeg = EEG;
        pleeg.data = pleeg.data(:, :, IDX(ix));
        figh = plot_raw(pleeg, ...
            'channels', CHANNELS(chchunks(i):chchunks(i + 1) - 1),...
            'markChannels',...
                EEG.CTAP.badepochs.(ctapMethod).scores.Properties.RowNames(...
                EEG.CTAP.badepochs.(ctapMethod).scores{:, IDX(ix)} == 1),...
            'epoch', true,...
            'timeResolution', 'ms',...
            'paperwh', Arg.paperwh,...
                plotVarargin{:});
        % savename concats the file id with the channel information
        savename = sprintf('%s-Badepoch_%d-chs%d-%d.png',...
                           plotname, IDX(ix), chchunks(i), chchunks(i + 1) - 1);
        % save and close figure
        print(figh, '-dpng', fullfile(savepath, savename)); 
        close(figh);
    end
end
