function leda = recording_neurone_to_leda(recording, chan)
%RECORDING_NEURONE_TO_LEDA - convert a neurOne recording EDA/GSR channel to
%   Ledalab-readable format
%
% Description:
%   returns a struct which can be saved as a .mat file for direct import to
%   Ledalab. Should be passed a single vector of EDA data, or index 'chan'
%
% Syntax:
%   leda = recording_neurone_to_leda(recording, chan)
%
% Inputs:
%   recording   neurOne data structure
%   chan        scalar - channel index of GSR/EDA
%   
% Outputs:
%   leda        Matlab struct readable by Ledalab with fields:
%       .conductance     vector of EDA potentials
%       .time            vector of timestamps per index of 'conductance'
%       .event
%           .time
%           .name
%           .nid
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also:  
%
% Copyright 2014- Benjamin Cowley, FIOH, benjamin.cowley@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<2
    chan = 1;
end

if ~isscalar(chan) || chan<1 || chan>numel(recording.signalTypes)
    error('Badly chosen channel index. Aborting');
end

leda.conductance = recording.signal.(recording.signalTypes{chan}).data';
disp(['Selecting channel #' num2str(chan)...
        ', signalTypes label: ' recording.signalTypes{chan}]);

jump = recording.properties.length/(numel(leda.conductance)-1);
leda.time = 0:jump:recording.properties.length;

leda.timeoff = 0;

leda.event = struct(...
    'time', num2cell(recording.markers.time)',...
    'name', num2cell(recording.markers.code)',...
    'nid', num2cell(1:numel(recording.markers.type)));
