function [EEG, Cfg] = CTAP_load_events(EEG, Cfg)
% CTAP_load_events - Load events into EEG
clc%
% Description:
%   Loads events from MC.measurementLog into EEG.
%   Cfg.measurement.measurementlog (created by looper) is used as the log
%   file.
%
% Syntax:
%   [EEG, Cfg] = CTAP_load_events(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_events:
%   .method     string, Loading method, allowed values
%               {'handle','presentation','importevent'},
%               For .method='handle' also field .handle is needed.
%               default: 'importevent'     
%   .handle     function handle, Function handle to a custom function to 
%               load events with, function should be of type 
%               [EEG, ~] = function(EEG, eventfile)
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: Cfg.ctap.load_events.handle()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.method = 'importevent';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_events')
    Arg = joinstruct(Arg, Cfg.ctap.load_events);
end

%% ASSIST
src = Cfg.measurement.measurementlog;

%% CORE
switch Arg.method
    case 'handle'
        EEG = Arg.handle(EEG, src);
        
    case 'presentation'
        EEG = pop_importpres(EEG, src);
        
    case 'importevent'
        EEG.event = importevent(src, EEG.event, EEG.srate);
        
    otherwise
        error('CTAP_load_events:badMethod',...
            'Unknown method ''%s''. Cannot process.', Arg.method);
end

%% ERROR/REPORT
Cfg.ctap.load_events = Arg;

msg = myReport({'Edited events for ' EEG.subject '_' EEG.setname}...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
