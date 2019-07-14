function EEG = ctap_readbdf(filename, varargin)
% ctap_readbdf() - Read Biosemi 24-bit BDF file
%
% Description:
%   Emulates EEGLAB's pop_readbdf() from bdfimport1.1
%   Code is refactored to bypass GUI and some obsolete/odd processes.
%   
% Syntax:
%   EEG = pop_readbdf( filename );
%   EEG = pop_readbdf( filename, ref );
%
% Inputs:
%   filename    string, Biosemi 24-bit BDF file name
% 
% Varargin
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


%% Parse input
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('filename', @ischar)

p.addParameter('refchan', [], @isnumeric)

p.parse(filename, varargin{:});
Arg = p.Results;


%% LOAD DATA USING Alois Schloegl's openbdf, readbdf FROM bdfimport1.1
% ----------
fprintf('ctap_readbdf : Reading BDF data in 24-bit format...\n');
dat = openbdf(filename);
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
fprintf('ctap_readbdf : Extracting events...');
thiscode = 0;
for p = 1:size(EEG.data, 2) - 1
    prevcode = thiscode;
    thiscode = mod(EEG.data(end, p), 256 * 256);
    if (thiscode ~= 0) && (thiscode ~= prevcode) 
        EEG.event(end + 1).latency = p;
        EEG.event(end).type = thiscode;
    end
end
EEG = pop_select(EEG, 'nochannel', EEG.nbchan);
EEG = eeg_checkset(EEG, 'makeur');


%% REFERENCE
if ~isempty(Arg.refchan)
    warning('ctap_readbdf:reref'...
        , 'Re-referencing to %s; note this will decrease matrix rank'...
        , num2str(Arg.refchan));
    EEG.data = EEG.data - ...
        repmat(mean(EEG.data(Arg.refchan, :), 1), [EEG.nbchan 1]);
end

