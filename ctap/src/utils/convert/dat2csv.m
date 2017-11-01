function [Dat] = dat2csv(datfile, varargin)
% DAT2CSV - Convert Neuroscan ERP peak DAT into CSV format
%
% Description:
%   Converts DAT files created using Neuroscan Edit TCL function 
%   PEAKDETECTION_EX into CSV format. 
%   Used as an intermediate step in exporting results from Scan to SPSS or
%   R.
%
% Syntax:
%   [Dat] = dat2csv(datfile, varargin);
%
% Inputs:
%   datfile     string, Full name and path for the DAT file to convert
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, value
%
% Outputs:
%   Dat     struct, CSV data in struct with fields:
%           "data"  cell array, CSV data
%           "info"  struct, related information
%
% Assumptions:
%   Assumes that the sourcefile names in DAT column 'source_file' contain
%   filenames of format <trigger>_<casestr>.avg. May crash if this is not
%   true.
%
% References:
%
% Example: Dat = dat2csv('C:\work\data.dat');
%
% Notes:
%   Based on scan_peaks2spss.m
%
% See also: read_dat
%
% Version History:
% 9.12.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.delimiter = ';';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Define constants
% Conversion specifications for DAT -file peak data
PeakDatConv(1).label = 'source_file';
PeakDatConv(1).format = '%s';
PeakDatConv(2).label = 'sweep_number';
PeakDatConv(2).format = '%1.0f';
PeakDatConv(3).label = 'channel';
PeakDatConv(3).format = '%s';
PeakDatConv(4).label = 'marker';
PeakDatConv(4).format = '%s';
PeakDatConv(5).label = 'latency';
PeakDatConv(5).format = '%1.4f';
PeakDatConv(6).label = 'amplitude';
PeakDatConv(6).format = '%1.5f';

MetaDataConv(1).label = 'trigger';
MetaDataConv(1).format = '%s';
MetaDataConv(2).label = 'casestr';
MetaDataConv(2).format = '%s';


%% Read in DAT data
[data, Info] = read_dat(datfile, 'scan_peakdetect');


%% Parse filenames into metadata
for i=1:numel(data.source_file)
    metadata(i,:) = fnamesplit(data.source_file{i}); 
end


%% Join data
data = horzcat(metadata,struct_to_cell(data)');
DataConv_cell = vertcat(struct_to_cell(MetaDataConv), struct_to_cell(PeakDatConv));


%% Initialize output
Dat.data = data;
Dat.info = Info;


%% Write into file
[pathstr, name, ext, versn] = fileparts(datfile);
savefile = fullfile(pathstr, [name,'.csv']);

cell2txtfile(savefile, DataConv_cell(:,1)', data, DataConv_cell(:,2)',...
                'delimiter', Arg.delimiter);


%% Helper functions
    function splits = fnamesplit(fname)
        
        [start_idx, end_idx, extents, matches, tokens, names, splits] = regexp(fname, '[_.]');
        splits = splits(1:end-1);
    end

end