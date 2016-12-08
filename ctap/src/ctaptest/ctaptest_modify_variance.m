% Modifies variance of channels
%
% Args:
% 	eeg: EEG struct
% 	ch <mat>: vector of channel indices
% 	multiplier <double>: multiplying coeficient
%
function eeg = ctaptest_modify_variance(eeg, ch, multiplier)

if isempty(ch)
    ch = 1:size(eeg.data,1);
end

eeg.data(ch,:)=eeg.data(ch,:)*sqrt(multiplier);

variance_params.channel_idx = ch;
variance_params.multiplier = multiplier;

if isfield(eeg.CTAP.artifact,'variance')
    eeg.CTAP.artifact.variance(end+1) = variance_params;
else
    eeg.CTAP.artifact.variance = variance_params;
end
