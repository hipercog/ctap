function [EEG, Cfg] = CTAP_calc_rt(EEG, Cfg)
%CTAP_calc_rt - calculate the response times between a given target and
%               given response event code
%
% Description:
%   
%
% Syntax:
%   [EEG, Cfg] = CTAP_calc_rt(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.calc_rt:
%   .target     struct, <name, value> pairs define EEG.event field and value
%                       of that field to define the target
%   .response   struct, <name, value> pairs define EEG.event field and value
%                       of that field to define the response
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct updated with used parameter values
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2023 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
% Arg.target = '';

% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'calc_rt')
    Arg = joinstruct(Arg, Cfg.ctap.calc_rt);%override with user params
end


%% ASSIST
if ischar(Arg.response)
    Arg.response = struct('type', Arg.response);
end
if ischar(Arg.target)
    Arg.target = struct('type', Arg.target);
end
%TODO: extend below code to allow one response per defined target-lock evt
if ~(isscalar(Arg.response) && isscalar(Arg.target))
     error('ctapeeg_epoch_data:bad_request'...
        , 'Please request singleton target and response to calculate RTs')
end


%% CORE

% Get Response occurences and latencies
response_event_field = fieldnames(Arg.response);
ref = response_event_field{:};
if ~contains(ref, fieldnames(EEG.event))
    error('ctapeeg_epoch_data:bad_request'...
        , 'EEG.event does not have the requested response field: %s', ref)
end
if isnumeric(Arg.response.(ref))
    rtx = [EEG.event.(ref)] == Arg.response.(ref);
else
    rtx = ismember({EEG.event.(ref)}, Arg.response.(ref));
end
rsplat = [EEG.event(rtx).latency];

% Get target occurences and latencies
target_event_field = fieldnames(Arg.target);
tef = target_event_field{:};
if ~contains(tef, fieldnames(EEG.event))
    error('ctapeeg_epoch_data:bad_request'...
        , 'EEG.event does not have the requested target field: %s', tef)
end
if isnumeric(Arg.target.(tef))
    tgx = [EEG.event.(tef)] == Arg.target.(tef);
else
    tgx = ismember({EEG.event.(tef)}, Arg.target.(tef));
end
trglat = [EEG.event(tgx).latency];

%    TODO: GET DIFF OF TARGET AND RESPONSE EVENTS
RT = rsplat - trglat;


%    TODO: STORE AS FIELD SOMEWHERE? OR MAKE NEW EVENTS?


%% ERROR/REPORT
Cfg.ctap.calc_rt = Arg;

switch Arg.match
    case 'starts'
        desc = 'start with';
    case 'ends'
        desc = 'end with';
    case 'contains'
        desc = 'contain anywhere';
    otherwise %'exact'
        desc = 'exactly match';
end
msg = repmat('SHSH', 1, numel(Arg.evtype));
for ix = 1:numel(Arg.evtype)
    msg = myReport({msg...
        newline ['Events which ' desc ' strings:'] Arg.evtype(ix)...
            newline 'Were aggregated under new label:' Arg.newevs(ix)});
end
myReport(msg, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% CTAP_calc_rt

