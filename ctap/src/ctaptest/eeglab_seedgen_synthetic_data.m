% Generates a synthetic EEG based on seed EEG dataset
%
% todo: similar to ctaptest_generate_syndata.m but different interface.
% Merge somehow.
%
% Args:
%   seedEEG <struct>: Seed EEGLAB dataset with channel locations in place
%   ch <struct>: EEGLAB channel locations struct for the new dataset, ch = readlocs(ch_file);
%   eeg_length <double>: length of the target EEG (in seconds)
%   srate <double>: desired sampling rate for the target EEG
%   model_order <int>: AR model order for the target EEG
%
% Returns:
%   EEG: EEG-struct containing the generated data
function EEG = eeglab_seedgen_synthetic_data(seedEEG, ch, eeg_length, srate, model_order)

	% reference to average
	seedEEG = pop_reref(seedEEG, []);

    % reserve space for data: samples x channels
    n_samples = ceil(eeg_length * seedEEG.srate); %.srate not always integer
    data = zeros(n_samples, length(ch));

    for k=1:length(ch)
        % find closest channel from input data
		[~, idx] = min(eucl([ch(k).X ch(k).Y], [[seedEEG.chanlocs.X]', ... 
			                                    [seedEEG.chanlocs.Y]']));

        fprintf(1, 'closest match was ch=%d,generating...\n', idx);

		data(:, k) = sbf_generate_channel(seedEEG.data(idx, :)', ...
									  model_order, ... 
									  n_samples);
        if isnan(data(1,k))
           keyboard; 
        end
    end

    % Wrap data into EEG-structure:
    EEG = eeg_emptyset();
    EEG.data = data';
	EEG.srate = seedEEG.srate;
    EEG.chanlocs = ch;
    EEG = sbf_check_channel_types(EEG);
    EEG = eeg_checkset(EEG);

	if srate ~= seedEEG.srate
    	EEG = pop_resample(EEG, srate);
		EEG.srate = srate;
	else
		EEG.srate = seedEEG.srate;
	end
end


%% Normalize or "center" the vector
function x = sbf_norm_vect(x, new_max, new_min)
    m = min(x); % minimum
    r = max(x) - m; % range
    x = (x - m) / r; % normalized between 0 and 1
    
    r2 = new_max - new_min;
    x = (x * r2) + new_min;
end


%% Generate an equal length vector of synthetic data from data
function output = sbf_generate_channel(input_data, order, output_length)
    boundary = output_length / 2;
    output = filter(1, aryule(input_data, order), ... 
		            randn(output_length + 2*boundary, 1));
    % 1. cut-out boundaries
    output = output(boundary:end - boundary - 1);
    % 2. normalize EEG vector
    output = sbf_norm_vect(output, 120, -120); % normalize to a new range
    
    if isnan(output(1))
       keyboard; 
    end
end


%% Checks that channel types have been assigned
function EEG = sbf_check_channel_types(EEG)
    % ALL CHANNELS ARE NOW EEG
    [EEG.chanlocs.type] = deal('EEG');
end
