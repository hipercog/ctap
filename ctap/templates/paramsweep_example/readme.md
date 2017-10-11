
# Parameter sweep examples (codename `HYDRA`)

## HOWTO
Start with one of the main batch files listed below. Always check the contents of `param_sweep_setup.m` prior to running a script and make sure the save locations and other settings are satisfactory.

The current solution is a temporary one where `param_sweep_*.m` scripts make changes directly to workspace causing hard-to-follow stuff to happen. A better option would be to turn them into functions.

## Main batch files

### Synthetic data
File | Purpose
------------ | -------------
`test_param_sweep_sdgen_blink.m`      | Blink correction
`test_param_sweep_sdgen_badchan.m`    | Bad channel detection
`test_param_sweep_sdgen_badsegment.m` | Bad segment detection

### Real data
File | Purpose
------------ | -------------
      | Blink correction
   | Bad channel detection
 | Bad segment detection

### Shared files
File | Purpose
------------ | -------------
`param_sweep_setup.m`                   | Create `Cfg` and some constants
`param_sweep_sdgen.m`                   | Generate synthetic data
`generate_synthetic_data_paramsweep.m`  | Generate synthetic data -- lower level function
`param_sweep_sdload.m`                  | Load synthetic data
`param_sweep_prepro.m`                  | Apply pre-processing pipe
