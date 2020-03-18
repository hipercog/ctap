function [EEG, EEGart, EEGclean] = param_sweep_sdload(seed_fname, PARAM)
% Note: cannot be called directly. Called as part of
% test_param_sweep_sdgen_*()

sd_file = fullfile(PARAM.path.seedDataSrc, seed_fname);
[sd_path, sd_name] = fileparts(sd_file);
sd_factorized_subdir = fullfile(PARAM.path.synDataRoot, sd_name);


EEGclean = pop_loadset(sprintf('%s_syndata_clean.set', sd_name),...
                        sd_factorized_subdir);

EEGart = pop_loadset(sprintf('%s_syndata_artifacts.set', sd_name),...
                    sd_factorized_subdir);

EEG = pop_loadset(sprintf('%s_syndata.set', sd_name),...
                    PARAM.path.synDataRoot);

end
