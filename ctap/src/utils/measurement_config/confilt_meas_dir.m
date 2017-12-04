function [MC, runMC] = confilt_meas_dir(data_dir_in, ext, subj_filt)
%CONFILT_MEAS_DIR Create measurement config (MC) based on folder

    % first create measurement structure from given dir and file extension
    MC = path2measconf(data_dir_in, ext);
    % Select measurements to process, matching given 'subj_filt' vector to 
    %  file-order indices
    Filt.subject = {MC.subject.subject};
    Filt.subject = Filt.subject(ismember([MC.subject.subjectnr], subj_filt));
    runMC = get_measurement_id(MC, Filt);

end