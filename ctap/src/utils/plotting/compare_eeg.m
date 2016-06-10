function compare_eeg(EEG1, EEG2, varargin)
%COMPARE_EEG - A wrapper for compare_signals to compare two EEG datasets


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG1', @isstruct);
p.addRequired('EEG2', @isstruct);
p.addParamValue('channels', {EEG1.chanlocs.labels}, @iscellstr);

p.parse(EEG1, EEG2, varargin{:});
Arg = p.Results;


%% Create stuff
match1 = ismember({EEG1.chanlocs.labels}, Arg.channels);
M1 = sum(match1);
match2 = ismember({EEG2.chanlocs.labels}, Arg.channels);
M2 = sum(match2);

labels1 = strcat('EEG1_', {EEG1.chanlocs(match1).labels});
labels2 = strcat('EEG2_', {EEG2.chanlocs(match2).labels});
labels = horzcat(labels1, labels2);

cspec1 = repmat({'b'},1,M1);
cspec2 = repmat({'r'},1,M2);
cspec = horzcat(cspec1, cspec2);

alldata = NaN(sum([M1,M2]), size(EEG1.data,2));


%% Reorder (for easy comparison)
idx1 = 1:2:sum([M1,M2]);
idx2 = 2:2:sum([M1,M2]);

alldata(idx1,:) = EEG1.data(match1,:);
alldata(idx2,:) = EEG2.data(match2,:);

labels(idx1) = labels1;
labels(idx2) = labels2;

cspec(idx1) = cspec1;
cspec(idx2) = cspec2;


%% Plot
compare_signals(alldata, labels, EEG1.srate,...
                'colorspec', cspec);
