% Convert UniBonn data
% UNPACK 100 DATA FILES TO SOME VALID DIRECTORY
% GIVE indir=DIRECTORY-NAME AND inpth=PATH-TO-indir
% INTERMEDIATE .mat FILE WILL BE SAVED TO inpth
% OUTPUT DIRECTORY outdir IS SET TO BE SOURCE OF SYNTH-
% GENERATED DATA FILES - SEE param_sweep_setup.m
% -----------------------------------------------

%HERE CONFIGURE param_sweep_setup.m TO GET PATHS & CHANLOCS
branch_name = 'Convert_UniBonn_data';
param_sweep_setup();
outdir = seed_srcdir;
chlocs = chanlocs;

%HERE INSERT COMPLETE PATH TO UNI-BONN DATA PARENT DIR
inpth = '/home/ben/Benslab/CTAP/hydra/SEED_DATA/UniBonn/';

%HERE INSERT DIR FOR 100 UniBonn ASCII .txt FILES, CONDITION A
% indir = 'A-scalp-EO-Z';
%HERE INSERT DIR FOR 100 UniBonn ASCII .txt FILES, CONDITION B
indir = 'B-scalp-EC-O';


%% Run once to concat files
files = dir(fullfile(inpth, indir, '*.txt'));
[dat, r] = sbf_read_file(fullfile(files(1).folder, files(1).name), '%d');
dat = [dat NaN(r, numel(files) - 1)];


for f = 1:numel(files)
    
    dat(:, f) = sbf_read_file(fullfile(files(f).folder, files(f).name), '%d');
    
end

dat = dat';

save([indir 'all'], 'dat');


%% Run to load data for synthing
EEG = pop_importdata('dataformat', 'matlab',...
                     'nbchan', 0,...
                     'data', [indir 'all.mat'],...
                     'setname', strrep(indir, '-scalp', ''),...
                     'srate', 173.61,...
                     'pnts', 0,...
                     'xmin', 0);

chlocs([2:4:48 50:5:128 129:134]) = [];
EEG.chanlocs = chlocs;
                 
EEG = pop_saveset(EEG, 'filename', [indir 'all.set'], 'filepath', outdir);
                 
clear


%% subfunctions
function [data, rows] = sbf_read_file(fname, format)
    fid = fopen(fname);
    data = fscanf(fid, format);
    rows = size(data, 1);
end