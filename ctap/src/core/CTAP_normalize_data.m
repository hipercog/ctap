function [EEG, Cfg] = CTAP_normalize_data(EEG, Cfg)
%CTAP_normalize_data - Center and scale EEG data
%
% Description:
%   Centers channel data (sets mean to zero) or scales them to unit std().
%   Apply this function after CTAP_detect_*() functions or other functions
%   that are dependent on certain voltage levels.
%
% Syntax:
%   [EEG, Cfg] = CTAP_normalize_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.normalize_data:
%       .center    logical, Apply centering?, default: true
%       .scale     logical, Apply scaling?, default: true
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.center = true;
Arg.scale = true;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'normalize_data')
    Arg = joinstruct(Arg, Cfg.ctap.normalize_data);
end

%% CORE
centerStr = 'false';
if Arg.center
   EEG = pop_rmbase(EEG,[],[]);
   centerStr = 'true';
end

scaleStr = 'false';
if Arg.scale
    sdArr = std(EEG.data, 0, 2);
    sdMat = repmat(sdArr, 1, size(EEG.data,2));
    EEG.data = EEG.data ./ sdMat;
    scaleStr = 'true';
end

%% ERROR/REPORT
Cfg.ctap.normalize_data = Arg;

msg = myReport(sprintf('Normalized data with center=%s and scale=%s.',...
    centerStr, scaleStr), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
