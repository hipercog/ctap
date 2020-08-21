# General Overview

Three datasets are tested in the evaluation* of CTAP HYDRA - first two are used as seeds for generating synthetic data, third is used directly (with synthetic artefacts added):

* BCI IV from the Berlin Brain-Computer-Interface competition website
* Eyes-open and eyes-closed from the University of Bonn website
* Auditory CPT data from UCSD SCCN's HeadIT database

\*See publication for details: _Cowley, Korpela, Torniainen, XXXX, FIXME journal name_



# Dataset 1: BCIIV_calib_ds1a.set

This dataset is from BCI IV competition: http://bbci.de/competition/iv/
CTAP repo contains _.set_ file converted from original download.

A detailed description can be found: http://bbci.de/competition/iv/desc_1.html
Essential content of the description is copy-pasted below:

## Experimental Setup

These data sets were recorded from healthy subjects. In the whole session motor imagery was performed without feedback. For each subject two classes of motor imagery were selected from the three classes left hand, right hand, and foot (side chosen by the subject; optionally also both feet).

### Calibration data

In the first two runs, arrows pointing left, right, or down were presented as visual cues on a computer screen. Cues were displayed for a period of 4s during which the subject was instructed to perform the cued motor imagery task. These periods were interleaved with 2s of blank screen and 2s with a fixation cross shown in the center of the screen. The fixation cross was superimposed on the cues, i.e. it was shown for 6s. These data sets are provided with complete marker information.

### Technical Information

The recording was made using BrainAmp MR plus amplifiers and a Ag/AgCl electrode cap. Signals from 59 EEG positions were measured that were most densely distributed over sensorimotor areas. Signals were band-pass filtered between 0.05 and 200 Hz and then digitized at 1000 Hz with 16 bit (0.1 uV) accuracy. We provide also a version of the data that is downsampled at 100 Hz (first low-pass filtering the original data (Chebyshev Type II filter of order 10 with stopband ripple 50dB down and stopband edge frequency 49Hz) and then calculating the mean of blocks of 10 samples).

### References

Any publication that analyzes this data set should cite the following paper as a reference of the recording:
Benjamin Blankertz, Guido Dornhege, Matthias Krauledat, Klaus-Robert Müller, and Gabriel Curio. The non-invasive Berlin Brain-Computer Interface: Fast acquisition of effective performance in untrained subjects. NeuroImage, 37(2):539-550, 2007.



# Dataset 2: A-scalp-EO-Zall.set and B-scalp-EC-Oall.set

Data is from University of Bonn epileptology clinic: http://epileptologie-bonn.de/cms/front_content.php?idcat=193
CTAP repo contains _.set_ datasets in both A:eyes-open and B:eyes-closed conditions. If the data is downloaded from the website (where each channel is in a separate _.txt_ file), a script is provided to aggregate and save as _.set_ files: __reshape_import_UniBonn_data.m__

Detailed description can be found in the paper: Andrzejak _et al_ (2001) Phys. Rev. E, 64, 061907
Brief overview is below:

## Experimental Setup
Datasets A and B were recorded from healthy subjects with scalp EEG, during eyes-open and eyes-closed conditions respectively.

### Technical Information

The recording was made with a 128 channel recording system, montaged by 10/20 specification, with 12 bit analog-to-digital conversion. An average common reference (omitting electrodes containing strong eye movement artifacts) was used. The data has 100 electrodes for 23.6 seconds at sampling rate 173.61 Hz, and (due to the acquisition system) the frequency boundaries are 0.5--85 Hz.
The segments were selected and cut out from continuous multichannel EEG recordings after visual inspection
for artifacts, e.g., due to muscle activity or eye movements. In addition, the segments had to fulfill a stationarity criterion described in detail in the paper.

Importantly, please note that the signals included in these sets are randomized with regard to the recording contact, recording time and the patient or volunteer. Accordingly, the information of which signal corresponds to which recording contact or patient or volunteer is not available. In particular, there is no relation such as "Z001.txt" to "Z020.txt" are from the first volunteer. Neither do certain numbers correspond to certain recording sites.

