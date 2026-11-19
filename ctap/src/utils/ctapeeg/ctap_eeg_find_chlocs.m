function locstr = ctap_eeg_find_chlocs(Cfg)
% CTAP_EEG_FIND_CHLOCS checks different possible ways chanlocs could be defined
% 'Cfg.eeg.chanlocs' field existence is checked in ctap_auto_config(), but 
% what's in the field?
%   'file' - trust it is a chanlocs file, return it
%   'dir' - read the directory for files with typical chanlocs extensions,
%           return the file with closest filename to the EEG filename
%           NOTE: ONLY WORKS IF CHANLOCS ARE NAMED REGULARLY, WITH SUBJECT
%           I.D. MATCHING EEG FILE, E.G. s01_eeg.bdf <--> s01_chanlocs.elp
%   'cell' - assume it is cell string array of chanlocs filenames; return the
%           cell contents at the index of the current subject number


if ~isfield(Cfg.eeg, 'chanlocs') || islogical(Cfg.eeg.chanlocs)
    % SUPPORT THE CASE WHEN CHANLOCS ARE ALREADY IN THE EEG FILE
    myReport('WARN No chanlocs data provided; assuming chanlocs are in EEG'...
        , Cfg.env.logFile);
    locstr = '-UNSPECIFIED-';

elseif iscell(Cfg.eeg.chanlocs) 
    % If all chanlocs filepaths have been provided separately, as cell str array
    % Indexing by .subjectnr which should be same as 1:num_subjs
    idx = isStructMember(Cfg.MC.measurement, 'subject', Cfg.measurement.subject) &...
        isStructMember(Cfg.MC.measurement, 'session', Cfg.measurement.session) &...
      isStructMember(Cfg.MC.measurement, 'measurement', Cfg.measurement.measurement);
    Cfg.eeg.chanlocs = Cfg.eeg.chanlocs{idx};
    locstr = ctap_eeg_find_chlocs(Cfg);

elseif exist(Cfg.eeg.chanlocs, 'file') == 2
    [p, ~, ~] = fileparts(Cfg.eeg.chanlocs);
    if isempty(p)
        locstr = which(Cfg.eeg.chanlocs);
    else
        locstr = Cfg.eeg.chanlocs;
    end

elseif isfolder(Cfg.eeg.chanlocs)
    % Find chanlocs from directory, as filename closest matching to EEG filename
    exts = {'locs', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'elp', 'ced'};
    loc = find_closest_file(Cfg.measurement.physiodata, Cfg.eeg.chanlocs, exts);
    locstr = fullfile(Cfg.eeg.chanlocs, loc);
    
end


end

function tf = isStructMember(S, f, q)
% isStructMember  Return logical vector: true if q appears in S.f
%   S - struct array with some field 'f' (numeric, char, string, or cell)
%   f - field to look within
%   q - query scalar or array to test for membership
    cell_arr = arrayfun(@(s) string(s.(f)), S);
    tf = ismember(cell_arr, string(q));
end
