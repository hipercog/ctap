function EEG = remove_ica(EEG)
%REMOVE_ICA if the ICA fields are not needed and removing them improves
%reliability of other operations, it can be handy to clear them all in one
%go.

EEG.icaact = [];
EEG.icawinv = [];
EEG.icasphere = [];
EEG.icaweights = [];
EEG.icachansind = [];

end