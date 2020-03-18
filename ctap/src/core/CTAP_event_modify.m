function [EEG, Cfg] = CTAP_event_modify(EEG, Cfg)
%CTAP_event_modify - A function to modify event codes based on their position in event sequence
%
% Description:
%   Inspects the "EEG.event.type" field of an EEG struct and identifies which 
%   target stimuli (TS) have a matching response (correct or incorrect) and
%   which do not. Modifies each TS according to response type: correct,
%   incorrect, not answered. (Computes also reaction times for correctly 
%   responded stimuli.)
%
%   Event modification has been divided accross several m-files. This m-file 
%   acts as the main source of documentation.
%   Event codes that do not belong to set unique(horzcat(stim, cresp,
%   fresp, noresp)) will be discarded (removed temporarily prior to
%   event modification).
%
%   A matching response is an event for which:
%       1.  Event code equals to one of the codes in 'stim'
%       2.  Response code {'cresp','fresp','noresp'} follows 'stim'
%           before next 'stim'
%   
%   Response classes (as defined by classify_events.m):
%       correct response: stim{i} is followed by cresp{i}
%       incorrect response: stim{i} is followed by fresp{i} or cresp{j}
%                           where j ~= i
%       no response: stim{i} is followd by noresp{i}
%       error: stim{i} does not fall into any of the other classes
%
%   This function performs the following modifications to the event data:
%       In case of...
%       1. ... correct response stim{i} is changed to cstim{i}
%       2. ... incorrect response stim{i} is changed to icstim{i}
%       3. ... no response stim{i} is changed to nrstim{i}
%       Reaction times are calculated for all answered stimuli. 
%       Reaction times are stored in EEG.event.rt and they are expressed in 
%       seconds. For not responded stimuli the value "NaN" is used.
%
%   The event code modification logic used in this function (and in the
%   ones called from it) does not support the modification of several
%   successive target stimuli with single common response event. Hence
%   e.g. in some operation span tasks event modification has to be made
%   separately for each target stimulus. 
%
%   It is good practice to check stimulus modification results by directly
%   inspecting the stimulus sequence.
%
% Syntax:
%   [EEG, Cfg] = CTAP_event_modify(EEG, Cfg));
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct should be updated with parameter values
%                       actually used
%
% Notes: 
%
% See also: mark_resp2stim.m, analyze_events.m, classify_events.m  
%
% Copyright(c) 2016 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test if the function can be run?
if verLessThan('matlab', '9.1')
   error('matlabVersionError',...
        ['Matlab versions older than 9.1 (R2016b) break CTAP_event_modify():'...
        ' all events get the same (wrong) class.']);  %#ok<CTPCT>
end


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
Arg.channels = {EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels};
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'event_modify')
    Arg = joinstruct(Arg, Cfg.ctap.event_modify);%override with user params
end


%% CORE Call the desired core function. The default is hard-coded, but if
%   the author wants, he can set the wrapper to listen for a core function
%   defined in the pipeline as a handle alongside the function parameters
%   which will replace the default. Thus users can choose to use the
%   wrapper layer but not the core layer (not recommended, unstable).
if isfield(Arg, 'coreFunc')
    funHandle = Arg.coreFunc;
    fun_varargs = rmfield(Arg, 'coreFunc');
    [EEG, Arg, ~] = funHandle(EEG, fun_varargs);
    
else
    
    % modify only target stimulus codes
    EEG = mark_resp2stim(EEG,...
                           Arg.targetStim,...
                           Arg.targetCorResp,...
                           Arg.targetICResp,...
                           Arg.targetNoResp,...
                           Arg.modTargetCorrect,...
                           Arg.modTargetIncorrect,...
                           Arg.modTargetNoResp); 
    
end


%% ERROR/REPORT
Cfg.ctap.event_modify = Arg;

msg = myReport(sprintf('ERP plotted for measurement %s.',...
    EEG.CTAP.measurement.casename), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

