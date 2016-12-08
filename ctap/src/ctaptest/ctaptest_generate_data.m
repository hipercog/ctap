% Generates a synthetic EEG based on the BCICIV data file.
%
% Args:
%   datafile <string>: path to an EEGLAB set-file
%   ch_file <string>: path to a channel location file for the target EEG
%   eeg_length <double>: length of the target EEG (in seconds)
%   srate <double>: desired sampling rate for the target EEG
%   model_order <int>: AR model order for the target EEG
%
% Returns:
%   eeg: EEG-struct containing the generated data
%
function eeg = ctaptest_generate_data(datafile, ch_file, eeg_length, srate, model_order)

    ch = readlocs(ch_file);
	eeg_original = pop_loadset(datafile);
	
	% reference to average
	eeg_original = pop_reref(eeg_original, []);

    % reserve space for data: samples x channels
    data = zeros(eeg_length * eeg_original.srate, length(ch));

    for k=1:length(ch)
        % find closest channel from input data
		[~, idx] = min(eucl([ch(k).X ch(k).Y], [[eeg_original.chanlocs.X]', ... 
			                                    [eeg_original.chanlocs.Y]']));

        fprintf(1, 'closest match was ch=%d,generating...\n', idx);

		data(:, k) = generate_channel(eeg_original.data(idx, :)', ...
									  model_order, ... 
									  eeg_length * eeg_original.srate);
    end

    % Wrap data into EEG-structure:
    eeg = eeg_emptyset();
    eeg.data = data';
	eeg.srate = eeg_original.srate;
    eeg.chanlocs = ch;
    eeg = check_channel_types(eeg);
    eeg = eeg_checkset(eeg);

	if srate ~= eeg_original.srate
    	eeg = pop_resample(eeg, srate);
		eeg.srate = srate
	else
		eeg.srate = eeg_original.srate
	end
end


%% Returns the range of vector input vector x
function r = range(x)
    r = max(x) - min(x);
end


%% Normalize or "center" the vector
function x = norm_vect(x, new_max, new_min)
    m = min(x); % minimum
    r = max(x) - m; % range
    x = (x - m) / r; % normalized between 0 and 1
    
    r2 = new_max - new_min;
    x = (x * r2) + new_min;
end


%% Generate an equal length vector of synthetic data from data
function output = generate_channel(input_data, order, output_length)
    boundary = output_length / 2;
    output = filter(1, aryule(input_data, order), ... 
		            randn(output_length + 2*boundary, 1));
    % 1. cut-out boundaries
    output = output(boundary:end - boundary - 1);
    % 2. normalize EEG vector
    output = norm_vect(output, 120, -120); % normalize to a new range
end


%% Checks that channel types have been assigned
function eeg = check_channel_types(eeg)
    % ALL CHANNELS ARE NOW EEG
    [eeg.chanlocs.type] = deal('EEG');
end
