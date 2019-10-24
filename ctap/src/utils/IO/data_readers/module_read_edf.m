function recording = module_read_edf(fname, varargin)
%MODULE_READ_EDF Read EDF file format and return recording structure.
%
% Input:
%   fname       : Path to EDF file.
%
% Variable input:
%                 headerOnly : Boolean indicating if only data header should be read.
%                              Defaults to false.
%
% Output        : A recording structure.
%
% For a description of the recording structure, see read_data_gen.
%
% Example:
%               myDataFile = 'c:\nonindata\test.edf';
%               recording  = read_data_gen(myDataFile);
%
% See also: read_data_gen
%
% Author: Andreas Henelius 2009

% Set default options
Arg.headerOnly = false;

% Parse input arguments and replace default values if given as input
Arg = parseargs(Arg, varargin{:});

% Initialise empty recording structure
% recording = new_recording();
recording = {};

% Open file and data
f = fopen(fname, 'rb');

% Get file size and calculate chunk sizes and factors
fseek(f,0,'eof');
fSize = ftell(f);
frewind(f);

CHUNKFACTOR = 50;
chunkSize = fSize / 2 / CHUNKFACTOR;


% Read global EDF header
header.global = fread(f, 256, 'uchar');

if ~(Arg.headerOnly)
    % Read number of signals in EDF-file
    nSignals = str2num(strtrim(char(header.global(253:256)')));
    
    % Read signal headers
    for i=1:nSignals
        header.(['sig_' num2str(i)]) = fread(f, 256, 'uchar');
    end
    
    % Get sampling rates of the channels
    samplingRate = str2num(char(header.(['sig_' num2str(nSignals)])'));

    % Initialise progress bar
    nRows = fSize/sum(samplingRate)/2+sum(samplingRate);
    progBar = progressBar(nRows);

    % Read all data at once
    % data_tmp = fread(f, [sum(samplingRate) inf], 'int16=>int16');
    %data_tmp_all = fread(f, [sum(samplingRate) inf], 'int16'); % if we want doubles

    % Alternatively; read all data, but in chunks:
    i = 0;
    data_tmp = [];
    while ~feof(f)
        data_tmp_chunk = fread(f, [sum(samplingRate) nRows/10], 'int16');
        data_tmp = horzcat(data_tmp, data_tmp_chunk);
        i = i+(nRows/10);
        progBar(i)
    end
    % Get channel names and read data
    startPos = 0;
    stepSize = 0;
    j = 1;
    for i=1:16:16*numel(samplingRate)
        signalName = strrep(strtrim(char(header.sig_1(i:i+15))'),' ', '_');
        signalName = labelFixer(signalName);
        stepSize = stepSize + samplingRate(j);
        tmp      = data_tmp((1+startPos):stepSize, :);
        
        recording.signal.(signalName).data = tmp(:);
        recording.signal.(signalName).samplingRate = samplingRate(j);
        startPos = startPos + samplingRate(j);
        j = j+1;
    end
    
    % Create labels for easy viewing
    recording.signalTypes = fieldnames(recording.signal);
    
    % Store signal length
    %recording.properties.length = numel(recording.signal.(recording.signalTypes{1}).data) / (recording.signal.(recording.signalTypes{1}).samplingRate);
    recording.properties.length = str2num(strtrim(char(header.global(245:252)')))*str2num(strtrim(char(header.global(237:244)')));
end

startDate = strtrim(char(header.global(169:176)'));
startTime = strtrim(char(header.global(177:184)'));

% Subject information
subject = strrep(strtrim(char(header.global(9:12)')),' ', '_');

% Timing information
recording.properties.start.time     = datestr(datenum([startDate ':' startTime], 'dd.mm.yy:HH.MM.SS'),30);
recording.properties.start.unixTime = datenum2unixtime(datenum(recording.properties.start.time, 'yyyymmddTHHMMSS'));
recording.properties.subject        = subject;


% Original data
%recording.sourceData = d;

local_rec_info = strread(strtrim(char(header.global(89:168)')), '%s', 'delimiter', ' ');
% Read local recording information
% AH -- possible bugfix: changed the out-commented codeblock to a simpler
% version
%{
device_tmp = '';
for i=5:numel(local_rec_info)
    device_tmp = [device_tmp local_rec_info{i}];
end
%}
device_tmp = local_rec_info{5};

% Device information
%recording.device.type       = str2num(strtrim(char(header.global(1:8)')));
recording.device.type       = device_tmp(1:8)
recording.device.version    = device_tmp;
recording.device.markerType = '';

% Set structure identifier
recording.identifier = 'FIOH_BWRC';

end

% =========================================================================
% EDF header information
% =========================================================================
% start     stop	 format     description
% ------------------------------------------
% 1     	8       ascii       version of this data format (0)
% 9     	88      ascii        local patient identification (mind item 3 of the additional EDF+ specs)
% 89    	168     ascii        local recording identification (mind item 4 of the additional EDF+ specs)
% 169       176     ascii        startdate of recording (dd.mm.yy) (mind item 2 of the additional EDF+ specs)
% 177   	184     ascii        starttime of recording (hh.mm.ss)
% 185       192     ascii       number of bytes in header record
% 193       236     ascii       reserved
% 237       244     ascii       number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)
% 245       252     ascii       duration of a data record, in seconds
% 253       256     ascii       number of signals (ns) in data record
%
% http://www.edfplus.info/specs/edfplus.html#header
% http://www.edfplus.info/specs/edfplus.html#additionalspecs
% =========================================================================
