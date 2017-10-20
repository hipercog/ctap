function markers = module_read_neurone_events(basePath, samplingRate)
%MODULE_READ_NEURONE_EVENTS   Read events from Mega NeurOne.
%
%  Inputs
%         basePath     : Path to directory containing NeurOne data files
%                        from one measurement.
%         samplingRate : Sampling frequency of the measurement to
%                        calculate occurence times of events.
%
%  Output
%         markers      : A structure containing event types, data indices
%                        and occurence times.
%
%  Dependencies: none
%
%  Module_read_neurone_events is part of NeurOne Tools for Matlab.
%
%  The NeurOne Tools for Matlab consists of the functions:
%       module_read_neurone.m, module_read_neurone_data.m,
%       module_read_neurone_events.m, module_read_neurone_xml.m
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2009 - 2013
%  Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  and
%  Mega Electronics Ltd (mega@megaemg.com, http://www.megaemg.com)
%  ========================================================================
%  This file is part of NeurOne Tools for Matlab.
% 
%  NeurOne Tools for Matlab is free software: you can redistribute it
%  and/or modify it under the terms of the GNU General Public License as
%  published by the Free Software Foundation, either version 3 of the
%  License, or (at your option) any later version.
%
%  NeurOne Tools for Matlab is distributed in the hope that it will be
%  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with NeurOne Tools for Matlab.
%  If not, see <http://www.gnu.org/licenses/>.
%  ========================================================================
%  Version x.y.z.k (08.03.2013)
%  See version_history.txt for details.
%  ========================================================================

%% Events are stored in three files:
% (1) events.bin
% (2) eventData.bin
% (3) eventDescriptions.bin

% Define files
EVENTSFILE            = [basePath filesep 'events.bin'];
EVENTDATAFILE         = [basePath filesep 'eventData.bin'];
EVENTDESCRIPTIONSFILE = [basePath filesep 'eventDescriptions.bin'];

%% Read events.bin
% Each event is stored in an 88-byte struct, so we read the data in
% chunks of 88 bytes.

% Get number of events
tmp = dir(EVENTSFILE);
nEvents = tmp.bytes / 88;

% Empty structure for event data
markers.type  = cell(nEvents, 1);
markers.index = NaN(nEvents, 1);
markers.time  = NaN(nEvents, 1);
markers.code  = NaN(nEvents, 1);

% Read events.bin
fileIdEvents = fopen(EVENTSFILE, 'rb');
for k = 1:nEvents
    % Read the whole event structure
    Revision          = fread(fileIdEvents, 1, 'int32');
    RFU               = fread(fileIdEvents, 1, 'int32');
    Type              = fread(fileIdEvents, 1, 'int32');
    SourcePort        = fread(fileIdEvents, 1, 'int32');
    ChannelNumber     = fread(fileIdEvents, 1, 'int32');
    Code              = fread(fileIdEvents, 1, 'int32');
    StartSampleIndex  = fread(fileIdEvents, 1, 'uint64');
    StopSampleIndex   = fread(fileIdEvents, 1, 'uint64');
    DescriptionLength = fread(fileIdEvents, 1, 'uint64');
    DescriptionOffset = fread(fileIdEvents, 1, 'uint64');
    DataLength        = fread(fileIdEvents, 1, 'uint64');
    DataOffset        = fread(fileIdEvents, 1, 'uint64');
    RFU               = fread(fileIdEvents, 1, 'int32');
    RFU               = fread(fileIdEvents, 1, 'int32');
    RFU               = fread(fileIdEvents, 1, 'int32');
    RFU               = fread(fileIdEvents, 1, 'int32');
    
    % Check if the data format has changed
    if Revision > 2
        error(strcat('This reader does not support the revision of events.bin (', ...
            num2str(Revision), '). Please contact mega@megaemg.com for an update.'))
    end
    
  
    % Determine the source port
    switch SourcePort
        case 0
            SourcePort = 'Unknown';
        case 1
            SourcePort = 'A';
        case 2
            SourcePort = 'B';
        case 3
            SourcePort = 'EightBit';
    end
    
    % Determine the event type
    switch Type
        case 0
            Type = [SourcePort ' - Unknown'];
            Code = 0;
        case 1
            Type = [SourcePort ' - Stimulation'];
            Code = 256;
        case 2
            Type = [SourcePort ' - Video'];
            Code = 257;
        case 3
            Type = [SourcePort ' - Mute'];
            Code = 258;
        case 4
            Type = num2str(Code);
            % Code is 1...255 and is equal to the Type
            Code = str2num(Type);
            
        case 5
            Type = [SourcePort '_Out' ];
            Code = 259;
        case 6
            % User-entered comments are read from eventData.bin
            fileIdEventData = fopen(EVENTDATAFILE, 'rb');
            offset = DataOffset / 2;
            length = DataLength / 2;
            comments = fread(fileIdEventData, [1 offset], 'int16');
            comments = fread(fileIdEventData, [1 length], 'int16');
            Type = char(comments);
            Code = 260;
            fclose(fileIdEventData);
    end
    
   
    % Store the event data
    markers.type(k,1)  = cellstr(Type);
    markers.index(k,1) = StartSampleIndex;
    markers.time(k,1)  = StartSampleIndex / samplingRate;
    markers.code(k,1)  = Code;
    
end

fclose(fileIdEvents);

end % end of module_read_neurone_events.m
