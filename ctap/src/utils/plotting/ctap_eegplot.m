function ctap_eegplot(EEG, varargin)

%% Varargin
Arg.channels = {EEG.chanlocs.labels};
Arg.colorChannels = {};
Arg.colorspec = repmat({'k'},1, size(EEG.data,1));
Arg.windowLength = 60; %in sec
Arg.title = 'ctap_eegplot';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Init
if ~isempty(Arg.colorChannels)
   colChanMatch = ismember({EEG.chanlocs.labels}, Arg.colorChannels);
   Arg.colorspec(colChanMatch) = {'r'};
end

chanMatch = ismember({EEG.chanlocs.labels}, Arg.channels);

%% Set plotting options
plotoptions{1} = 'color';
plotoptions{2} = Arg.colorspec;

% Plotting options:
plotoptions_gen{1} = 'srate';
plotoptions_gen{2} = EEG.srate;
plotoptions_gen{3} = 'limits';
plotoptions_gen{4} = [EEG.xmin EEG.xmax]*1000;
plotoptions_gen{5} = 'winlength';
plotoptions_gen{6} = Arg.windowLength;
plotoptions_gen{7} = 'events';
plotoptions_gen{8} = EEG.event;
plotoptions_gen{9} = 'eloc_file';
plotoptions_gen{10} = EEG.chanlocs(chanMatch);
plotoptions_gen{11} = 'title';
plotoptions_gen{12} = Arg.title;
plotoptions_gen{13} = 'spacing';
plotoptions_gen{14} =...
 10*mean(std(EEG.data(:,1:Arg.windowLength*EEG.srate),[],2));
plotoptions_gen{15} = 'ploteventdur';
plotoptions_gen{16} = 'off';

plotoptions = horzcat(plotoptions, plotoptions_gen);
eegplot(EEG.data(chanMatch,:), plotoptions{:}); 
