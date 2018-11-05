function matrixToMul(filepath, muldata, segname)
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

f = fopen(filepath,'wt+');

header = sprintf(['TimePoints=%i\t'...
                  'Channels=%i\t'...
                  'BeginSweep[ms]=%d\t'...
                  'SamplingInterval[ms]=%d\t'...
                  'Bins/uV=%d\t'...
                  'SegmentName=%s\n']...
                  , muldata.Npts...
                  , size(muldata.data,2)...
                  , muldata.TSB...
                  , muldata.DI...
                  , muldata.Scale...
                  , segname);

fprintf(f, header);

for c = 1:size(muldata.data, 2)
    fprintf(f, '%s\t', muldata.ChannelLabels{1, c});
end
fprintf(f, '\n');

for s = 1:size(muldata.data, 1)
    for c = 1:size(muldata.data, 2)
        fprintf(f, '%d\t', muldata.data(s, c));
    end
    fprintf(f, '\n');
end
fclose(f);

