function Eog = eeglab_extract_eog(EEG, veogChanNames, heogChanNames, varargin)
%CTAP_EXTRACT_EOG - Extract veog and heog signals based on channel names
%
% Inputs:
%   EEG         struct, EEGLAB struct
%   *ChanNames  cellstr, Channel names. Allowed compositions are:
%               {},{'chname1'},{'chname1','chname2'}
%
% Outputs
%   Eog         struct, Veog and heog signals as Eog.veog and Eog.heog.

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('veogChanNames', @(x) iscellstr(x) || isstring(x) || ischar(x));
p.addRequired('heogChanNames', @(x) iscellstr(x) || isstring(x) || ischar(x));
p.addParameter('filter', false, @islogical);
p.addParameter('invert_polarity', false, @islogical);

p.parse(EEG, veogChanNames, heogChanNames, varargin{:});
Arg = p.Results;

if ~iscell(veogChanNames)
    veogChanNames = {veogChanNames};
end
if ~iscell(heogChanNames)
    heogChanNames = {heogChanNames};
end


%% Create veog and heog signals
Eog = struct();

veog = sbf_get_signal(EEG, veogChanNames);
veog = sbf_check_polarity(veog, EEG.srate, Arg.invert_polarity);
Eog.veog = veog;
if ~isnan(veog)
    fprintf('Using ''%s'' as vertical EOG signal...\n', catcellstr(veogChanNames));
else
    fprintf('Channels {%s} were not found. Cannot extract vertical EOG signal.\n'...
        , catcellstr(veogChanNames,'sep',','))
end

heog = sbf_get_signal(EEG, heogChanNames);
Eog.heog = heog;
if ~isnan(heog)
    fprintf('Using ''%s'' as horizontal EOG signal...\n', catcellstr(heogChanNames));
else
    fprintf('Channels {%s} were not found. Cannot extract horizontal EOG signal.\n'...
        , catcellstr(heogChanNames,'sep',','))
end


%% Filter to remove baseline wander
if isfield(Eog, 'veog') && Arg.filter
    Eog.veog = eegfilt(Eog.veog, EEG.srate, 1, 0);
end

if isfield(Eog, 'heog') && Arg.filter
    Eog.heog = eegfilt(Eog.heog, EEG.srate, 1, 0);
end


%% Subfunctions

    function sig = sbf_get_signal(EEG, chanNames)
        [chMatch, chIndArr] = ismember(chanNames, {EEG.chanlocs.labels});
        % finds channels locations as indices, in order
        
        % Check that all channels were found
        if numel(chanNames) ~= sum(chMatch)
           error('eeglab_extract_eog:channelNotFound',...
                 'Cannot find channel(s) ''%s''.',...
                  strjoin(chanNames(~chMatch),', ') ); 
        end
        
        % Extract EOG
        switch length(chIndArr)
            case 0
                sig = NaN;
            case 1
                sig = EEG.data(chIndArr,:);
            case 2
                if all(EEG.data(chIndArr(1),:) == EEG.data(chIndArr(2),:))
                    sig = EEG.data(chIndArr(1),:);
                else
                    sig = EEG.data(chIndArr(1),:) - EEG.data(chIndArr(2),:);
                end
            otherwise
                error('eeglab_extract_eog:tooManyChannels',...
                    'There are too many channels specified. Check inputs.');
        end
    end


    %% Estimate the polarity of the signal, and correct to be positive
    function sig = sbf_check_polarity(sig, srate, inv_cmd)
        
        smth = smooth(sig, numel(sig) / srate, 'sgolay');%NEEDS curve-fitting TOOLBOX
        polarityTendency = skewness(smth);
        
        [posPeaks, ~] = findpeaks(smth, srate);
        [negPeaks, ~] = findpeaks(-smth, srate);
        negPeaks = -negPeaks; % Restore the actual values
        
        madVal = median(abs(smth - median(smth)));%Threshold on robust deviation
        xtrmPos = posPeaks(posPeaks > 3 * madVal);
        xtrmNeg = negPeaks(negPeaks < -3 * madVal);

        if inv_cmd
            sig = -sig;
        elseif polarityTendency > 0 && abs(median(xtrmPos)) > abs(median(xtrmNeg))
            [hKS, pKS, KS] = kstest2(posPeaks, negPeaks, 'Tail', 'larger');
            if hKS
                % do nothing as v-EOG is already positive
                % sig = sig;
            end
        elseif polarityTendency < 0 && abs(median(xtrmPos)) < abs(median(xtrmNeg))
            [hKS, pKS, KS] = kstest2(negPeaks, posPeaks, 'Tail', 'larger');
            if hKS
                % flip the sign as v-EOG is negative
                sig = -sig;
            end
        else
        end
    end

end %of function