### References

Andrzejak RG, Lehnertz K, Rieke C, Mormann F, David P, Elger CE (2001) _Indications of nonlinear deterministic and finite dimensional structures in time series of brain electrical activity: Dependence on recording region and brain state_, Phys. Rev. E, 64, 061907


# Dataset 3: 18C_vigilance_EC_clean.set

Data is from a standard Vigilance protocol defined by the University Hospital Leipzig (to be used with their VIGALL algorithm), recorded at University of Helsinki as part of CENT project (Cowley et al, 2016).

## Experimental Setup
Dataset was recorded from a healthy right-handed male subject, aged 29. Within the period of data included, subject was instructed to remain seated and relaxed with eyes closed. They reported that they did not fall asleep, and arrived at the experiment with a high score of 3 on Karolinska sleepiness scale, and had consumed no stimulants/depressants and no medications during last 24 hrs.

### Technical Information

EEG data were collected synchronously from 128 scalp and four electroocular electrodes with an active reference (Biosemi, Amsterdam) at a sampling rate of 512 Hz with 24-bit A/D resolution. Data was FIR filtered to high-pass at 0.5Hz, lowpass at 45Hz. Channel locations were loaded from Biosemi's 'chanlocs128_pist.elp' file. Data was then rereferenced to the linked mastoids. 90s of clean data in the time window 450-540s was selected, and non-EEG channels were discarded. Code for these steps (after loading data to variable 'eeg'):

```
eeg = pop_eegfiltnew(eeg, 'locutoff', 0.5, 'hicutoff', 45);
eeg = ctapeeg_load_chanlocs(eeg, 'file', which('chanlocs128_pist.elp'));
eeg = pop_reref(eeg, get_refchan_inds(eeg, {'EXG7' 'EXG8'}));
eegseg = pop_select(eeg, 'time', [470 650], 'channel', 1:128);
pop_saveset(eegseg, 'filepath', ind, 'filename', '18C_vigilance_EC_clean.set')
```

### References
https://research.uni-leipzig.de/vigall/
Cowley, B., Holmström, É., Juurmaa, K., Kovarskis, L., & Krause, C. M. (2016). Computer Enabled Neuroplasticity Treatment: A Clinical Trial of a Novel Design for Neurofeedback Therapy in Adult ADHD. Frontiers in Human Neuroscience, 10(205). https://doi.org/10.3389/fnhum.2016.00205



# Dataset 4 (download): SCCN eeg_recording_8.bdf

Data is from the database of HeadIT (Human Electrophysiology, Anatomic Data and Integrated Tools Resource), run by the UCSD SCCN lab http://headit.ucsd.edu/studies/9d557882-a236-11e2-9420-0050563f2612

The 8th recording was chosen from this collection, as it was described as the most clean, see here:
http://headit.ucsd.edu/studies/9d557882-a236-11e2-9420-0050563f2612/description

## Experimental Setup
Dataset was recorded from a healthy right-handed male subject, aged 24. Subject listened to auditory tones of short or long duration (200 ms or 400 ms, mixed with equal probability). In 90% of trials these tones were 600 Hz; in the other 10% they were 600 Hz. Subjects were asked to ignore the pitch differences and to respond, by two-choice button press, as to whether the tone was 'long' or 'short'. About 1 s after stimulus onset, visual feedback informed subjects whether their response was correct or not.

### Technical Information

EEG data were collected synchronously from 250 scalp, four infra-ocular, and two electrocardiographic (ECG) electrodes with an active reference (Biosemi, Amsterdam) at a sampling rate of 256 Hz with 24-bit A/D resolution. After download from the server, a CTAP script was used to preprocess (script is included in the CTAP repo as cleanSCCNdata.m). In addition to artefact cleaning steps, the script spatially downsamples to 128 EEG channels.

### References

Onton, J., & Makeig, S. (2009). _High-frequency broadband modulation of electroencephalographic spectra_. Frontiers in Human Neuroscience, 3, 61. http://doi.org/10.3389/neuro.09.061.2009
