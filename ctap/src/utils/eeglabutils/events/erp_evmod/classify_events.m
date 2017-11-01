function  [csm, fsm, nasm, crm, frm] =...
    classify_events(evarr, stim, cresp, fresp, noresp, varargin)
%CLASSIFY_EVENTS - Interpret event code vector
%
% Description:
%   Searches matching stimulus-response pairs from a vector of event codes.
%   Can be used for example to interpret event log from test such as 
%   Oddball, Task Switching, Operation Span, etc. 
%
%   Basically this function divides any occurences of 'stim' events into
%   one of the following classes:  correct, incorrect and no response.
%
%   If your event array ('evarr') contains 
%   1. other events than those defined by unique(horzcat(stim, cresp, noresp))
%   2. multiple responses to the same target stimulus (e.g. 14+12 or 14+13
%      in CognFuse Task Switching task)
%   you SHOULD NOT USE classify_events() directly. Use analyze_events()
%   instead.
%
% Code overview:
%   1. For each stim(i)
%       a) Find correctly answered instances (csm, crm)
%       b) Find incorrectly answered instances (fsm, frm)
%       c) Find not answered instances using noresp(i) (nasm_code)
%   2. For all stim(:) at once
%       a) Find not answered instances i.e. trains of stimulus codes
%       following each other (nasm_empty)
%   3. Combine not answered instances into one
%       (nasm = nasm_code | nasm_empty)
%
%   Uses search_responses.m to search for different stimulus-response
%   pairs
% 
% Algorithm: 
%   1. Search all occurences of 'stim(:)' from 'evarr' (i.e. search for 
%      any type of target stimulus stimulus)
%   For all stimuli in 'stim' indexed by i
%       4. Select a stimulus-response pair i
%       3. Search all occurences of stimulus 'stim(i)'
%       For all occurences of 'stim(i)' indexed by k
%           4. Check the event codes that exist between k:th occurence of
%              'stim(i)' and the next occurence of any type of target
%              stimulus.
%           5. Depending on the event codes found, do the following 
%              (code found from interval => action):              
%               * found 'cresp(i)' =>
%               mark the stimulus-response pair in 'csm' and 'crm'
%               * found 'fresp{i}' or 'cresp{k}', where k~=i =>
%               mark the stimulus-response pair in 'fsm' and 'frm'
%               * found 'noresp(i)' or no response code at all =>
%               mark the stimulus in 'nasm'
%       Move on to the next occurence of 'stim{i}'
%   Move on to the next stimulus 'stim(i+1)'
%
%
% Syntax:
%   [csm, fsm, nasm, crm, frm] =...
%   classify_events(evarr, stim, cresp, fresp, noresp, varargin);
%
% Inputs:
%   evarr   [1,N] | [N,1] numeric, Event code array
%   stim    [1,m] numeric OR cell of strings, Stimulus codes
%   cresp   [1,m] numeric OR cell of strings, Correct response codes for 
%           the elements in 'stim'
%   fresp   [1,m] numeric OR cell of strings, Incorrect response codes for
%           the elements in 'stim' (sometimes provided by e.g. CognFuse/CognLight)
%   noresp  [1,m] numeric  OR cell of strings, Response codes marking 
%           "no response" for the elements in stim
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, value
%   showDebug   string, Should debugging information be shown or not, 
%               {<'no'>, 'yes'}       
%
% Outputs:
%   csm     [N,m] logical, Positions of CORRECTLY answered STIMULI,
%           csm <-> "correct stimulus match"
%   fsm     [N,m] logical, Positions of INCORRECTLY answered STIMULI,
%           fsm <-> "false stimulus match"
%   nasm    [N,m] logical, Positions of NOT ANSWERED STIMULI,
%           nasm <-> "not answered stimulus match"
%   crm     [N,m] logical, Positions of CORRECT ANSWERS,
%           csm <-> "correct response match"
%   frm     [N,m] logical, Positions of INCORRECT ANSWERS,
%           fsm <-> "false response match"
%
% Assumptions:
%   Assumes the following:
%   * evarr CONTAINS ONLY events that belong to the set of allowed events
%     i.e. unique(horzcat(stim,cresp, noresp))
%   * there is NOT MORE THAN ONE answer to each target stimulus. Target 
%     stimuli without any answer are allowed. Both a stimulus followed by a
%      noresp code or a stimulus followed by another stimulus are recorded 
%      as not responded stimuli.
%
%   Violating these assumptions does not necessarily cause the code to crash
%   but will issue a warning. It will also cause 'csm', 'fsm' and 'nasm'
%   not to sum to the total number of target stimuli present in 'evarr'.
%   This happens because multiple answers to one target causes the target to
%   be recorded multiple times and because unallowed events may cause a not 
%   responded target to go undetected. Use analyze_events.m to overcome
%   these problems.
%
% References:
%
% Example:
%
% Notes:
%
% See also: mark_resp2stim, analyze_events, search_response 
%
% Version History:
% 23.4.2010 Modified to accept strings as stimulus and response codes,
% Jussi Korpela, TTL
% 27.8.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.showDebug = 'no';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check inputs
% To column vector
evarr = evarr(:); 

