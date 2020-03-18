# Current dependencies of CTAP

Listing of external dependencies other than EEGLAB
All dependencies are included in this folder for convenience, licenced within their own folders. The CTAP licence does not apply.

## firfilt
* from github: https://github.com/widmann/firfilt
* licence unknown
* used by: CTAP_fir_filter, CTAP_filter_blink_ica
* status: should be loaded as an EEGLAB plugin: will not be mounted directly in CTAP as it is under regular maintenance.

## ctap/dependencies/nansuite:
* from FileExchange: http://www.mathworks.com/matlabcentral/fileexchange/6837-nan-suite
* license unknown
* used by?: LIBRA, src/utils (once)
* status: might not be required

## ctap/dependencies/mksqlite:
* from https://sourceforge.net/projects/mksqlite/ (or https://github.com/AndreasMartin72/mksqlite)
* license LGPLv2
* used by: src/utils/IO (feature export)
* status: required

## ctap/dependencies/LIBRA:
* from https://wis.kuleuven.be/stat/robust/LIBRA
* license unknown
* used by: continuous_sound_and_vibrations_analysis
../ctap/dependencies/continuous_sound_and_vibrations_analysis/fastmcd.m
../ctap/dependencies/continuous_sound_and_vibrations_analysis/fastlts.m
* status: might not be required

## ctap/dependencies/importvpd:
* from: adapted by Ben Cowley from Ledalab
* license MIT
* used by: ../ctap/src/generic/ctapeeg_load_data.m
* status: yet another input data type

## ctap/dependencies/gridLegend:
* from
* license custom license file
* used by: ../ctap/src/utils/plotting/plot_epoched_EEG.m
* status: maybe not required

## ctap/dependencies/fastica_25:
* from http://research.ics.aalto.fi/ica/fastica/
* license GPL
* used by: EEGLAB pop_runica.m
* status: required

## ctap/dependencies/faster_plugin:
* from http://www.mee.tcd.ie/neuraleng/Research/Faster
* license GPL
* used by: many artefact detection routines in CTAP
* status: required

## ctap/dependencies/continuous_sound_and_vibrations_analysis:
* from http://www.mathworks.com/matlabcentral/fileexchange/21384-continuous-sound-and-vibration-analysis
* license BSD, custom license file, allows use
* used by: ../ctap/src/utils/mvoutlier.m, LIBRA?
* status: fastmcd.m used, might be laborious to replace (does LIBRA have something similar?)

## ctap/dependencies/adjust_pluging:
* from http://www.unicog.org/pm/pmwiki.php/MEG/RemovingArtifactsWithADJUST
* license >= GNUv2
* used by: CTAP preprocessing function ctapeeg_detect_bad_comps()
* status: required

## ctap/dependencies/epoch2continuous.m:
* from Javier Lopez-Calderon, SCNN?
* license unknown
* used by: ../ctap/src/generic/ctapeeg_epoch_data.m
* status: used but not required

## ctap/dependencies/litekmeans:
* from
* license
* used by: eeg_detect_blink.m (but not stable)
* status: not required
