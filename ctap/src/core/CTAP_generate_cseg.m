function [EEG, Cfg] = CTAP_generate_cseg(EEG, Cfg)
%CTAP_generate_cseg - Generate calculation segments
%
% Description:
%   Creates events of type Cfg.event.csegEvent into EEG.event to guide PSD
%   estimation.
%
% Syntax:
%   [EEG, Cfg] = CTAP_generate_cseg(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.generate_cseg:
%   .csegEvent      string, Event type string for the events, 
%                   default: 'cseg'
%   .regev          boolean, Create regular events (true) or event-locked events
%                   default: true
%   Depending on value or .regev, other arguments should match:
%       eeg_add_regular_events()
%   OR
%       eeg_tile_locked_evts()
% 
% 
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_add_regular_events()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.csegEvent = 'cseg'; %event type string
Arg.regev = true;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'generate_cseg')
    Arg = joinstruct(Arg, Cfg.ctap.generate_cseg);
end
vargs = struct2varargin(Arg);


%% Add events
if Arg.regev
    EEG = eeg_add_regular_events(EEG, Arg.csegEvent, vargs{:});
else
    EEG = eeg_tile_locked_evts(EEG, Arg.csegEvent, Arg.TILESxEV, Arg.LOCK_EVTS, Arg.END_EVTS);
end
                      
% MAYBEDO: Create a visualization of how the events are located with
% respect to e.g. boundary events and the dataset duration
%{
evmatch = ismember({EEG.event.type}, Arg.csegEvent);
[evc, labs] = struct_to_cell(EEG.event(evmatch));

replabs = {'latency','duration'};
replabsInds = ismember(labs, replabs);
%}


%% ERROR/REPORT
Cfg.ctap.generate_cseg = Arg;
nEvents = sum(ismember({EEG.event.type}, Arg.csegEvent));
msg = myReport(sprintf('%d ''%s'' events addded to EEG.event.',...
               nEvents,Arg.csegEvent), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
