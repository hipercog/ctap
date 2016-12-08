function eeglab_writeh5_erp(h5file, EEG)
%eeglab_writeh5_erp - Write epoched EEG data into a HDF5 file for export into R/Python
%
% Description:
%   Use this function to store raw and average epoched EEG data to disk in
%   HDF5 format. HDF5 format is a handy way of sharing data between systems,
%   e.g. to export Matlab data to R or Python.
%
% Syntax:
%   eeglab_writeh5_erp(h5file, EEG)
%
% Inputs:
%   h5file      string, A HDF5 file to save data to
%   EEG         struct, EEGLAB structure with _epoched_ data
%
% Outputs:
%   Saves data to disk
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2016 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% HDF5 file needs to be deleted because:
% 1) datasets cannot be removed and
% 2) differently sized data cannot overwrite existing data
% Hence an existing dataset cannot be easily updated.
if exist(h5file, 'file')
    delete(h5file);
end

% debug:
%keyboard;
%tmp = h5info(h5file, h5p_erpavg)
%tmp = h5info(h5file, h5p_erp)
%tmp = h5info(h5file, '/erp/SEAMPILOT301')
%h5disp(h5file)
%h5readatt(h5file, '/erp')


%% Create file and datasets
% Note: dimensions need to be flipped for the data to appear "correct" in
% other systems (Matlab is an outlier, again...)
h5p_erp = '/erp';
h5create(h5file, h5p_erp,...
        [[size(EEG.data, 3), size(EEG.data, 2)], size(EEG.data,1)] );

h5p_erpavg = '/erpavg';
h5create(h5file, h5p_erpavg,...
        fliplr([size(EEG.data, 1), size(EEG.data, 2)]));

    
%% Write ERP average
% Note: dimensions need to be flipped
h5write(h5file, h5p_erpavg, mean(EEG.data, 3)'); %Note: dimensions need to be transposed
h5writeatt(h5file, h5p_erpavg, 'd1ID', strjoin({EEG.chanlocs.labels}, ';'));
h5writeatt(h5file, h5p_erpavg, 'd2ID', EEG.times);


%% Write single trial ERP
% Note: dimensions need to be flipped
h5write(h5file, h5p_erp, permute(EEG.data, [3,2,1]) ); %Note: dimensions 1 and 2 need to be flipped
%h5write(h5file, h5p_erp, EEG.data); %Note: dimensions 1 and 2 need to be flipped
h5writeatt(h5file, h5p_erp, 'd1ID', strjoin({EEG.chanlocs.labels}, ';'));
h5writeatt(h5file, h5p_erp, 'd2ID', EEG.times);
h5writeatt(h5file, h5p_erp, 'd3ID', 1:size(EEG.data,3));
