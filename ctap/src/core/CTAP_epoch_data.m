function [EEG, Cfg] = CTAP_epoch_data(EEG, Cfg)
%CTAP_epoch_data - Create epochs from events in the dataset
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_epoch_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.epoch_data:
%       .match  string, controls how to match 'evtype' strings to EEG events:
%                       'exact' (default) match complete string
%                       'starts' match if evtype begins the event label
%                       'contains' match if evtype occurs anywhere in event
%                       'ends' match if evtype ends the event label
%       Other fields and their content should match the varargins of
%       ctapeeg_epoch_data().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
%
% Notes: 
%
% See also: ctapeeg_epoch_data
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.match = 'exact';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'epoch_data')
    Arg = joinstruct(Arg, Cfg.ctap.epoch_data); %override with user params
end


%% ASSIST
evlist = eeglab_validate_evlist(EEG, Arg.evtype, Arg.match);
if isempty(evlist)
    myReport(['FAIL evtype not found: ' Arg.evtype], Cfg.env.logFile);
else
    Arg.evtype = evlist;
end


%% CORE
[EEG, params, result] = ctapeeg_epoch_data(EEG, Arg);

EEG.CTAP.badepochs.events = result;


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.epoch_data = params;


if strcmp(Arg.method, 'depoc')
    msg = myReport(sprintf('Transformed Epoched dataset to Continuous for %s',...
        EEG.setname), Cfg.env.logFile);
else
    msg = myReport(sprintf('Epoched with %s data from: %s'...
        , Arg.method, EEG.setname), Cfg.env.logFile);
end

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, params);
