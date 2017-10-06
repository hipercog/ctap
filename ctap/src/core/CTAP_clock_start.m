function [EEG, Cfg] = CTAP_clock_start(EEG, Cfg)
%CTAP_clock_start  - starts processing timer
%
% Description:
%   Starts a clock
%
% Syntax:
%   [EEG, Cfg] = CTAP_compute_psd(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: CTAP_clock_stop() %
% Copyright(c) 2017 :
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.clockstart = [];

% Override defaults with user parameters
if isfield(Cfg, 'elapsed')
    Arg = joinstruct(Arg, Cfg.elapsed);
end

%% ERROR/REPORT
res = struct;
res.clockstart = datetime('now');

Arg = joinstruct(Arg, res);
Cfg.elapsed = Arg;

msg = myReport({'Started clock' Arg.clockstart}, Cfg.env.logFile);

EEG = add_CTAP(EEG, Cfg);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);