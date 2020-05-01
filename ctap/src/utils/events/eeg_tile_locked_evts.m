function EEG = eeg_tile_locked_evts(EEG, evType, TILESxEV, LOCK_EVTS, END_EVTS)
%EEG_TILE_LOCKED_EVTS - Add events to EEG
%
% Description:
%   Add events to EEG.event to enable computations - tiles requested number of
%   1 second computation events between named lock events and named end events.
%
% Syntax:
%   EEG = eeg_tile_locked_evts(EEG, TILESxEV, LOCK_EVTS, END_EVTS, varargin)
%
% Inputs:
%   EEG        struct, EEGLAB struct, non-epoched data
%   evType     string, Event type string for the new events
%   TILESxEV   [1,1] numeric, number of event tiles per lock-event
%   LOCK_EVTS  cell string array or string, name(s) of lock-event(s)
%   END_EVTS   cell string array or string, name(s) of end-event(s)
%
% Varargin     Keyword-value pairs
%
% Outputs:
%   EEG         struct, EEGLAB struct with new events of evLength at
%               with possible overlap.
%
% Notes:
%   Assumes continuous time. Tries to create the generated segments without 
%   including any boundary events, but defaults to a regular tiling if it 
%   can't avoid boundaries. If avilable time is too short, overlapping occurs
%
% See also:
%
% Version History:
% 2020 Ben Cowley, U of Helsinki
%
% Copyright(c) 2020 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO - ADD PARAMETER TO SET DURATION OF TILED EVENTS
% TODO - ADD PARAMETER TO FIX BOUNDARY EVENTS AS NOGO - FAILURE CASE

%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('EEG', @isstruct)
p.addRequired('evType', @ischar)
p.addRequired('TILESxEV', @isnumeric)
p.addRequired('LOCK_EVTS', @(x) iscellstr(x) || ischar(x) || isstring(x))
p.addRequired('END_EVTS', @(x) iscellstr(x) || ischar(x) || isstring(x))

p.parse(EEG, evType, TILESxEV, LOCK_EVTS, END_EVTS)
% Arg = p.Results;


%% 
bndx = ismember({EEG.event.type}, 'boundary');
bndlats = [EEG.event(bndx).latency];

% blkx = ismember({EEG.event.type}, 'blink');
% blklats = [EEG.event(blkx).latency];

lockev_register = zeros(1, numel(LOCK_EVTS));


%%
ev = 1;
rsps = 0;
while ev < length(EEG.event) %go through all the events
    if ismember(EEG.event(ev).type, LOCK_EVTS) %act on those that are LOCKs
        lockevix = ismember(LOCK_EVTS, EEG.event(ev).type);
        lockev_register(lockevix) = lockev_register(lockevix) + 1;
        rsps = rsps + 1;
        lats = zeros(1, TILESxEV);
        evlat = EEG.event(ev).latency;
        for evd = ev+1:length(EEG.event)
            if ismember(EEG.event(evd).type, END_EVTS)
                break
            end
        end
        wnlat = EEG.event(evd).latency;
        evlen = wnlat - evlat;
%         evsec = evlen / EEG.srate;
        curr_evs = ev:evd;
        bndx_in_epc = bndlats >= evlat & bndlats <= wnlat;
%         blkx_in_epc = blklats >= evlat & blklats <= wnlat;
        
        % calculate onsets from less than TILESxEV seconds of data
        if evlen <= TILESxEV * EEG.srate
            % so, uniformly spread five 1sec windows...
            olp = ((TILESxEV * EEG.srate) - evlen) / (TILESxEV - 1);
            lats = evlat + 1 : EEG.srate - olp : wnlat - 1;
            % An extra onset is created but we can simply discard it
            if numel(lats) > TILESxEV
                lats((TILESxEV + 1):end) = [];
            end
            
        % calculate onsets that minimise overlap with boundaries
        elseif numel(curr_evs) > 2 && any(bndx_in_epc)
            
            % calculate sparse onsets, but from cut-up data
            cslat = evlat + 1;
            % try to get five clean slices if gaps exist between boundaries
            for e = (1:TILESxEV)
                while cslat <= wnlat - (((TILESxEV + 1) - e) * EEG.srate)
                    bndx_in_wnd = bndlats >= cslat & bndlats <= cslat + EEG.srate;
                    if any(bndx_in_wnd)
                       cslat = max(bndlats(bndx_in_wnd)) + 1;
                    else
                        lats(e) = cslat;
                        cslat = cslat + EEG.srate + 1;
                        break
                    end
                end
            end
            % Try to place the missing event where there is fewest boundaries
            if sum(lats == 0) == 1
                lat0x = lats(lats ~= 0);
                allat = evlat + 1 : wnlat - 1;
                stx = evlat + 1;
                for i = 1:numel(lat0x)
                    allat(ismember(allat, lat0x(i):lat0x(i) + EEG.srate)) = [];
                    stx(end + 1) = lat0x(i) + EEG.srate + 1; %#ok<AGROW>
                end
                stx(~ismember(stx, allat)) = [];
                jumps = diff(allat) > 1;
                jumps(end) = 1;
                stx_bndx_in_wnd = zeros(1, numel(stx));
                for i = 1:numel(stx)
                    if allat(find(jumps, 1)) - stx(i) < EEG.srate
                        break
                    else
                        stx_bndx_in_wnd(i) = sum(ismember(bndlats...
                                            , stx(i):allat(find(jumps, 1))));
                    end
                end
                [~, mnstx] = min(stx_bndx_in_wnd);
                lats(lats == 0) = stx(mnstx);
            end
        end
        % create TILESxEV windows from clean sparse data
        if any(lats == 0)
            lats = evlat + 1 : EEG.srate : evlat + EEG.srate * TILESxEV;
        end
 
        cseg = eeglab_create_event(lats, evType...
                            , 'duration', {EEG.srate}...
                            , 'label', {EEG.event(ev).type}...
                            , 'kind', {num2str(lockev_register(lockevix))});
        EEG.event = eeglab_merge_event_tables(EEG.event, cseg, 'ignoreDisc');
    end
    ev = ev + 1;
end
% check csegs
csegs = sum(ismember({EEG.event.type}, 'cseg'));
fprintf('%d csegs from %d responses for %s\n'...
    , csegs, rsps, EEG.CTAP.subject.subject)
% save file
if csegs ~= rsps * TILESxEV
    disp('SOMETHING HAS GONE TERRIBLY WRONG!!')
end