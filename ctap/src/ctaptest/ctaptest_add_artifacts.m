% Adds artifacts to the EEG struct given as input
% artifact parameter ranges are hard coded for now
%
% Args:
% 	eeg: input EEG struct
% 	n_blinks <int>: number of blinks (default 20)
% 	n_emg <int>: number of EMG bursts (default 10)
% 	n_wrecks <int>: number of channels to break (default 5)
%
% Returns:
% 	eeg: EEG struct with artifacts added
function eeg = ctaptest_add_artifacts(eeg,n_blinks,n_emg,n_wrecks)

if n_blinks == 0 || isempty(n_blinks)
    n_blinks = 20;
end

if n_emg == 0 || isempty(n_emg)
    n_emg = 10;
end

if n_wrecks == 0 || isempty(n_wrecks)
    n_wrecks = 5;
end

%% I. WRECK CHANNELS
for a = 1:randi([1 n_wrecks])
    wreck_amount = randi([1 8]);
    if rand() < 0.5
        wreck_amount = 1 / wreck_amount; % randomly either amplify or dampen
    end
    eeg = ctaptest_modify_variance(eeg,...
                                   randperm(eeg.nbchan, randi([1 5])),...
                                   wreck_amount);
end

%% II.   BLINKS
for a=1:randi([1 n_blinks])
    eeg = ctaptest_add_blink(eeg,...
                             randi([300,400]),...            % amplitude
                             randi([5 round(eeg.xmax-5)]),...% start time (in s)
                             0.100 + rand()*0.2);            % duration (in s)
end

%% III.  EMG{
for a=1:randi([1 n_emg])
    w0 = 8+rand()*12;           % band start 8-20 Hz
    w1 = w0+(8+rand()*7);       % band width 8-15 Hz
    wt = 3.0;                   % transition band (roll-off) 3 Hz
    w = [w0 w1 1.0];

    eeg = ctaptest_add_EMG(eeg,...
                           10 + rand()*70,...             % amplitude
                           5 + rand()*(eeg.xmax - 10),... % start time (in s)
                           2 + rand()*3.0,...             % duration (in s)
                           [rand()*2 - 1 ...              % center X
                            rand()*2 - 1 ...              % center Y
                            rand()*.5 + .5],...           % center Z
                           rand()*2.5,...                 % radius
                           w...                           % frequency profile
                           );
end