% To row vector
stim = stim(:)'; 
cresp = cresp(:)'; 
fresp = fresp(:)'; 
noresp = noresp(:)';

% Check event array
if sum(ismember(evarr,unique(horzcat(stim, cresp, fresp, noresp))))~=length(evarr)
    msg = 'Event array contains unallowed events. Cannot continue.';
    error('classify_events:inputError', msg);
end


%% Initialize variables
% Output variables
csm = false(length(evarr), length(stim)); %correct stimulus match
fsm = false(length(evarr), length(stim)); %incorrectly answered stimulus match
nasm = false(length(evarr), length(stim)); %not asnswered stimulus match
crm = false(length(evarr), length(stim)); %correct response match
frm = false(length(evarr), length(stim)); %incorrect response match

% Helper variables
tmp = false(length(evarr), length(stim));
nasm_code = false(length(evarr), length(stim)); %not answered stimulus match - noresp(i) code found
nasm_empty = false(length(evarr), length(stim)); %not answered stimulus match - no response codes found 
nasm_test = false(length(evarr), length(stim)); %not asnswered stimulus match for result testing


%% Determine output sequences for all stimuli
for i = 1:length(stim)

    % Select i:th elements
    i_stim = stim(i);
    i_cresp = cresp(i);
    i_fresp = fresp(i);
    i_noresp = noresp(i);

    % Define other stimuli than stim(i) as non target for the round i
    i_target_match = ismember(stim, i_stim);
    i_non_target_stims = stim(~i_target_match);
    
    % Syntax of search_response.m:
    %[respTargetMatch, norespTargetMatch,...
    %correctRespMatch, falseRespMatch] =...
    %search_response(evarr, target_code, response_code, standard_code_arr, varargin)
   
    
    %% Find CORRECTLY answered occurences of stim(i)
    [csm(:,i), tmp(:,i), crm(:,i)] =...
        search_response(evarr, i_stim, i_cresp, i_non_target_stims); 

    
    %% Find INCORRECTLY answered occurences of stim(i)
    % Set correct responses other than cresp(i) as incorrect responses
    % There might also exist also a dedicated incorrect response code
    
    %todo:
    % there are two cases:
    % 1. only stim and reponse codes
    % 2. stim, hit, miss, noresp codes
    % the logic for finding fsm and frm should be different for each.
    % The current logic is for case 1. only.
    % Problems arise if stimuli are missing e.g. due to boundary events.
    i_incorrect_resp_codes = unique(horzcat(i_fresp, setdiff(cresp, i_cresp)));
 
    % Find stim(i) followed by i_incorrect_resp_codes
    i_fsm_tmp = false(length(evarr), length(i_incorrect_resp_codes));
    i_frm_tmp = false(length(evarr), length(i_incorrect_resp_codes));
    i_tmp = false(length(evarr), length(i_incorrect_resp_codes));
    for k = 1:length(i_incorrect_resp_codes)
        [i_fsm_tmp(:,k), i_tmp(:,k), i_frm_tmp(:,k)] =...
            search_response(evarr, i_stim, i_incorrect_resp_codes(k), i_non_target_stims);
    end
    fsm(:,i) = (sum(i_fsm_tmp,2) >= 1);
    frm(:,i) = (sum(i_frm_tmp,2) >= 1);
    
    if sum(fsm(:,i)) ~= sum(frm(:,i))
       error('classify_events:logicError',...
             'This should not happen. Maybe a stim code is gone missing due to e.g. a boundary event.'); 
    end
    
    %if strcmp(i_fresp, 'Resp_incorrect_p3') && strcmp(i_stim, 'Event_Seed_p3')
    %   keyboard; 
    %end
    
    
    %% Find NOT ANSWERED occurences of i_stim - error code present
    % calls search_response.m
    noresp_codes = unique(i_noresp);
    [sm, rm] = test_codes(evarr, i_stim, noresp_codes, i_non_target_stims);
    nasm_code(:,i) = test_codes(evarr, i_stim, noresp_codes, i_non_target_stims);
    
    
    %% Find NOT ANSWERED occurences of i_stim - FOR VERIFICATION
    i_sm = ismember(evarr,i_stim);
    nasm_test(:,i) = (i_sm & (~csm(:,i) & ~fsm(:,i)) );  
    
    clear('i_*');
end



