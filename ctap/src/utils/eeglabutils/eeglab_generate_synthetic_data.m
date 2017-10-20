function [EEG, clfile] = eeglab_generate_synthetic_data(dlen_sec, fs, nchan)
%EEGLAB_GENERATE_SYNTHETIC_DATA create synthetic datasets (now only random)
%
% Generates synthetic EEG data for testing purposes

    %clfdir = '/ukko/users/jkor/work/projects/ctap/ctap/res';

    if ~ismember(nchan, [16,32,64,128,160,256])
       error('eeglab_generate_synthetic_data:invalidNumberOfChannels',...
           'Allowed values for nchan are 16, 32, 64, 128, 160, 256.'); 
    end

    clfile = which(sprintf('chanlocs%d_biosemi_withEOG.elp', nchan));
    nchan = nchan + 4; %EOG channels

    setname = sprintf(...
        'Synthetic EEG data: %d channels %d min at %d Hz using %s().',...
                        nchan, dlen_sec/60, fs, mfilename);

    %TODO(feature-request)(JTOR): generate EEG-like data instead of random data
    EEG = create_eeg(rand(nchan, dlen_sec*fs), 'fs', fs, 'setname', setname);

    % reside in ctap/res, should be in Matlab path if CTAP is
    EEG = ctapeeg_load_chanlocs(EEG, 'locs', fullfile(clfile));

    for i=1:nchan-4
       EEG.chanlocs(i).type = 'EEG';
    end
    for i= (nchan-3):nchan
       EEG.chanlocs(i).type = 'EOG';
    end

end % of eeglab_generate_synthetic_data()
