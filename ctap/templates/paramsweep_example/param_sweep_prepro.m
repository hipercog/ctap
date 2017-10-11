

% Create measurement config (MC) based on folder
% Measurement config based on synthetic source files
MC = path2measconf(syndata_dir, '*.set');
Cfg.MC = MC;

clear('Filt')
Filt.subjectnr = 1;
Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);

%Cfg.pipe.runSets = {Cfg.pipe.stepSets(3).id}; %/3_tmp/

CTAP_pipeline_looper(Cfg,...
                    'debug', STOP_ON_ERROR,...
                    'overwrite', OVERWRITE_OLD_RESULTS);