%% Find NOT ANSWERED occurences of stim(:) - no response or error code present
% Not answered stimuli appear as sequences of multiple stimulus codes

stim_code_match = ismember(evarr, stim);
stim_code_match_shifted = circshift(stim_code_match, -1);

% Remove last element
stim_code_match = stim_code_match(1:end-1);
stim_code_match_shifted = stim_code_match_shifted(1:end-1);

% Compare to find any sequences of multiple stimulus codes
multiple_stim_match = (stim_code_match & stim_code_match_shifted);

% Transfer locations to original 'evarr' vector
nasm_empty_collapsed = vertcat(multiple_stim_match, false); %add previously removed last element
nas_inds = find(nasm_empty_collapsed);
nas_types = evarr(nasm_empty_collapsed);

% Build uncollapsed 'nasm_empty'
for i = 1:length(nas_types)
    % Select i:th element
    if iscell(stim)
        % cell array of strings
        i_nas_types = nas_types{i};
    else
        % numeric array
        i_nas_types = nas_types(i);
    end
    i_stim_match = ismember(stim,i_nas_types);
    nasm_empty(nas_inds(i), i_stim_match) = 1;
    clear('i_*');
end



% Test the last event
stim_code_inds = find(ismember(evarr, stim));
ans_code_inds = find(ismember(evarr,horzcat(cresp,fresp,noresp)));
if ~isempty(ans_code_inds)
    if stim_code_inds(end) > ans_code_inds(end)
        tmp = ismember(stim, evarr(stim_code_inds(end)));
        nasm_empty(end, tmp) = true;
    end
else
    %no answer codes present (very rare situation)
    tmp = ismember(stim, evarr(stim_code_inds(end)));
    nasm_empty(end, tmp) = true;
end

nasm = nasm_code | nasm_empty;


%% Check result consistency
if sum(sum(csm)+sum(fsm)+sum(nasm)) > sum(ismember(evarr, stim))
   warning('classify_events:multipleClassificationWarning', 'Some stimuli classified multiple times. Check validity of assumptions. '); 
   
elseif sum(sum(csm)+sum(fsm)+sum(nasm)) < sum(ismember(evarr, stim)) 
    warning('classify_events:incompleteClassificationWarning', 'Some stimuli not classified. Results incorrect.');  
end


if sum(sum(nasm_code)+sum(nasm_empty)) < sum(sum(nasm_test))
    warning('classify_events:incompleteClassificationWarning', 'Some stimuli not classified. Results incorrect.'); 
    
elseif sum(sum(nasm_code)+sum(nasm_empty)) > sum(sum(nasm_test))
    warning('classify_events:multipleClassificationWarning', 'Some stimuli classified multiple times. Check validity of assumptions. '); 
end


%% Show debugging information
if strmatch(Arg.showDebug, 'yes')   
    disp('csm+fsm')
    sum(csm,1)+sum(fsm,1)
    sum(sum(csm,1))+sum(sum(fsm,1))
    disp('csm+fsm+nasm')
    sum(csm,1)+sum(fsm,1)+sum(nasm,1)
    sum(sum(csm))+sum(sum(fsm))+sum(sum(nasm))
    disp('#stim')
    sum(numArrayFind(evarr, stim))

    disp('*********************')

    disp('nasm_test')
    sum(nasm_test, 1)
    sum(sum(nasm_test))
    disp('nasm_code')
    sum(nasm_code, 1)
    sum(sum(nasm_code))
    disp('nasm_empty')
    sum(nasm_empty, 1)
    sum(sum(nasm_empty))
    disp('nasm_code + nasm_empty')
    sum(nasm_code,1)+sum(nasm_empty,1)
    sum(sum(nasm_code))+sum(sum(nasm_empty))
end

function [sm, rm] = test_codes(evarr, stim, codes_to_test, non_target_stimulus_codes)
    % This function is used as a looper to find matching stimulus -
    % response pairs for an array of response codes. Note that 
    % search_response.m assumes that both target stimulus and the respective
    % response code cannot be arrays.
    
    % Find 'stim' followed by one of the codes in 'codes_to_test'
    sm_tmp = false(length(evarr), length(codes_to_test)); %stimulus match
    nrm_tmp = false(length(evarr), length(codes_to_test)); %noresp match (not needed)
    rm_tmp = false(length(evarr), length(codes_to_test)); %response match
    
    for m = 1:length(codes_to_test)
        [sm_tmp(:,m), nrm_tmp(:,m), rm_tmp(:,m)] =...
            search_response(evarr, stim, codes_to_test(m), non_target_stimulus_codes);
    end
    sm = (sum(sm_tmp,2) >= 1);
    rm = (sum(rm_tmp,2) >= 1);
end % of test_codes


end % of classify_events






