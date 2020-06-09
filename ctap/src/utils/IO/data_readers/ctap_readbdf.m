function EEG = ctap_readbdf(filename, varargin)
% ctap_readbdf() - Read Biosemi 24-bit BDF file
%
% Description:
%   Emulates EEGLAB's pop_readbdf() from bdfimport1.1
%   Code is refactored to bypass GUI and some obsolete/odd processes.
%   WARNING - does not always read events into EEG.event structure
%   
% Syntax:
%   EEG = pop_readbdf( filename );
%   EEG = pop_readbdf( filename, ref );
%
% Inputs:
%   filename    string, Biosemi 24-bit BDF file name
% 
% Varargin
%   gettrig     true, read triggers from data channel labelled 'Status'
%               Default: true
%   refchan     [1 n] channel index or index(s) for the reference.
%                    Reference channels are not removed from the data,
%                    allowing easy re-referencing. If more than one
%                    channel, data are referenced to the average of the
%                    indexed channels. WARNING! Biosemi Active II data 
%                    are recorded reference-free, but LOSE 40 dB of SNR 
%                    if no reference is used!. If you do not know which
%                    channel to use, pick one and then re-reference after 
%                    the channel locations are read in. {default: none}
%               Default: []
%
% Outputs:
%   EEG            - EEGLAB data structure
%
% See also: openbdf(), readbdf()
%
% Author: Benjamin Cowley (ben.cowley@helsinki.fi)
% Based on code by
%   Arnaud Delorme
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO - FIX EVENT READING, NOT CURRENTLY WORKING AS BIOSIG

%% Parse input
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('filename', @ischar)

p.addParameter('gettrig', true, @islogical)
p.addParameter('refchan', [], @isnumeric)

p.parse(filename, varargin{:});
Arg = p.Results;


%% LOAD DATA USING Alois Schloegl's openbdf, readbdf FROM bdfimport1.1
% ----------
fprintf('ctap_readbdf : Reading BDF data in 24-bit format...\n');
dat = openbdf(filename);
fid = dat.Head.FILE.FID;
if isempty(dat.Head.NRec)
    dat.Head.NRec = 100;
end
DAT = readbdf(dat, 1:dat.Head.NRec);

EEG = eeg_emptyset;
EEG.nbchan = size(DAT.Record, 1);
if numel(unique(dat.Head.SampleRate)) > 1
    warning('ctap_readbdf:check_sr', '%d different sample rates found!%s%d'...
        , numel(unique(dat.Head.SampleRate)), ' Using channel 1 srate of: '...
        , dat.Head.SampleRate(1))
end
EEG.srate = dat.Head.SampleRate(1);
EEG.data = DAT.Record;
EEG.pnts = size(EEG.data ,2);
EEG.trials = 1;
EEG.setname = dat.Head.FILE.Name;
EEG.filename = [dat.Head.FILE.Name '.' dat.Head.FILE.Ext];
EEG.filepath = dat.Head.FILE.Path;
EEG.xmin = 0; 
EEG.chanlocs = struct('labels', cellstr(dat.Head.Label));
EEG = eeg_checkset(EEG);


%% EXTRACT EVENTS FROM LAST CHANNEL
% If triggers are coded by raising and lowering of the bit (pulsed), then
% each trigger corresponds to an entire contiguous period of not-0, even if
% its level varies (due to some jitter, etc)
if Arg.gettrig
    trgdx = strcmp('Status', {EEG.chanlocs.labels});
    if ~any(trgdx)
        trgdx = size(EEG.data, 1);
    end
% TODO - SEE biosig/T200_FileAccess/sopen.m line 1036-1072, which uses only
%   fread.m and bdf2biosig_events.m (latter could be CTAP-embedded)
%     [t,c] = fread(fid, inf, [int2str(dat.Head.SampleRate(trgdx)*3),'*uint8']...
%         , dat.Head.AS.spb - dat.Head.SampleRate(trgdx) * 3);
    fprintf('ctap_readbdf : Extracting 24-bit events...\n');
    PULSE_OFF = true;
    trggrch = mod(EEG.data(trgdx, :), 256 * 256);
    offset = 65280; %offset SHOULD be 256^2 - 256, but might vary
    for o = 0:6 %set trigger base-level to 0 by subtracting an offset
        tmp = trggrch - (offset + 32 * o);
        if any(tmp == 0)
            offset = (offset + 32 * o);
            fprintf('Triggers offset by -%d\n', offset);
            trggrch = tmp;
            break
        end
    end

    if ~any(trggrch == 0)
        warning('ctap_readbdf:bad_triggers', 'No events read into EEG')
    else
        for p = 1:size(EEG.data, 2) - 1
            trggr = trggrch(p);
            if trggr ~= 0 % IF trigger channel rises...
                if PULSE_OFF % AND pulse flag is off...
                    EEG.event(end + 1).latency = p; % THEN code pulse onset...
                    EEG.event(end).type = trggr + offset; % AND value (+2bytes)
                    PULSE_OFF = false; % Guard against coding more triggers
                end
            else % IF trigger channel falls...
                if ~PULSE_OFF % ...AND pulse flag is ON, THEN add duration
                    EEG.event(end).duration = p - EEG.event(end).latency;
                end
                PULSE_OFF = true; %set pulse flag off
            end
        end
        EEG = pop_select(EEG, 'nochannel', EEG.nbchan);
        EEG = eeg_checkset(EEG, 'makeur');
    end
end


%% REFERENCE
if ~isempty(Arg.refchan)
    warning('ctap_readbdf:reref'...
        , 'Re-referencing to %s; note this will decrease matrix rank'...
        , num2str(Arg.refchan));
    EEG.data = EEG.data - ...
        repmat(mean(EEG.data(Arg.refchan, :), 1), [EEG.nbchan 1]);
end

