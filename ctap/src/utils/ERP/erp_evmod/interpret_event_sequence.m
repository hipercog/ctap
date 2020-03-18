function    [evsq_out, csm, fsm, nrsm, crm, frm] =...
            interpret_event_sequence(evsq_in, st,...
                                     cr, fr, nr,...
                                     st_cr, st_fr, st_nr)
% Interpret stimuli in an event sequence

% Intended as a simpler replacement for:
% mark_resp2stim.m -> analyze_events.m -> classify_events.m

% evsq_in   [1,M] cellstr, An event sequence
% st        string, Target stimulus code
% cr        string, Correct response code
% fr        string, False / incorrect response code
% nr        string, No-response code
% st_cr     string, Code for correctly responded stimulus
% st_fr     string, Code for incorrectly responded stimulus
% st_nr     string, Code for not responded stimulus
%
% Use '' for fr and nr if they are not coded in any special way.

%% Initialize
% Subset to events that are of interest
relevant_events = {st, cr, fr, nr};
relevant_events = setdiff(relevant_events, ''); %remove possible empty strings
ev_match_in = ismember(evsq_in, relevant_events);
ev_idx_in = find(ev_match_in);
evsq = evsq_in(ev_match_in); %internal event sequence, only relevant events

% st locations in different event sequences
stim_match = ismember(evsq, st);
stim_idx = find(stim_match);
stim_match_in = ismember(evsq_in, st);

% Initialize modified response sequence
evsq_resp = evsq;


%% Rename responses using st_* codes
% correct responses
cr_match = ismember(evsq_resp, cr);
evsq_resp(cr_match) = {st_cr};

% incorrect responses
if ~isempty(fr)
    fr_match = ismember(evsq_resp, fr);
    evsq_resp(fr_match) = {st_fr};
end

% not responded, with special code
if ~isempty(nr)
    nr_match = ismember(evsq_resp, nr);
    evsq_resp(nr_match) = {st_nr};
end

% not responded, without code i.e. followed by another stimulus
% If stimulus is followed by another stimulus it is a not responded one
st_match = ismember(evsq_resp, st);
evsq_resp(st_match) = {st_nr};  


%% Shift and match events
% For stim at index i interpret response sequence element i+1 as the response
evsq_resp = circshift(evsq_resp, -1);
evsq_resp(end) = {st_nr}; %if last event in evq is stimulus it is a no-response

% Store {st_cr, st_fr, st_nr} codes at st locations in the original sequence
evsq_out = evsq_in;
evsq_out(stim_match_in) = evsq_resp(stim_match); 


%% Correct and incorrect response positions (with evsq indexing)
stim_interp = evsq_resp(stim_match);

cstim_idx = stim_idx(ismember(stim_interp, st_cr));
fstim_idx = stim_idx(ismember(stim_interp, st_fr));
nrstim_idx = stim_idx(ismember(stim_interp, st_nr));

cresp_idx = cstim_idx + 1; %responses follow stimuli directly
fresp_idx = fstim_idx + 1;


%% Output variables (with evsq_in indexing)
csm =   false(1, numel(evsq_in)); %Correct Stimulus Match
fsm =   false(1, numel(evsq_in));
nrsm =  false(1, numel(evsq_in));
crm =   false(1, numel(evsq_in));
frm =   false(1, numel(evsq_in));

csm(ev_idx_in(cstim_idx)) = true;
fsm(ev_idx_in(fstim_idx)) = true;
nrsm(ev_idx_in(nrstim_idx)) = true;
crm(ev_idx_in(cresp_idx)) = true;
frm(ev_idx_in(fresp_idx)) = true;
