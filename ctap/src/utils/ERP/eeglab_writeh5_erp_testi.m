function eeglab_writeh5_erp_testi(h5file, EEG)
% todo: test that the data storing goes right: read data into R/Python and
% plot

h5p_erpavg = sprintf('/erpavg/%s', EEG.CTAP.subject.subject);
h5p_erp = sprintf('/erp/%s', EEG.CTAP.subject.subject);

%keyboard;
%tmp = h5info(h5file, h5p_erpavg)
%tmp = h5info(h5file, h5p_erp)
%tmp = h5info(h5file, '/erp/SEAMPILOT301')
%h5disp(h5file)
%h5readatt(h5file, '/erp')
    

% create hdf5 file

% Note: dimensions need to be flipped
%keyboard
try
    h5create(h5file, h5p_erpavg,...
        fliplr([size(EEG.data, 1), size(EEG.data, 2)]));
catch
    disp(lasterr);
end

try
    h5create(h5file, h5p_erp,...
        [[size(EEG.data, 3), size(EEG.data, 2)], size(EEG.data,1)] );
catch
    disp(lasterr);
end

    
    
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

