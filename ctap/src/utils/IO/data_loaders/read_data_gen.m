function recording = read_data_gen(inputPath, varargin)
%READ_DATA_GEN Wrapper function for reading physiologic recordings.
%
% Important notice: 
%   * CTAP repository contains only EDF reading.
%   * Neurone reading is distributed as an EEGLAB pluging
%     http://www.megaemg.com/support/unrestricted-downloads/
%   * Other file formats are available for FIOH users only
%
% The function reads data of various formats and returns a recording
% structure with the data. The user can specify the recordingType (i.e.
% originating device format), otherwise the function uses various
% heurestics to determine the correct file format.
%
% After the file format has been determined, the function calls a separate
% module for reading the physiologic recording. Each supported device (or
% supported file format) requires an own file reading module.
%
%
% Input:
%       inputPath           : Full path to the input file. Can also be a folder.
%
% Variable input:
%       recordingType       : A string describing the input file format.
%                             Supported recordingTypes:
%                             'neurone'     * Neurone File format
%                             'edf'         * European Data Format (EDF)
%
%       headerOnly           : Boolean indicating if only data header should be read.
%
% Output:
%       recording               : A structure with (at least) the following fields:
%       ---------
%       .signal
%           .<signalName>       : The name of the signal, e.g. 'ECG' or 'Fz'.
%               .data           : Data in the channel.
%               .samplingRate   : Channel sampling rate in Hz.
%       .properties
%           .length             : Length of recording in seconds.
%       .signalTypes            : Cell array of strings with names of all
%                                 channels. These are the same names as found in
%                                 recording.signal.<signalName>.
%       .markers
%           .time               : Time in seconds of marker in recording.
%           .type               : Type of marker in recording (integer codes).
%       .device
%           .type               : String identifying device. E.g. 'Neuroscan' or 'Embla'.
%           .version            : String identifying device version, if applicable.
%           .markerType         : String identifying marker type: either 'Analog' or 'Digital'.
%       .identifier             : String identifying the recording. Always 'FIOH_BWRC'.
%
%   Following fields are optional (for now):
%       .properties
%           .start
%               .unixTime       : Measurement start time in machine
%                                 readable format, unix time in sec from
%                                 1.1.1970
%               .time           : Measurement start time in human readable
%                                 format, yyyymmddTHHMMSS (ISO 8601)
%
% Example:
%               myDataFile = 'c:\data\myData.cnt';
%               recording  = read_data_gen(myDataFile)
%
%               recording  = read_data_gen(myDataFile, 'recordingType', 'neuroscan', 'headerOnly', true)
%
% See also: module_read_embla
%           module_read_neuroscan
%           module_read_ibi
%           module_read_alive
%           module_read_bodyguard
%           module_read_neurone
%           module_read_nonin
%           module_nonin_sync
%           module_read_edf
%           module_read_actiwatch
%           read_neurone_xml
%           triggerStruct2Vector
%
% Author: Andreas Henelius 2009


% General function for data reading


%% Process input arguments
if isempty(varargin)
    disp('No recordingType specified. Trying to guess type.')
    recordingType = '';
end


% Parse input arguments and replace default values if given as input
p = inputParser;
p.addRequired('inputPath', @ischar);

p.addParamValue('headerOnly', false, @islogical);
p.addParamValue('recordingType', '', @isstr);
p.addParamValue('channels', {}, @iscellstr);
p.addParamValue('offset', 0, @isnumeric);
p.addParamValue('dataLength',-1 ,@isnumeric);

% For Embla
p.addParamValue('useEmblaFractionedRate', true, @islogical);


% For Neurone
p.addParamValue('sessionPhaseNumber', 1 ,@isnumeric);

p.parse(inputPath, varargin{:});
Arg = p.Results;

% Set default options
% Default values
% Arg.headerOnly    = false;
% Arg.offset = 0;
% Arg.dataLength = 'entire';




%Arg = input_interp(varargin, Arg, 'useKeyChecking', false);
% Some varargin argumens passed directly to module functions. Thus there
% can exist varargin arguments that have no default value specified.

recordingType     = Arg.recordingType;
headerOnly        = Arg.headerOnly;




%% Prepare for determination if input argument inputPath is a folder or a file.
% Split inputPath into components for easy manipulation later on.
if isdir(inputPath) && ~strcmpi(inputPath, filesep)
    inputPath = [inputPath filesep];
end

[fpath, fname, ext] = fileparts(inputPath);
ext = ext(2:end);

offset     = Arg.offset;
dataLength = Arg.dataLength;


% Assume Embla file format if directory given instead of file name.
if (isempty(ext) && isdir(inputPath))
    % A directory indicates either Embla or NeurOne data.
    % Check if any EBM-files are present
    if ~isempty(dir([inputPath '*.ebm']))
        recordingType = 'ebm';
    end
    
    % Probably NeurOne if we have the two files Protocol.xml and
    % Session.xml in the same directory.
    if (~isempty(dir(fullfile(inputPath,'Protocol.xml')))) && (~isempty(dir(fullfile(inputPath,'Session.xml'))))
        recordingType = 'neurone';
    end
end

% Process input arguments
if isempty(recordingType)
    switch lower(ext)
        case {'edf'}
            recordingType = 'edf';
        otherwise
            error('Unknown input data format. Quitting.')
    end
end

% Process recording type and load data, then return recording structure.
switch lower(recordingType)
        % =======================================================
        % Neurone file (data in binary file with XML descriptors)
        % =======================================================
    case {'neurone'}
        disp('Reading NeurOne data.')
        recording = module_read_neurone(inputPath, varargin{:});
        % =======================================================
        % European Data Format (binary file)
        % =======================================================
    case {'edf'}
        disp('Reading EDF data.')
        recording = module_read_edf(inputPath, 'headerOnly', headerOnly);
        % =======================================================
        % Unknown data format
        % =======================================================
    otherwise
        disp('Unknown data format')
        %=======================================================
end
end
