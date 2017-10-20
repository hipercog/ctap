function  [csm, fsm, nasm, crm, frm] =...
    analyze_events(evarr, stim, cresp, fresp, noresp, varargin)
%ANALYZE_EVENTS - Interpret event code vector
%
% Description:
%   Searches matching stimulus-response pairs from a vector of event codes.
%   Can be used for example to interpret event log from test such as oddball, 
%   Task Switching, Operation Span, etc.
%  
%   Basically this function divides any occurences of 'stim' events into
%   one of the following classes:  correct, incorrect and no response.
%
%   If your event array ('evarr') contains 
%   1. other events than those defined by unique(horzcat(stim, cresp, noresp))
%   2. multiple responses to the same target stimulus (e.g. 14+12 or 14+13
%      in CognFuse Task Switching task)
%   you should use this this function. Another option is to use
%   classify_events.m directly but if either of the above mentioned
%   conditions hold, you will get incorrect results. When using CognFuse
%   the above mentioned conditions always hold and you should use this
%   function.
%
%   How it works:
%   1. All irrelevant events are marked
%   2. All multiple responses to the same stimulus are marked
%   3. Marked events are temporarily removed
%   4. Classification of target stimuli into correct, incorrect and no
%      response is done with classify_events.m using a modified event array
%      that does not contain irrelevant events and/or multiple responses.
%   5. Results are reported with respect to the original unpruned event array
%
%   Depending on the values of varargin parameter 'ignoreMultipleResponses',
%   the step 2. is either taken or not. By default it's taken.
%
% Syntax:
%   [csm, fsm, nasm, crm, frm] =...
%   analyze_events(evarr, stim, cresp, fresp, noresp, varargin);
%
% Inputs:
%   evarr   [1,N] | [N,1] numeric, Event code array
%   stim    [1,m] numeric or string, Stimulus codes
%   cresp   [1,m] numeric or string, Correct response codes for the 
%           elements in 'stim'
%   fresp   [1,m] numeric or string, Incorrect response codes for the
%           elements in 'stim' (sometimes provided by CognFuse/CognLight)
%   noresp  [1,m] numeric or string, Response codes marking "no response" 
%           for the elements in stim
%
%   varargin    Keyword-value pairs
%   Keyword                     Type, description, value
%   'ignoreMultipleResponses'   string, To analyze only the first response to
%                               a stimulus set this to 'yes'. If set to 'no'
%                               all responses to the stimulus will appear
%                               in the output arrays causing a single stimulus
%                               to be recorded multiple times, {<'yes'>,'no'}
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
%
% References:
%
% Example: 
%   [csm, fsm, nasm, crm, frm] = analyze_events(evarr1,
%   [10,11,20,21,30,31,40,41], [12,13,12,13,12,13,12,13], [14,14,14,14,14,14,14,14]);
%   
%   Correctly answered stimulus positions (any stimulus correct)
%   csm_anystim = sum(csm, 2); 
%
% Notes:
%
% See also: search_response, classify_events 
%
% Version History:
% 2.9.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.ignoreObscuringEvents = 'yes'; % Do not change this value!
Arg.ignoreMultipleResponses = 'yes'; %{<'yes'>,'no'}

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


%% Initialize variables
% Output variables
csm = false(length(evarr), length(stim)); %correct stimulus match
fsm = false(length(evarr), length(stim)); %incorrectly answered stimulus match
nasm = false(length(evarr), length(stim)); %not asnswered stimulus match
crm = false(length(evarr), length(stim)); %correct response match
frm = false(length(evarr), length(stim)); %incorrect response match

% Helper variables
%{
tmp = false(length(evarr), length(stim));
nasm_code = false(length(evarr), length(stim)); %not answered stimulus match - noresp(i) code found
nasm_empty = false(length(evarr), length(stim)); %not answered stimulus match - no response codes found 
nasm_test = false(length(evarr), length(stim)); %not asnswered stimulus match for result testing
%}


%% Find events that obscure the analysis
if strcmp(Arg.ignoreObscuringEvents, 'yes')
    allowed_code_arr = unique(horzcat(stim, cresp, fresp, noresp));
    allowed_code_match = ismember(evarr, allowed_code_arr);
    disp('analyze_events: Possible irrelevant event codes ignored.');

else
    error('analyze_events:irrelevantEventsNotIgnored','Irrelevant events are not ignored. Multiple response matching won''t work either.');
end

%% Find sequences of multiple response codes
if strcmp(Arg.ignoreMultipleResponses, 'yes') && strcmp(Arg.ignoreObscuringEvents, 'yes')
    
    % Create response code position vectors
    resp_code_arr = unique(horzcat(cresp, noresp));
    resp_code_match = ismember(evarr(allowed_code_match), resp_code_arr);
    resp_code_match_shifted = circshift(resp_code_match, 1);

    % Remove first element
    resp_code_match = resp_code_match(2:end);
    resp_code_match_shifted = resp_code_match_shifted(2:end);

    % Compare to find any sequences of multiple response codes
    unwanted_resp_match = (resp_code_match & resp_code_match_shifted);
    unwanted_resp_match = vertcat(0, unwanted_resp_match); % add removed first element
    
    disp('analyze_events: Possible of multiple response codes ignored.');
else
    warning('analyze_events:multipleResponsesNotIgnored','Multiple responses to the same stimulus not ignored. Some target stimuli possibly recorded twice.');
end


%% Create final event selection vector
analysis_event_match = allowed_code_match;
analysis_event_match(allowed_code_match) = ~unwanted_resp_match;


%% Analyze a subset of the event array

[csm_tmp, fsm_tmp, nasm_tmp, crm_tmp, frm_tmp] =...
    classify_events(evarr(analysis_event_match), stim, cresp, fresp, noresp);


%% Assign results
csm(analysis_event_match, :) = csm_tmp;
fsm(analysis_event_match, :) = fsm_tmp;
nasm(analysis_event_match, :) = nasm_tmp;
crm(analysis_event_match, :) = crm_tmp;
frm(analysis_event_match, :) = frm_tmp;