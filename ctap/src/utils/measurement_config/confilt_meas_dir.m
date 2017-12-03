%% Create measurement config (MC) based on folder
function [MC, runMeasurements] = confilt_meas_dir(data_dir_in, ext, subj_filt)

    % first create measurement structure from given dir and file extension
    MC = path2measconf(data_dir_in, ext);
    % Select measurements to process, matching given vector to file-order indices
    Filt = {MC.subject.subject};
    Filt = Filt(ismember([MC.subject.subjectnr], subj_filt));
    runMeasurements = get_measurement_id(MC, Filt);

end