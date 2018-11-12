function [EEG] = mark_resp2stim(EEG, stim, cresp, fresp, noresp,...
                                    cstim, icstim, nrstim, varargin)
%mark_resp2stim - Modifies EEG.event data based on targets and responses
%
% Description:
%   Inspects the "EEG.event.type" field of an EEG struct and identifies which 
%   target stimuli (TS) have a matching response (correct or incorrect) and
%   which do not. Modifies each TS according to response type: correct,
%   incorrect, not answered. Calculates also reaction times for correctly 
%   responded stimuli.
%   Event modification has been divided accross several m-files. This m-file 
%   acts as the main source of documentation.
%   Event codes that do not belong to set unique(horzcat(stim, cresp,
%   fresp, noresp)) will be discarded (removed temporarily prior to
%   event modification).
%   mark_resp2stim.m is an EEGLAB compatible improved version of ev2_responses.m. 
%   Note, however, that response matching in ev2_responses.m assumes that
%   the event table contains only three types of stimuli whereas this
%   function can handle event tables with unlimited number of different
%   event types.
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
%   This function performs the following modifications to the EV2 data:
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
%   EEG = mark_resp2stim(EEG, stim, cresp, fresp, noresp,...
%                                    cstim, icstim, nrstim)
%
% Inputs:
%   EEG     struct, EEGLAB data structure (see eeg_checkset.m)
%   stim    [1,m] numeric or string, Event codes for target stimuli
%   cresp   [1,m] numeric or string, Event codes that indicate a correct 
%           response to the elements in 'stim'. 
%   fresp   [1,m] numeric or string, Event codes that indicate incorrect 
%           response to the elements in 'stim'. These are sometimes 
%           provided by CognFuse/CognLight.
%   noresp  [1,m] numeric or string, Event codes indicating a "no response"
%           to the elements in 'stim'. These are sometimes 
%           provided by CognFuse/CognLight.
%   cstim   [1,m] numeric or string, Event codes to assign to correctly 
%           answered target stimuli 
%   icstim  [1,m] numeric or string, Event codes to assign to incorrectly 
%           answered target stimuli  
%   nrstim  [1,m] numeric or string, Event codes to assign to not answered 
%           target stimuli  
%
% Outputs:
%   EEG     struct, EEGLAB data structure (see eeg_checkset.m)
%           The following fields have been added or modified:
%   EEG.event.type  string, Type string changed for all target stimuli as
%                           defined by 'stim'
%   EEG.event.rt    numeric, Reaction time calculated for responded
%                            targets in [s] 
%
% Assumptions:
%   The event sequence should be:
%   1. target stimulus
%   2. any stimuli
%   3. response event: correct/incorrect/no repsonse (optional)
%   4. next target stimulus
%   Several target stimuli cannot occur in succession and have a common
%   response event.
%
% References:
%
% Example:
%
% Notes:
%   eeg_checkevent applied -> EEG.event.type converted to string.
%   No lines are removed from the EV2 structure.
%
% See also: analyze_events.m, classify_events.m, eeg_checkevent.m, ev2_responses.m 
%
% Version History:
% 6.9.2010 Help improved and input 'fresp' added. 
% 11/2007 Created based on ev2_responses.m, Jussi Korpela, TTL
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.errorIDStr = '_err';
Arg.errorIDNum = NaN;
Arg.modifyResponses = false;
Arg.cresp = {};
Arg.icresp = {};

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Message
msg = 'mark_resp2stim: Labeling target stimuli in EEG.event.type...';
disp(msg);


%% Check input and initialize variables
%keyboard;
EEG = eeg_checkevent(EEG);
EventMod = structconv(EEG.event); %to plane organization
EventMod.latency = cell2mat(EventMod.latency);
% two copies of event sequence
evsq = EventMod.type;
evsq2 = EventMod.type;
 

