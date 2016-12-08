% Adds correct CTAP-fields to the dataset so it passes analysis steps
% TODO: Check if this is still needed
%
function eeg = ctaptest_add_ctap(eeg)
    eeg.CTAP.subject = char(randi([65 90], 1, 10));
    eeg.CTAP.measurement.casename = 'kakka';
    eeg.CTAP.files.eegFile = 'kakka';
    eeg.CTAP.files.channelLocationsFile = 'kakka';
    eeg.CTAP.time.fileStart = 1924;
    eeg.CTAP.time.dataStart = 2540;
    eeg.CTAP.meta = 'kakka';
    eeg.CTAP.date = date;
    eeg.CTAP.protocol = 'kakka';
    eeg.CTAP.history(1).msg = ['kakka_' datestr(now, 'yymmddHHMM')];
	eeg.CTAP.history(1).fun = 'kakka';
	eeg.CTAP.history(1).args = 'kakka';
    eeg.CTAP.artifact = [];
    eeg.CTAP.reference = eeg.ref;

    eeg = remove_peripherals(eeg);
    eeg = update_channel_types(eeg);
end


% Remove non-EEG data
function eeg = remove_peripherals(eeg)
    bad_idx = find(cellfun(@isempty, {eeg.chanlocs.X}));
    eeg.data(bad_idx, :) = [];
    eeg.chanlocs(bad_idx) = [];
    eeg.nbchan = eeg.nbchan - numel(bad_idx);
    eeg = eeg_checkset(eeg);
    if eeg.nbchan == 0
        error('No channels left!')
    end
end


% Make sure channel types are correct
function eeg = update_channel_types(eeg)
    [eeg.chanlocs.type]=deal('EEG');
    veog_idx = strmatch('VEOG', {eeg.chanlocs.labels});
    heog_idx = strmatch('HEOG', {eeg.chanlocs.labels});
    [eeg.chanlocs(veog_idx).type] = deal('EOG');
    [eeg.chanlocs(heog_idx).type] = deal('EOG');
end
