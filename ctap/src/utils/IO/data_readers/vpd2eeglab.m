function [EEG, date] = vpd2eeglab(VPD, varargin)
% VPD2EEGLAB converts data imported from a .vpd file to an EEGLAB struct
%
% Description:
%
% Syntax:
%   [EEG, date] = vpd2eeglab( VPD )
%
% Inputs:
%   'VPD'           struct, data from the Varioport psychophysiological
%                   recording system, to be converted to EEGLAB structure
% 
% Varargin
%   'events'        struct [m n], m events with n fields:
%                                 'name'
%                                 'time' in seconds
%
% Outputs:
%   'EEG'           struct, converted EEG structure
%   'date'          string, vpd recording date and time
%
%
% Notes: 
%
% See also: ImportVPD
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

p.addRequired('VPD', @isstruct)

p.addParameter('events', struct(), @isstruct)

p.parse(VPD, varargin{:});
Arg = p.Results;


%% BUILD EEG
[~, EEG, ~] = pop_newset([], [], 1, 'gui', 'off');

chidx = contains(VPD.channels(:, 1), 'EEG');

EEG.srate = mean([VPD.chn(1, chidx).sr]);

numch = sum(chidx);
EEG.nbchan = numch;
EEG.trials = 1;
EEG.pnts = length(VPD.chn(1, find(chidx, 1, 'first')).signal);
EEG.data = [VPD.chn(1, chidx).signal];
[r, c] = size(EEG.data);
if r == EEG.pnts
    EEG.data = EEG.data';
    [r, c] = size(EEG.data);
end
if r ~= numch || c ~= EEG.pnts
    warning('**** Something has gone wrong! ****'); %#ok<WNTAG>
end
date = [VPD.mdate ' ' VPD.mtime];


%% COPY EVENTS TO EEG
if ~isempty(fieldnames(Arg.events))
    VPD.events = Arg.events;
end

EEG.event = VPD.events;
[EEG.event.type] = VPD.events.name;
EEG.event = rmfield(EEG.event, 'name');
for i = 1:numel(VPD.events)
    VPD.events(i).time = VPD.events(i).time * EEG.srate; 
end
[EEG.event.latency] = VPD.events.time;
EEG.event = rmfield(EEG.event, 'time');

end % vpd2eeglab
