% Generates a synthetic EEG based on the BCICIV data file.
%
% Args:
%   datafile    = a .mat file containing the BCICIV data
%   chfile      = channel location file
%   mdl_order   = model order for the synthetic model
% Returns:
%   eeg         = EEG-struct containing synthetic data
%
% todo: almost identical to ctaptest_generate_data.m
function eeg = ctaptest_datagen(datafile,chfile,mdl_order)
    load(datafile); % this loads the cnt, nfo and mrk
    ch = readlocs(chfile);
    % reserve space for data: samples x channels
    syn_len = 100 * 60;
    data = zeros(syn_len, length(ch));
    for k=1:length(ch)
        % find closest channel from input data
        [~, idx] = min(eucl([ch(k).X ch(k).Y], [nfo.xpos nfo.ypos]));
        fprintf(1, 'closest match was ch=%d,generating...\n', idx);
        input_data = 0.1 * double(cnt(:, idx));
        data(:, k)  = generate_channel(input_data, mdl_order, syn_len);
    end
    % Wrap data into EEG-structure:
    eeg = eeg_emptyset();
    eeg.data = data';
    eeg.chanlocs = ch;
    eeg = check_channel_types(eeg);
    eeg.srate = 100;
    eeg = eeg_checkset(eeg);
    eeg = pop_resample(eeg, 256);
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

%% Generate an equal length vector of synthetic data from dat
function syn = generate_channel(dat, ord, syn_len)
    boundary = syn_len / 2;
    syn = filter(1, aryule(dat,ord), randn(syn_len + 2 * boundary, 1));
    % 1. cut-out boundaries
    syn = syn(boundary:end - boundary - 1);
    % 2. normalize EEG vector
    syn = norm_vect(syn, 120, -120); % normalize to a new range
end

%% Checks that channel types have been assigned
function eeg = check_channel_types(eeg)
    % ALL CHANNELS ARE NOW EEG
    [eeg.chanlocs.type] = deal('EEG');
end
