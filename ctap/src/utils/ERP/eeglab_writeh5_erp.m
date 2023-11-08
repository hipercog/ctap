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
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
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


%% Create file and datasets
[x, y, z] = size(EEG.data);
% Note: dimensions need to be flipped for the data to appear "correct" in
% other systems (Matlab is an outlier, again...)
h5p_erp = '/erp';
h5create(h5file, h5p_erp, [z y x] )

h5p_erpavg = '/erpavg';
h5create(h5file, h5p_erpavg, fliplr([x y]))

    
%% Write ERP average
%Note: dimensions need to be transposed
h5write(h5file, h5p_erpavg, mean(EEG.data, 3)')
h5writeatt(h5file, h5p_erpavg, 'chans', strjoin({EEG.chanlocs.labels}, ';'))
h5writeatt(h5file, h5p_erpavg, 'frames', EEG.times)


%% Write single trial ERP
% Note: dimensions need to be flipped
h5write(h5file, h5p_erp, permute(EEG.data, [3,2,1]) );%Note: flips dims 1+2
h5writeatt(h5file, h5p_erp, 'chans', strjoin({EEG.chanlocs.labels}, ';'))
h5writeatt(h5file, h5p_erp, 'frames', EEG.times)
h5writeatt(h5file, h5p_erp, 'trials', 1:size(EEG.data,3))
%}

%% Write continuous and epoched events using struct2h5()
fileId = H5F.open(h5file, 'H5F_ACC_RDWR', 'H5P_DEFAULT');

% Events structure is regular in 2D so we transform to a table and write by
% columns
evt = struct2table(EEG.event);
vars = evt.Properties.VariableNames;
h5p_evt = '/event';
write_h5_group(fileId, h5p_evt);

for i = 1:width(evt)
    if iscell(evt.(vars{i}))
        write_h5_cellstr(fileId, [h5p_evt '/' vars{i}], evt.(vars{i}))
    else
        write_h5_double(fileId, [h5p_evt '/' vars{i}], evt.(vars{i}))
    end
end

% Epochs structure is irregular but corresponds nicely to epochs, so write
% each one separately
h5p_epc = '/epoch';
write_h5_group(fileId, h5p_epc);

idx = num2padstr(1:size(EEG.data, 3));
for i = 1:size(EEG.data, 3)
    write_h5_group(fileId, [h5p_epc '/' idx{i}])
    struct2h5(h5file, EEG.epoch(i)...
        , 'groupPath', [h5p_epc '/' idx{i}] ...
        , 'dsetname', idx{i})
end

H5F.close(fileId)
%}
