function [EEG, Cfg] = CTAP_load_events(EEG, Cfg)
% CTAP_load_events - Load events into EEG
%
% Description:
%   Loads events from a given source into EEG.
%   Source can be:
%       a file, read automagically from measurement info spreadsheet into 
%               ''Cfg.measurement.measurementlog''
%       a folder, where exists a log file with name matching the EEG file
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
%               [EEG, ~] = function(EEG, eventfile, varargin)
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
% Please see the file LICENSE for details.be given as 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.method = 'importevent';
if isfield(Cfg.measurement, 'measurementlog')
    Arg.src = Cfg.measurement.measurementlog;
end
Arg.src_ext = 'log';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_events')
    Arg = joinstruct(Arg, Cfg.ctap.load_events);
end


%% ASSIST
errmsg = 'Log file is needed to load events';
if ~isfield(Arg, 'src')
    error('CTAP_load_events:no_log', '%s :: No source given', errmsg)
elseif isfolder(Arg.src)
    exts = {'log', 'txt', Arg.src_ext};
    % Find events from directory = filename containing subject number
    Arg.src = find_filematch_bynum(Cfg.measurement.subject, Arg.src, exts);
    % If numeric matching failed = filename closest matching to EEG filename
    if isempty(Arg.src)
        Arg.src = find_closest_file(Cfg.measurement.physiodata, Arg.src, exts);
    end
elseif ischar(Arg.src) && ~exist(Arg.src, 'file') == 2
    error('CTAP_load_events:no_log', '%s :: Bad filename or not a file', errmsg)
end


%% CORE
switch Arg.method
    case 'handle'
        EEG = Arg.handle(EEG, Arg.src, rmfield(Arg, {'method' 'src'}));
        
    case 'presentation'
        EEG = pop_importpres(EEG, Arg.src);
        
    case 'importevent'
        EEG.event = importevent(Arg.src, EEG.event, EEG.srate);
        
    otherwise
        error('CTAP_load_events:badMethod',...
            'Unknown method ''%s''. Cannot process.', Arg.method);
end

%% ERROR/REPORT
Cfg.ctap.load_events = Arg;

msg = myReport({'Edited events for ' EEG.subject '_' EEG.setname}...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
