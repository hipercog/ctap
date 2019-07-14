function mul = eeglab2mul(EEG, varargin)
%eeglab2mul - Write epoched EEG data into a mul struct for export to BESA
%
% Description:
%   .
%
% Syntax:
%   mul = eeglab2mul(EEG, varargin)
%
% Inputs:
%   EEG         struct, EEGLAB structure with _epoched_ data
% Varargin
%   lock_event  string, event to create average, default = ''
%
% Outputs:
%   mul-format structure to be exported to disk for e.g. BESA
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2016 FIOH:
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('lock_event', @(x) ischar(x) || isstruct(x));

p.parse(EEG, varargin{:});
Arg = p.Results;


if ~ismatrix(EEG.data)
    if ~ismember({EEG.event.type}, Arg.lock_event)
        error('eeglab2mul:bad_event_name', ['Event name %s was'...
            ' not found in the event structure: cannot export'], lock_event)
    end
    %average data for lock_event event here
    idx = get_event_epochIdx(EEG, Arg.lock_event);
    epx = EEG.data(get_eeg_inds(EEG, 'EEG'), :, idx);
    eegdata = mean(epx, 3)';
else
    eegdata = EEG.data(get_eeg_inds(EEG, 'EEG'), :)';
end
%make structure to feed to matrixToMul
mul = struct(...
    'data', eegdata,...
    'Npts', EEG.pnts,...
    'TSB', EEG.xmin * 1000,...
    'DI', 1000 / EEG.srate,...
    'Scale', 1.0,...
    'ChannelLabels', {{EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels}});
