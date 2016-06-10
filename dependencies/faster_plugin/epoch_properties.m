function list_properties = epoch_properties(EEG,eeg_chans,epochs)
%% adapted to allow specification of epoch indices
%   by BEN COWLEY, 28.06.2014

if length(size(EEG.data)) < 3
	fprintf('Not epoched.\n');
	return;
end

neps=numel(epochs);
list_properties = zeros(neps,3);
means = mean(EEG.data(eeg_chans,:),2);

% 1 Epoch's mean deviation from channel means.
measure = 1;
for u = 1:neps
	list_properties(u,measure) = mean(abs(squeeze(mean(EEG.data(eeg_chans,:,epochs(u)),2)) - means));
end

% 2 Epoch variance
measure = measure + 1;
list_properties(:,measure) = mean(squeeze(var(EEG.data(eeg_chans,:,epochs),0,2)));

% 3 Max amplitude difference
measure = measure + 1;
ampdiffs = zeros(numel(eeg_chans),neps);
for t = eeg_chans
	for u = 1:neps
		ampdiffs(t,u) = max(EEG.data(t,:,epochs(u))) - min(EEG.data(t,:,epochs(u)));
	end
end
list_properties(:,measure) = mean(ampdiffs,1);

% subtract the median
for v = 1:measure
	list_properties(:,v) = list_properties(:,v) - median(list_properties(:,v));
end