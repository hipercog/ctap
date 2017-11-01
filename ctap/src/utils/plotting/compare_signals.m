function compare_signals(data, labels, fs, varargin)
%COMPARE_SIGNALS - A wrapper to use eegplot.m as a multi-purpose plotter
%
% Inputs:
%   data    [M,N] numeric, EEG data, channels in rows  
%           M = number of channels, N = data length = time
%   labels  [M,1] cellstr, Labels for the channels
%   fs      [1,1] numeric, Sampling rate

% data = channels x time
if  ~exist('labels','var')
    labels = strcat('sig',cellstr(num2str([1:size(data,1)]'))');
else
    if isempty(labels)
        labels = strcat('sig',cellstr(num2str([1:size(data,1)]'))');
    end
end

if ~exist('fs','var')
    fs = 1;
end

%% Varargin
Arg.eventStruct = [];
Arg.colorspec = repmat({'k'},1,numel(labels));
Arg.plot_winlength = 30; %in sec
Arg.title = 'compare_signals output';
Arg.equalizeVariances = false;

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end



%% Equalize variances
if Arg.equalizeVariances
    sprintf('Equalizing variances...\n');
    for i=2:size(data,1)
       i_a = variance_factor(data(i,:), data(1,:));
       data(i,:) = i_a*data(i,:); 
       clear('i_*');
    end
end

%% Create EEGLAB dataset
EEG = create_eeg(data, 'channel_labels', labels,...
    'fs', fs, 'eventStruct', Arg.eventStruct);


%% Set plotting options
plotoptions{1} = 'color';
plotoptions{2} = flipdim(Arg.colorspec,2); %flipdim needed because of eegplot

% Plotting options:
plotoptions_gen{1} = 'srate';
plotoptions_gen{2} = EEG.srate;
plotoptions_gen{3} = 'limits';
plotoptions_gen{4} = [EEG.xmin EEG.xmax]*1000;
plotoptions_gen{5} = 'winlength';
plotoptions_gen{6} = Arg.plot_winlength;
plotoptions_gen{7} = 'events';
plotoptions_gen{8} = EEG.event;
plotoptions_gen{9} = 'eloc_file';
plotoptions_gen{10} = EEG.chanlocs;
plotoptions_gen{11} = 'title';
plotoptions_gen{12} = Arg.title;
plotoptions_gen{13} = 'spacing';
plotoptions_gen{14} = 10*mean(std(EEG.data(:,1:Arg.plot_winlength*fs),[],2));

plotoptions = horzcat(plotoptions, plotoptions_gen);
eegplot(EEG.data, plotoptions{:});  