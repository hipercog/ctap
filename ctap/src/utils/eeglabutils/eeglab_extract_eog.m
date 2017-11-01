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
p.addRequired('veogChanNames', @iscellstr);
p.addRequired('heogChanNames', @iscellstr);
p.addParameter('filter', false, @islogical);

p.parse(EEG, veogChanNames, heogChanNames, varargin{:});
Arg = p.Results;


%% Create veog and heog signals
Eog = struct();

veog = sbf_get_signal(EEG, veogChanNames);
Eog.veog = veog;
if ~isnan(veog)
    disp(['Using ''',catcellstr(veogChanNames),''' as veog signal...']);
else
    disp(['Channels {',catcellstr(veogChanNames,'sep',','),'} were not found. Cannot extract veog signal.'])
end

heog = sbf_get_signal(EEG, heogChanNames);
Eog.heog = heog;
if ~isnan(heog)
    disp(['Using ''',catcellstr(heogChanNames),''' as heog signal...']);
else
    disp(['Channels {',catcellstr(heogChanNames,'sep',','),'} were not found. Cannot extract heog signal.'])
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
                sig = EEG.data(chIndArr(1),:)-EEG.data(chIndArr(2),:);
            otherwise
                error('eeglab_extract_eog:tooManyChannels',...
                    'There are too many channels specified. Check inputs.');
        end
    end

end %of function
