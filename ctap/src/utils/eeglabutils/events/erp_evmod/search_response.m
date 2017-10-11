function [respTargetMatch, norespTargetMatch,...
    correctRespMatch, falseRespMatch] = search_response(evarr,...
    target_code, response_code, standard_code_arr, varargin)
%SEARCH_RESPONSE - Detects responses to targets from an event array
%
% NOTE: This function has been using up to 15.12.2014 strArrayFind() with
% substring matching, yielding incorrect results e.g. for integer codes 
% converted to string. For example '1' matches to '11','21', etc...
% Changed to using ismember() instead.
%
% Description:
%   Identifies which target stimuli (TS) in 'evarr' have a matching 
%   response and which do not. Returns logical vectors indicating 
%   responded/not responded target stimulus positions and correct/false 
%   response positions. 
%
%   A matching response is an event for which:
%       1.  Event code equals to 'response_code'
%       2.  Response follows 'target_code' either directly or at least
%       before next 'target_code' or 'standard_code'
%
%
% Syntax:
%   [respTargetMatch, norespTargetMatch,...
%    correctRespMatch, falseRespMatch] = search_response(evarr,...
%    target_code, response_code, standard_code_arr, varargin)
%
% Inputs:
%   evarr               [1,N] | [N,1] cell of strings OR numeric, 
%                       Event code array to be interpreted,
%                       For example: evarr = {EEG.event(:).type}
%   target_code         string OR [1,1] numeric, Target event code
%   response_code       string OR [1,1] numeric, Respone event code
%   standard_code_arr   [1,m] | [m,1] cell of strings OR numeric,
%                       Standard event code(s) 
%
% Outputs: 
%   respTargetMatch     [N,1] logical, Responded target positions
%   norespTargetMatch   [N,1] logical, Not responded target positions
%   correctRespMatch    [N,1] logical, Correct response positions
%   falseRespMatch      [N,1] logical, False response positions
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%   EEG = eeg_checkevent(EEG) can be applied to ensure that all events are
%   in string format before passing them to this function.
%
% See also: mark_resp2stim, analyze_events, classify_events, ev_responses, 
%           ev2_responses, eeg_checkevent
%
% Version History:
% 7.3.2008 Created based on ev_responses.m (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
Arg = struct([]);

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check input and initialize variables
evarr = evarr(:); %to column vector
N_events = length(evarr);

% Preallocate memory for output variables
respTargetMatch = false(N_events,1);
norespTargetMatch = false(N_events,1);
correctRespMatch = false(N_events,1);
falseRespMatch = false(N_events,1);


%% Target and stimulus positions

% Target positions
targetMatch = ismember(evarr, target_code);
targetInds = find(targetMatch);
% FIXME: if no targets are found, targetInds will be empty and code will
% crash. What if other codes are missing?

% Standard positions
standardMatch = ismember(evarr, standard_code_arr);
standardInds = find(standardMatch);

% Stimulus positions (i.e. target or standard stimulus)
stimMatch = standardMatch | targetMatch;
stimInds = find(stimMatch);

% Response positions
respMatch = ismember(evarr, response_code);
respInds = find(respMatch);

if isempty(targetInds)
    msg = ['No target events of type: ', sbf_coerceToString(target_code), ' found.'];
    disp(msg);
    return;  
end


%% Match targets and responses
% Targets 1:N-1
for i=1:length(targetInds)-1
    % Test which targets i have a matching response before next target OR
    % standard
    
    % Find out index of next stimulus
    i_tmp = find(targetInds(i) < stimInds);
    i_next_stim_ind = stimInds(i_tmp(1));
    
    % Check if any responses reside between target i and next stimulus
    i_respMatch = (targetInds(i)<respInds) & (respInds<i_next_stim_ind); 
    
    % Set output for target i
    if sum(i_respMatch) >= 1
        respTargetMatch(targetInds(i)) = 1;
        i_respMatch_inds = respInds(i_respMatch);
        correctRespMatch(i_respMatch_inds(1)) = 1;
    else
        norespTargetMatch(targetInds(i)) = 1;
    end
    %if i==8
    %    keyboard
    %end
    clear('i_*');
end

% Target N (last target)
% Find out index of next stimulus
tmp_stim_inds = find(targetInds(end) < stimInds);
if isempty(tmp_stim_inds)
    i_next_stim_ind = N_events;
else
    i_next_stim_ind = stimInds(tmp_stim_inds(1));
end
% Check if any responses reside between target N and next auditory
% stimulus
end_respMatch = (targetInds(end)<respInds) & (respInds<=i_next_stim_ind); 
% Set output for target N
if sum(end_respMatch) >= 1
    respTargetMatch(targetInds(end)) = 1;
    end_respMatch_inds = respInds(end_respMatch);
    correctRespMatch(end_respMatch_inds(1)) = 1;
else
    norespTargetMatch(targetInds(end)) = 1;
end


%% Set remaining output variables
falseRespMatch = ~correctRespMatch & respMatch;


%% Check correctness of event classification
if sum(respTargetMatch) ~= sum(correctRespMatch)
    msg = 'Checksum mismatch -> event classification failed.';
    error('ev_responses:eventClassificationError',msg); 
    
elseif (sum(norespTargetMatch)+sum(respTargetMatch)) ~= sum(targetMatch)
    msg = 'Checksum mismatch -> event classification failed.';
    error('ev_responses:eventClassificationError',msg);
    
elseif (sum(correctRespMatch)+sum(falseRespMatch)) ~= sum(respMatch)
    msg = 'Checksum mismatch -> event classification failed.';
    error('ev_responses:eventClassificationError',msg);
end

function xstr = sbf_coerceToString(x)
    if isnumeric(x)
        xstr = num2str(x);
    else 
        xstr = x;
    end
end


end