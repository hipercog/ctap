function [plv, plvCI] = eegPLV(eegData, srate, filtSpec, varargin)
% Computes the Phase Locking Value (PLV) for an EEG dataset.
%
% Input parameters:
%   eegData 	3D matrix [numChannels numTimePoints numTrials]
%   srate       scalar, sampling rate of the EEG data
%   filtSpec	struct, filter specification to filter the EEG signal in the
%               desired frequency band of interest. It is a structure with two
%               fields, order and range. 
%                - Range specifies the limits of the frequency band, e.g. 
%                   filtSpec.range = [35 45] for gamma band.
%                - Order defines the FIR filter order. A useful rule of thumb 
%                   can be to include about 4 to 5 cycles of the desired
%                   signal. For example, filtSpec.order = 50 for eeg data 
%                   sampled at 500 Hz corresponds to 100 ms and contains ~4 
%                   cycles of gamma band (40 Hz)
% 
% Varargin
%   condIdx 	logical 2D matrix [numTrials numConditions]
%               E.g. with 250 trials in eegData, where first 125 => 'attend'
%               condition and last 125 => 'ignore' condition, then use:
%                   condIdx = [[true(125, 1); false(125, 1)]...
%                            , [false(125, 1); true(125, 1)]];
%
% 
% Output parameters:
%   plv 	3/4-D matrix [numTimePoints numChannels numChannels numConditions]
%           If 'condIdx' is not specified, then we assume that there is
%           only one condition and all trials belong to that condition:
%           then plv is a 3D matrix
%   plvCI   4/5-D matrix [numTimePoints numChannels numChannels numConditions lo-hi-CI]
%           As plv, but last dimension are lower (1) and upper (2) bounds of CI
% 
%--------------------------------------------------------------------------
% Example: Consider a 28 channel EEG data sampled @ 500 Hz with 231 trials,
% where each trial lasts for 2 seconds. You are required to plot the phase
% locking value in the gamma band between channels Fz (17) and Oz (20) for
% two conditions (say, attend and ignore). Below is an example of how to
% use this function.
%
%   eegData = rand(28, 1000, 231); 
%   srate = 500; %Hz
%   filtSpec.order = 50;
%   filtSpec.range = [35 45]; %Hz
%   condIdx = rand(231, 1) >= 0.5; % attend trials
%   condIdx(:, 2) = ~condIdx(:, 1); % ignore trials
%   [plv] = eegPLV(eegData, srate, filtSpec, 'condIdx', myDSA);
%   figure; plot((0:size(eegData, 2)-1)/srate, squeeze(plv(:, 17, 20, :)));
%   xlabel('Time (s)'); ylabel('Plase Locking Value');
%
% NOTE:
% As you have probably noticed in the plot from the above example, the PLV 
% between two random signals is spuriously large in the first 100 ms. While 
% using FIR filtering and/or hilbert transform, it is good practice to 
% discard both ends of the signal (same number of samples as the order of 
% the FIR filter, or more).
% 
% Also note that in order to extract the PLV between channels 17 and 20, 
% use plv(:, 17, 20, :) and NOT plv(:, 20, 17, :). The smaller channel 
% number is to be used first.
%--------------------------------------------------------------------------
% 
% Reference:
%   Lachaux, J P, E Rodriguez, J Martinerie, and F J Varela. 
%   Measuring phase synchrony in brain signals.
%   Human brain mapping 8, no. 4 (January 1999): 194-208. 
%   http://www.ncbi.nlm.nih.gov/pubmed/10619414.
% 
%--------------------------------------------------------------------------
% Written by: 
% Praneeth Namburi
% Cognitive Neuroscience Lab, DUKE-NUS
% 01 Dec 2009
% 
% Present address: Neuroscience Graduate Program, MIT
% email:           praneeth@mit.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edited by: Benjamin Cowley, University of Helsinki, 2020
%            ben.cowley@helsinki.fi
% Added input parser and funcationality to compute bootstrapped CIs
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Init
numChans = size(eegData, 1);
numTrials = size(eegData, 3);

P = inputParser;

P.addRequired('eegData', @isnumeric)
P.addRequired('srate', @(x) isnumeric(x) & isscalar(x))
P.addRequired('filtSpec', @isstruct)

P.addParameter('condIdx', true(numTrials, 1)...
                        , @(x) islogical(x) | all(ismember(x, [0 1]), 'all'))
P.addParameter('verbose', true, @islogical)
P.addParameter('nbootci', 0, @isscalar)
P.addParameter('bootalpha', 0.05, @isscalar)

P.parse(eegData, srate, filtSpec, varargin{:})
P = P.Results;

numConditions = size(P.condIdx, 2);


%% Filtering
if P.verbose
    fprintf('FIR filtering data in %d-%dHz, order:%d\n'...
        , filtSpec.range(1), filtSpec.range(2), filtSpec.order)
end
filtPts = fir1(filtSpec.order, 2/srate*filtSpec.range);
filteredData = filter(filtPts, 1, eegData, [], 2);


%% PLV
if P.verbose
	fprintf('Calculating PLV for %d trials...\n', sum(P.condIdx, 1))
end
for chanCount = 1:numChans
    filteredData(chanCount, :, :) = ...
                        angle(hilbert(squeeze(filteredData(chanCount, :, :))));
end

plv = zeros(size(filteredData, 2), numChans, numChans, numConditions);
if P.nbootci == 0
    plvCI = [];
else
    plvCI = zeros(size(filteredData, 2), numChans, numChans, numConditions, 2);
end

for chanCount = 1:numChans - 1
    chanData = squeeze(filteredData(chanCount, :, :));
    for compareChanCount = chanCount + 1:numChans
        compareChanData = squeeze(filteredData(compareChanCount, :, :));
        for conditionCount = 1:numConditions
            % Here, important to transpose EEG data because bootci will resample
            % from rows (not cols), so must have rows=trials and cols=time
            chanA = chanData(:, P.condIdx(:, conditionCount))';
            chanB = compareChanData(:, P.condIdx(:, conditionCount))';
            condTrials = sum(P.condIdx(:, conditionCount));
            
            plv(:, chanCount, compareChanCount, conditionCount) = ...
                sbf_plv(chanA, chanB, condTrials)';

            if P.nbootci > 0
                plvCI(:, chanCount, compareChanCount, conditionCount, :) = ...
                    bootci(P.nbootci, {@sbf_plv, chanA, chanB, condTrials}...
                        , 'type', 'stud'...
                        , 'alpha', P.bootalpha)'; %#ok<AGROW>
            end
        end
    end
end

plv = squeeze(plv);
plvCI = squeeze(plvCI);


    function plvAB = sbf_plv(chA, chB, N)
        plvAB = abs(...
                    sum(...
                        exp(1i * (chA - chB)) ) )...
                / N;
