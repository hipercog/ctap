% Converts a BCICIV dataset to a set-format
% Note: Only works for this specific dataset due to hardcoded values
%
% Arga:
% 	filename <string>: path to target file
%
% Returns:
% 	eeg: EEG struct
function eeg = ctaptest_convert_bci(filename)
	load(filename)

	eeg = eeg_emptyset();

	eeg.data = single(cnt');
	eeg.srate = 100;

	chanlocs.labels = '';
	chanlocs.X = [];
	chanlocs.Y = [];

	% Make the channel locations structure
	for k = 1:length(nfo.clab)
		chanlocs(k).labels = nfo.clab{k};
		chanlocs(k).X = nfo.xpos(k);
		chanlocs(k).Y = nfo.ypos(k);
	end

	eeg.chanlocs = chanlocs;
	eeg = eeg_checkset(eeg);
	eeg = eeg_checkchanlocs(eeg);

end
