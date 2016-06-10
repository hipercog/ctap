function data = read_edf(fname)
% Example: data = read_edf('N:\Projects\HyvaTerveys\Rawdata\ActiWave\akoi_01R0120090825.edf')
f = fopen(fname, 'rb');

% Read EDF header
header.main = fread(f, 256, 'uchar');

% Read number of signals in EDF-file
nSignals = str2num(strtrim(char(header.main(end-8:end))'));

% Read signal headers
for i=1:nSignals
    header.(['sig_' num2str(i)]) = fread(f, 256, 'uchar');
end

% Get sampling rates of the channels
samplingRate = str2num(char(header.(['sig_' num2str(nSignals)])'));

% Read all data
data_tmp = fread(f, [sum(samplingRate) inf], 'int16=>int16');

% Get channel names and read data
%keyboard
startPos = 0;
stepSize = 0;
j = 1;
for i=1:16:16*numel(samplingRate)
    stepSize = stepSize + samplingRate(j);
    tmp = data_tmp((1+startPos):stepSize, :);
    data.(strrep(strtrim(char(header.sig_1(i:i+15))'),' ', '_')) = tmp(:);
    startPos = startPos + samplingRate(j);
    j = j+1;
end
end