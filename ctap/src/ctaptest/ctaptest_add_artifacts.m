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
classes = 2;


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
if any(n_blinks ~= 0)
    %A vector of 2 n_blinks represents two classes of blink: 
    %1: longer large-amp, 2: faster small-amp
    bl_amp = [300 400; 200 240]; % uV
    bl_dur_offset = [0.240 0.120]; % milliseconds
    bl_dur_len = [0.20 0.06]; % milliseconds
    
    for c = 1:classes
        for a = 1:n_blinks / classes
            eeg = ctaptest_add_blink(eeg,...
                     randi(bl_amp(c, :)),...                   %amplitude:uV
                     randi([5 round(eeg.xmax - 5)]),...        %start time:sec
                     bl_dur_offset(c) + rand() * bl_dur_len(c));%duration:sec
        end
    end
    % derive a dataset of blinks
    blinks = eeg.data - clean - wrecks;
end


%% III.  EMG
if n_myo ~= 0
    % location of 'A4' as [x,y,z]
    center = [-0.566406236924833, -6.936475850670939e-17, 0.824126188622016];
    emg_amp_base = [300 80];
    emg_amp_gain = [100 70];
    emg_dur_offset = [2 0.5];
    emg_dur_len = [3.0 0.5];
    emg_band_s0 = [8 30];
    emg_band_s1 = [12 10];
    emg_band_w0 = [8 5];
    emg_band_w1 = [7 5];

    for c = 1:classes
        for a = 1:n_myo / classes
            f0 = emg_band_s0(c) + rand() * emg_band_s1(c);       % start 8-20 Hz
            f1 = f0 + (emg_band_w0(c) + rand() * emg_band_w1(c));% width 8-15 Hz
            % center as a random variable (as originally by jari)
            %center = [rand()*2 - 1,  rand()*2 - 1, rand()*.5 + .5]; %[x,y,z]

            eeg = ctaptest_add_emg(eeg,...
                       emg_amp_base(c) + rand() * emg_amp_gain(c),... %amplitude
                       5 + rand() * (eeg.xmax - 10),...          %start time:sec
                       emg_dur_offset(c) + rand() * emg_dur_len(c),...  %dur:sec
                       center,...                                 %center[x,y,z]
                       rand() * 2.5,...                                  %radius
                       [f0 f1 1.0]);                               %freq profile
        end
    end
    % derive a dataset of EMG
    myo = eeg.data - clean - wrecks - blinks;
end
