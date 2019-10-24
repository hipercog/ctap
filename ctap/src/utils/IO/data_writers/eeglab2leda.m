function leda = eeglab2leda(EEG, varargin)
%EEGLAB2LEDA - convert a given EEGLAB structure to Ledalab-readable format
%
% Description:
%   returns a struct which can be saved as a .mat file for direct import to
%   Ledalab. EEGALB '.data' field should be a single vector of EDA data
%
% Syntax:
%   leda = eeglab2leda(EEG, varargin)
%
% Inputs:
%   'EEG'       struct, EEGLAB structure
% 
% varargin      Keyword-value pairs
%   'chan'      scalar, channel index to extract as EDA
%   'evnames'   cell array, fieldnames of EEG.event struct fields to include 
%               in Leda events
%               default = {}
%   'udefnames' cell array, m names for m fields udefvals to add as events
%               default = {}
%   'udefvals'  cell array, {1:m, 1:n} m fields x n values to add as events
%               default = {}
%   
% Outputs:
%   leda        Matlab struct readable by Ledalab with fields:
%       .conductance    vector of EDA potentials
%       .time           vector of timestamps per index of 'conductance'
%       .event
%           .time       
%           .name
%           .nid
%
%
% See also:  Ledalab
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);

p.addParameter('chan', 1, @isscalar);
p.addParameter('evnames', {}, @iscell);
p.addParameter('udefnames', {}, @iscell);
p.addParameter('udefvals', {}, @iscell);

p.parse(EEG, varargin{:});
Arg = p.Results;

if Arg.chan < 1 || Arg.chan > EEG.nbchan
    error('Badly chosen channel index. Aborting');
end


%% Leda struct building
leda.conductance = EEG.data(Arg.chan,:);
fprintf('Exporting channel #%d, chanlocs label: %s, to Ledalab format.'...
    , Arg.chan, EEG.chanlocs(Arg.chan).labels);

jump = (EEG.xmax-EEG.xmin)/(EEG.pnts-1);
leda.time = EEG.xmin:jump:EEG.xmax;

leda.timeoff = 0;

leda.event = struct(...
    'time', num2cell(leda.time(round([EEG.event.latency]))),...
    'name', {EEG.event.type},...
    'nid', {EEG.event.urevent});


%% add user-defined event fields from EEG.event struct
leda.event = add_dyn_fields(EEG.event, leda.event, Arg.evnames);


%% add user-defined event fields from udefnames & udefvals
if ~isempty(Arg.udefnames) && ~isempty(Arg.udefvals)
    % loop given event fields, adding to leda.event
    for i = numel(Arg.udefnames)
        leda.event.(Arg.udefnames{i}) = Arg.udefvals{i};
    end
end


%% MAYBEDO (BEN) LEGACY CODE FOR WCST
% cellfun(@strcat, {EEG.event.globalstim}, {EEG.event.localstim}, 'UniformOutput', false);
