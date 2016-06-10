% This must be changed so it passes is_valid_CTAP functions
function eeg = ctaptest_add_ctap(eeg)
    eeg.CTAP.subject = char(randi([65 90], 1, 10));
    eeg.CTAP.measurement.casename = 'kakk';
    eeg.CTAP.files.eegFile = 'asdf';
    eeg.CTAP.files.channelLocationsFile = 'moi';
    eeg.CTAP.time.fileStart = 1924;
    eeg.CTAP.time.dataStart = 2540;
    eeg.CTAP.meta = 'this might be meta';
    eeg.CTAP.date = date;
    eeg.CTAP.protocol = '#yolo';
    eeg.CTAP.history(1).msg = ['step_' datestr(now, 'yymmddHHMM')];
	eeg.CTAP.history(1).fun = 'fu';
	eeg.CTAP.history(1).args = 'so done';
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