%% Analyze responses (pre 3/2017)
%{
try
    % Classify stimuli
    [csm2, fsm2, nasm2, crm2, frm2] =...
        analyze_events(evsq2, stim, cresp, fresp, noresp);


    % Mark target stimuli according to correct/incorrect/not-answered -results
    for i = 1:length(stim)
        evsq2(csm2(:,i)) = cstim(i);
        evsq2(fsm2(:,i)) = icstim(i);
        evsq2(nasm2(:,i)) = nrstim(i);
    end

    % Mark unclassified stimuli
    csm2_tot = sum(csm2,2)>=1;
    fsm2_tot = sum(fsm2,2)>=1;
    nasm2_tot = sum(nasm2,2)>=1;
    stim_match = ismember(evsq2, stim);
    unclassified_stim_match = stim_match' & ~(csm2_tot | fsm2_tot | nasm2_tot);

    if ischar(evsq2{1})
       evsq2(unclassified_stim_match) =....
           strcat(evsq2(unclassified_stim_match),Arg.errorIDStr); 
    else
       evsq2(unclassified_stim_match) =  {Arg.errorIDNum};
    end
    
    old_analysis_succeeded = true;
    
catch
    old_analysis_succeeded = false;
end
%}


%% Analyze responses (current)
csm = false(numel(evsq), numel(stim));
fsm = false(numel(evsq), numel(stim));
nrsm = false(numel(evsq), numel(stim));
crm = false(numel(evsq), numel(stim));
frm = false(numel(evsq), numel(stim));

for m = 1:numel(stim)
    [evsq, m_csm, m_fsm, m_nrsm, m_crm, m_frm] = ...
                                interpret_event_sequence(evsq, stim{m},...
                                cresp{m}, fresp{m}, noresp{m},...
                                cstim{m}, icstim{m}, nrstim{m});
    csm(:,m) = m_csm;
    fsm(:,m) = m_fsm;
    nrsm(:,m) = m_nrsm;
    crm(:,m) = m_crm;
    frm(:,m) = m_frm;
end


%% Quality control
%orig stim locations:
st_match = ismember(EventMod.type, stim)'; 
% interpreted stim locations:
ist_match = (sum(csm, 2) > 0) | (sum(fsm, 2) > 0) | (sum(nrsm, 2) > 0);

if sum(st_match ~= ist_match) > 0
    error(  'mark_resp2stim:mismatch',...
            'Original stim locations do not match to interpreted locations.');
end


EventMod.type = evsq;


%% Compare (debug)
%{
savedir = '/ukko/projects/SeamlessCare_2015-16/analysis/ctap_nback/evlog';
mkdir(savedir);

if old_analysis_succeeded
    tm = horzcat([csm~=csm2]', [fsm~=fsm2]', [crm~=crm2]', [frm~=frm2]');
    bad_match = sum(tm, 2) > 0;

    if  sum(bad_match) > 0
        S.evdata = EventMod;
        S.evsq_old = evsq2;
        S.evsq_current = evsq;
        S.comparison = tm;
        S.bad_match = bad_match;

       savename = sprintf('%s.mat', EEG.setname);
        save(fullfile(savedir, savename), 'S');
    end
    
else
    logfile = fullfile(savedir, 'old_evmod_failed.txt');
    fileID = fopen(logfile,'a');
    fprintf(fileID, sprintf('%s\n', EEG.setname));
    fclose(fileID);    
end
%}


%% Set reaction times
EventMod.rt = NaN(1, length(EventMod.type));
for i = 1:length(stim)
    %Reaction time for correctly responded targets
    EventMod.rt(csm(:,i)) = (EventMod.latency(crm(:,i))-...
                        EventMod.latency(csm(:,i)))/EEG.srate; 
    %Reaction time for incorrectly responded targets
    EventMod.rt(fsm(:,i)) = (EventMod.latency(frm(:,i))-...
                        EventMod.latency(fsm(:,i)))/EEG.srate; 
end


%% Mark responses according to correct/incorrect/not-answered -results
if Arg.modifyResponses
    
    for i = 1:length(Arg.cresp)
        EventMod.type(crm(:,i)) = Arg.cresp(i);
        EventMod.type(frm(:,i)) = Arg.icresp(i);
    end

    % mark unclassified stimuli
    crm_tot = sum(crm,2)>=1;
    frm_tot = sum(frm,2)>=1;
    resp_match = ismember(EventMod.type, cresp);
    unclassified_resp_match = resp_match' & ~(crm_tot | frm_tot);

    if ischar(EventMod.type{1})
       EventMod.type(unclassified_resp_match) =....
           strcat(EventMod.type(unclassified_resp_match),Arg.errorIDStr); 
    else
       EventMod.type(unclassified_resp_match) =  {Arg.errorIDNum};
    end

end

%% Set output
% EEG struct

EEG.event = structconv(EventMod);
