% Adds correct CTAP-fields to the dataset so it passes analysis steps
% TODO: Check if this is still needed
%
function eeg = ctaptest_add_ctap(eeg)
    eeg.CTAP.subject = char(randi([65 90], 1, 10));
    eeg.CTAP.measurement.casename = eeg.CTAP.subject;
    eeg.CTAP.files.eegFile = 'synthetic';
    eeg.CTAP.files.channelLocationsFile = 'synthetic';
    eeg.CTAP.time.fileStart = 1924;
    eeg.CTAP.time.dataStart = 2540;
    eeg.CTAP.meta = 'synthetic';
    eeg.CTAP.date = date;
    eeg.CTAP.protocol = 'synthetic';
%     eeg.CTAP.history(1).msg = ['na_' datestr(now, 'yymmddHHMM')];
% 	eeg.CTAP.history(1).fun = 'na';
% 	eeg.CTAP.history(1).args = 'na';
    eeg.CTAP.artifact = [];
    eeg.CTAP.reference = eeg.ref;

    eeg = sbf_remove_peripherals(eeg);
    eeg = sbf_update_channel_types(eeg);
end


% Remove non-EEG data
function eeg = sbf_remove_peripherals(eeg)
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
function eeg = sbf_update_channel_types(eeg)
    [eeg.chanlocs.type]=deal('EEG');
    veog_idx = ismember({eeg.chanlocs.labels}, 'VEOG');
    heog_idx = ismember({eeg.chanlocs.labels}, 'HEOG');
    [eeg.chanlocs(veog_idx).type] = deal('EOG');
    [eeg.chanlocs(heog_idx).type] = deal('EOG');
end
