function matrixToMul(filepath, muldata, segname, delim)
%MATRIXTOMUL 
% 
% Description:
%   mul is an ASCII format (columns=channels, rows=samples, header can be 
%   written by using the info in EEG struct). 
%   To export, write channels and samples of EEG.data struct into a text 
%   file, saved with .mul file extension.  
%   Use readBESAmul.m to read a mul sample file for some header info.
% 
% 

if nargin < 4, delim = '\t'; end

[pt, fn, ex] = fileparts(filepath);
pt = strrep(pt, '\', filesep);
if ~strcmpi(strrep(ex, '.', ''), 'mul')
    filepath = fullfile(pt, [fn '.mul']);
end

f = fopen(filepath,'wt+');

header = sprintf(['TimePoints=%i' delim...
                  'Channels=%i' delim...
                  'BeginSweep[ms]=%d' delim...
                  'SamplingInterval[ms]=%d' delim...
                  'Bins/uV=%d' delim...
                  'SegmentName=%s\n']...
                  , muldata.Npts...
                  , size(muldata.data,2)...
                  , muldata.TSB...
                  , muldata.DI...
                  , muldata.Scale...
                  , segname);

fprintf(f, header);

for c = 1:size(muldata.data, 2)
    fprintf(f, ['%s' delim], muldata.ChannelLabels{1, c});
end
fprintf(f, '\n');

for s = 1:size(muldata.data, 1)
    for c = 1:size(muldata.data, 2)
        fprintf(f, ['%f' delim], muldata.data(s, c));
    end
    fprintf(f, '\n');
end
fclose(f);

