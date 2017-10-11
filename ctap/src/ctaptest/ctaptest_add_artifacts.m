function [eeg, blinks, myo, wrecks] = ctaptest_add_artifacts(eeg...
                                                           , n_blinks...
                                                           , n_myo...
                                                           , n_wrecks...
                                                           , varargin)
%CTAPTEST_ADD_ARTIFACTS adds artifacts to the EEG struct given as input
%
% Syntax:
%   [eeg, blinks, myo, wrecks] = ctaptest_add_artifacts(eeg...
%                                                     , n_blinks...
%                                                     , n_myo...
%                                                     , n_wrecks...
%                                                     , varargin)
% 
% Args:
% 	eeg         struct, input EEG
% 	n_blinks    int, number of blinks (default 20)
% 	n_myo       int, number of myogenic/EMG bursts (default 10)
% 	n_wrecks    int, number of channels to break (default 5)
%
% Returns:
% 	eeg         struct, input EEG
% 	blinks      matrix, blinks data (zero outside of artefacts)
% 	myo         matrix, myogenic/EMG bursts data (zero outside of artefacts)
% 	wrecks      matrix, wrecked channels data (zero outside of artefacts)
% 


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('eeg', @isstruct);
p.addRequired('n_blinks', @isnumeric);
p.addRequired('n_myo', @isnumeric);
p.addRequired('n_wrecks', @isnumeric);

p.addParameter('wreckMultiplierArr', NaN, @isnumeric); % [1, n_wrecks] numeric
p.addParameter('randomAmountArtifacts', false, @islogical);

p.parse(eeg, n_blinks, n_myo, n_wrecks, varargin{:});
Arg = p.Results;

if Arg.randomAmountArtifacts
    n_wrecks = randi([1 n_wrecks]);
    n_blinks = randi([1 n_blinks]);
    n_myo = randi([1 n_myo]);
end

clean = eeg.data;
blinks = zeros(size(clean));
myo = zeros(size(clean));
wrecks = zeros(size(clean));


%% I. WRECK CHANNELS
if n_wrecks ~= 0
    
    % defaults for channel wreck multipliers
    if isnan(Arg.wreckMultiplierArr)
        for a = 1:n_wrecks
            Arg.wreckMultiplierArr(a) = 1 + rand() * 8;
            if rand() < 0.5 % randomly either amplify or dampen
                Arg.wreckMultiplierArr(a) = 1 / Arg.wreckMultiplierArr(a); 
            end
        end
    end
    
    % Sanity check channels
    if numel(Arg.wreckMultiplierArr) ~= n_wrecks
        warning('ctaptest_add_artifact:inputError',...
            'There must be a wreck multplier for each channel to wreck.');
    else
        wreckable_idx_arr = 1:eeg.nbchan;
        wreck_idx = NaN(1, n_wrecks);

        for a = 1:n_wrecks
            wreck_idx(a) = wreckable_idx_arr(randi([1 numel(wreckable_idx_arr)]));
            wreckable_idx_arr = setdiff(wreckable_idx_arr, wreck_idx(a));%pre-wrkd
            eeg = ctaptest_modify_variance( eeg, wreck_idx(a), ...
                                            Arg.wreckMultiplierArr(a) );
        end
    end
    wrecks = eeg.data - clean;
end


%% II.   BLINKS
if n_blinks ~= 0
    for a = 1:n_blinks
        eeg = ctaptest_add_blink(eeg,...
                                 randi([300,400]),...            %amplitude
                                 randi([5 round(eeg.xmax-5)]),...%start time:sec
                                 0.100 + rand()*0.2);            %duration:sec
    end
    blinks = eeg.data - clean - wrecks;
end


%% III.  EMG
if n_myo ~= 0
    for a = 1:n_myo
        w0 = 8+rand()*12;           % band start 8-20 Hz
        w1 = w0+(8+rand()*7);       % band width 8-15 Hz
        wt = 3.0;                   % transition band (roll-off) 3 Hz
        w = [w0 w1 1.0];
        
        % location of 'A4' as [x,y,z]
        center = [-0.566406236924833, -6.936475850670939e-17, 0.824126188622016];
        
        % original by jari
        %center = [rand()*2 - 1,  rand()*2 - 1, rand()*.5 + .5]; %[x,y,z]
        
        eeg = ctaptest_add_emg(eeg,...
                               150 + rand()*70,...            % amplitude
                               5 + rand()*(eeg.xmax - 10),... % start time (in s)
                               2 + rand()*3.0,...             % duration (in s)
                               center,...                     % center [x,y,z]
                               rand()*2.5,...                 % radius
                               w...                           % frequency profile
                               );
    end
    myo = eeg.data - clean - wrecks - blinks;
end
