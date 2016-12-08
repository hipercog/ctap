function [units, data] = ctap_read_detections(EEG, focus)
%CTAP_READ_DETECTIONS finds the method_data per method for bad channel,
% epoch, component detections.

rejmethods = {'badchans', 'badepochs', 'badsegev', 'badcomps'};
rejdattype = {   'chans',    'epochs',  'evidstr',    'comps'};

if ~ismember(rejmethods, focus)
    error('ctap_read_detections:bad_param', 'Not defined for %s', focus)
end

mtd = EEG.CTAP.(focus).detect.src{1,1};
idx = EEG.CTAP.(focus).detect.src{1,2};
unit = rejdattype{ismember(rejmethods, focus)};

units = EEG.CTAP.(focus).(mtd)(idx).(unit);
data = EEG.CTAP.(focus).(mtd)(idx).scores;

for i = 2:size(EEG.CTAP.(focus).detect.src, 1)
    mtd = EEG.CTAP.(focus).detect.src{i,1};
    idx = EEG.CTAP.(focus).detect.src{i,2};
    units = union(units, EEG.CTAP.(focus).(mtd)(idx).(unit));
    data = join(data, EEG.CTAP.(focus).(mtd)(idx).scores, 'Keys', 'RowNames');
    
end

end % ctap_read_detections()
