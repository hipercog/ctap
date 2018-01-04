function locstr = ctap_eeg_find_chlocs(Cfg)
% CTAP_EEG_FIND_CHLOCS checks different possible ways chanlocs could be defined
% 'Cfg.eeg.chanlocs' field existence is checked in ctap_auto_config(), but 
% what's in the field?
%   'file' - trust it is a chanlocs file, return it
%   'dir' - read the directory for files with typical chanlocs extensions,
%           return the file with closest filename to the EEG filename
%   'cell' - assume it is cell string array of chanlocs filenames; return the
%           cell contents at the index of the current subject number

if exist(Cfg.eeg.chanlocs, 'file') == 2
    locstr = Cfg.eeg.chanlocs; 
    return
end

if isdir(Cfg.eeg.chanlocs)
    % Find chanlocs from directory, as filename closest matching to EEG filename
    % NOTE: ONLY WORKS IF CHANLOCS ARE NAMED REGULARLY, WITH SUBJECT IDENTIFIER
    % MATCHING EEG FILE, E.G. s01_eeg.bdf <--> s01_chanlocs.elp
    exts = {'locs', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'elp', 'ced'};
    loc = find_closest_file(Cfg.measurement.physiodata, Cfg.eeg.chanlocs, exts);
    locstr = fullfile(Cfg.eeg.chanlocs, loc);

elseif iscell(Cfg.eeg.chanlocs) 
    % If all chanlocs filepaths have been provided separately, as cell str array
    locstr = Cfg.eeg.chanlocs{Cfg.subject.subjectnr};

% elseif TODO: SUPPORT THE CASE WHEN CHANLOCS ARE ALREADY IN THE EEG FILE:
% THIS WOULD MAKE OBSOLETE 'Cfg.eeg.chanlocs' AND THE CORRESPONDING CHECK IN
% 'ctap_auto_config()'
    
end



end