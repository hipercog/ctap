function block_structure = parse_blocks(MC, casename)
% PARSE_BLOCKS - Parse block information given in the MC
%
% Description: 
% A block is defined in the block-sheet of the MC using the following syntax.
%
%     casename | blockid | starttype | starttime | stoptype | stoptime | factor1 | factor2
% 
%     casename  : a casename in the MC
%     blockid   : an integer enumerating the block (one casename can have one or more blocks)
%     starttype : one of the following:
%                 time
%                      the block start/stop point is defined as the instant in time
%                      calculated from the beginning of the recording or from the
%                      zerotime (if provided).
%                 timestamp
%                      the block start/stop point is defined as an exact instant in time
%                      using ISO-8601, e.g. 20141011T113300
%                 marker
%                      the block start/stop point is defined as the instant in time when
%                      the marker with code was sent to the recording device. The time
%                      instant of the marker code is adjusted  with respect to the zerotime,
%                      if provided.
% 
%    starttime : must be matched with the starttype, and must be one of the following:
%                 starttype = time
%                       an integer representing second
%                 starttype = timestamp
%                       a string giving a timestamp in ISO-8601, e.g. 20141011T113300
%                 starttype = marker
%                       a string in the format "code_order", where code is, e.g., an eight-bit
%                       marker from a measurement device. Order designates the occurrence order
%                       of the marker, i.e., '123_2' means the second instance of the code 123 etc.
%                       The shorthand '123' can be used to represent '123_1'.
%     stoptype : see starttype
%     stoptime : see starttime
%     factors  : A string factor describing the block, e.g. "tasktype" etc.
%                The number of factors (strings after stoptime) is unlimited.
%
% Syntax:
%   MC = parse_blocks(MC, casename)
%
% Inputs:
%   MC          A struct containing the measurement configuration
%   casename    A string giving a casename found in the MC
%
% Outputs:
%   blocks      A struct containing the following fields:
%                .limits_time   : block start and stop times (in seconds)
%                .limits_sample : block start and stop times (in samples)
%                .factors       : factors associated with the block
%                .factorlabels  : labels for the factors
%
% See also:
%           read_measinfo_spreadsheet, event_to_time, marker_to_time
%
% Author: Andreas Henelius (FIOH, 2014)
% -------------------------------------------------------------------------

% =========================================================================
% Filter the blocks and measurement based on the casename
% =========================================================================
if ~(sum(strcmpi('blocks', fieldnames(MC))))
    error('No blocks in measurement configuration.')
end

% Get the blocks
mc_filter.casename = casename;
blocks  = struct_filter(MC.blocks, mc_filter);
nblocks = numel(blocks);

if (nblocks == 0)
    error('Casename not found in blocks.')
end

% Get the measurement
if ~(sum(strcmpi('measurement', fieldnames(MC))))
    error('No measurement in measurement configuration.')
end

measurement = struct_filter(MC.measurement, mc_filter);

if (numel(measurement) > 1)
    error('Casename not unique in measurements.')
end

% =========================================================================
% Get information regarding the physiologic recording
% =========================================================================

recording =  read_data_gen(measurement.physiodata, 'headerOnly', true);

% =========================================================================
% Determine the zerotime, if possible
% =========================================================================

if ~(sum(strcmpi('events', fieldnames(MC))))
    warning('No events in measurement configuration. Using 0 as the zerotime.')
    events = [];
else
    mc_filter.eventname = 'zerotime';
    events = struct_filter(MC.events, mc_filter);
end

if numel(events) == 0
    warning('No zerotime event specified. Using 0 as the zerotime.')
    zerotime = 0;
else
    [zerotime, zerosample] = ...
        event_to_time(events.eventtype, events.timestamp, 0, recording);
end

% =========================================================================
% Container for block limits
% =========================================================================
% Determine the factor labels
required_fields = {'casename', 'starttype', 'starttime', 'stoptype', 'stoptime'};
factorlabels    = setdiff(fieldnames(blocks), required_fields);
nfactors        = numel(factorlabels);

blocklimits_time    = zeros(nblocks, 2);
blocklimits_samples = zeros(nblocks, 2);
factors             = cell(nblocks, nfactors);

% =========================================================================
% Parse the events
% =========================================================================

for i = 1:nblocks
    block_record = blocks(i);
    
    % Unpack the block data record
    starttype    = block_record.starttype;
    startmark    = block_record.starttime;
    startmarkraw = block_record.starttime;
    stoptype     = block_record.stoptype;
    stopmark     = block_record.stoptime;
    stopmarkraw  = block_record.stoptime;
    
    % Factors
    for j = 1:nfactors
        factors{i, j} = block_record.(factorlabels{j});
    end
    
    % Start and stop times of the blocks
    [start_time, start_sample] = ...
        event_to_time(starttype, startmark, zerotime, recording);
    [stop_time, stop_sample] = ...
        event_to_time(stoptype, stopmark, zerotime, recording);
    
    % Check that starttime/sampe is smaller than stoptime/sample
    if (start_time < stop_time) && (start_sample < stop_sample)
        blocklimits_time(i, 1)   = start_time;
        blocklimits_sample(i, 1) = start_sample;
        
        blocklimits_time(i, 2)   = stop_time;
        blocklimits_sample(i, 2) = stop_sample;
    else
        disp 'ERROR : stoptime cannot be smaller than starttime.'
        round([start_time , stop_time])
    end
    
end

% Return the block structure
block_structure.limits_time   = blocklimits_time;
block_structure.limits_sample = blocklimits_sample;
block_structure.factors       = factors;
block_structure.factorlabels  = factorlabels;

end
% -------------------------------------------------------------------------
