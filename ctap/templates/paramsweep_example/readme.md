
# Parameter sweep examples (codename `HYDRA`)

## Note!
* HYDRA works currently only branch `dev`.
* git lfs needs to be _installed_ to get HYDRA source data. Run `git lfs fetch` and `git lfs checkout`, if you only have file pointers and not data (visible as an empty EEG dataset error).

## HOWTO

To run HYDRA experiments you need to do the following:
1. Set up CTAP: see [main readme](../../../README.md)
2. Make sure Matlab working directory is set at CTAP repo root (to get correct seed data location)
3. Add variable `PROJECT_ROOT` to Matlab workspace to tell the scripts where to save results. Example: `PROJECT_ROOT = '/home/jkor/work_local/projects/ctap/ctapres_hydra'`
4. Run: `batch_psweep_datagen` script
5. Run: `batch_psweep_experiments` script

The function `param_sweep_setup.m` contains common options.

The `batch_psweep_experiments` script calls other scripts that have tunable options in them.
By turning e.g. preprocessing off once it has been done once saves _a lot of_ time.
Each of these scripts have separate preprocessing pipes and separate sweeping.


## Files

File | Type | Purpose
------------ | ------------------------ | -------------
`batch_psweep_datagen`                  | script |Generate synthetic data, TODO: prepare real data
`batch_psweep_experiments`              | script | Run all experiments
`test_param_sweep_sdgen_blink.m`        | script | Blink correction experiment
`test_param_sweep_sdgen_badchan.m`      | script | Bad channel detection experiment
`test_param_sweep_sdgen_badsegment.m`   | script | Bad segment detection experiment
`param_sweep_setup.m`                   | function | Create `PARAM` struct and some constants
`param_sweep_sdgen.m`                   | function | Generate synthetic data
`generate_synthetic_data_paramsweep.m`  | function | Generate synthetic data -- lower level function
`param_sweep_sdload.m`                  | function | Load synthetic data


## Directories
The follwing directories are created under `PARAM.path.projectRoot`:

Directory | Description
------------ | -------------
`syndata`         | Generated synthetic datasets
`ctap_hydra_*`    | Preprocessing pipe CTAP folders for each of the experiments
`sweepres_*`      | Parameter sweep results for each of the experiments
`logs`            | CTAP high level log files (if any)
