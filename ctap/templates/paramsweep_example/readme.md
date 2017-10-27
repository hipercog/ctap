
# Parameter sweep examples (codename `HYDRA`)

## HOWTO
Make sure you have correctly set up CTAP, see: [main readme](../../../README.md).

###### Note!
* HYDRA works currently only branch `dev`.
* git lfs needs to be _installed_ to get HYDRA source data. Run `git lfs fetch` and `git lfs checkout`, if you only have file pointers and not data (visible as an empty EEG dataset error).

Always check the contents of `param_sweep_setup.m` prior to running a script and make sure the save locations and other settings are satisfactory.

The current solution is a temporary one where `param_sweep_*.m` scripts make changes directly to workspace causing hard-to-follow stuff to happen. A better option would be to turn them into functions.

Run the batch files in the following order:
1. `param_sweep_sdgen.m`
2. `test_param_sweep_sdgen_blink.m`
3. `test_param_sweep_sdgen_badchan.m`
4. `test_param_sweep_sdgen_badsegment.m`

`param_sweep_setup.m` contains variables that control how the scripts behave.
Each script creates its own ctap branch.

## Main batch files

### Shared files
File | Purpose
------------ | -------------
`param_sweep_setup.m`                   | Create `Cfg` and some constants
`param_sweep_sdgen.m`                   | Generate synthetic data
`generate_synthetic_data_paramsweep.m`  | Generate synthetic data -- lower level function
`param_sweep_sdload.m`                  | Load synthetic data
`param_sweep_prepro.m`                  | Apply pre-processing pipe

### Synthetic data
File | Purpose
------------ | -------------
`test_param_sweep_sdgen_blink.m`      | Blink correction
`test_param_sweep_sdgen_badchan.m`    | Bad channel detection
`test_param_sweep_sdgen_badsegment.m` | Bad segment detection

### Real data
File | Purpose
------------ | -------------
TBA   | Blink correction
TBA   | Bad channel detection
TBA   | Bad segment detection
