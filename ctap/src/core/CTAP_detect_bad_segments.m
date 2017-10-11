function [EEG, Cfg] = CTAP_detect_bad_segments(EEG, Cfg)
%CTAP_detect_bad_segments - Detect bad quality segments from continuous data
%
% Description:
%   Like CTAP_detect_bad_epochs() but works on continuous data and produces
%   variable length segments. Marks bad segments as events in EEG.event.
%
% Syntax:
%   [EEG, Cfg] = CTAP_detect_bad_segments(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_segments:
%   .method             string, Method to use, available {'quantileTh'},
%                       default: 'quantileTh'
%   .channels           cellstring, Channels to include in the analysis, 
%                       default: EEG.chanlocs.type == 'EEG'
%   .normalEEGAmpLimits [1,2] numeric, Normal EEG amplitude limits in muV,
%                       If data has been normalized the defaults will fail. 
%                       default: [-75, 75]
%   .badSegmentIDStr    string, Event id string for labeling the bad segments 
%                       detected. default: Cfg.event.badSegment
%   .plot               boolean, Should quality control figures be plotted?
%                       default: Cfg.grfx.on
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%   You might run high-pass filtering prior to this step.
%
% See also: eeglab_detect_extreme_amplitudes()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~ismatrix(EEG.data)
    error('CTAP_detect_bad_segments:dimension_err', 'Data must be continuous!')
end


%% Set optional arguments
Arg.method = 'quantileTh';
Arg.channels = {EEG.chanlocs(ismember({EEG.chanlocs.type}, 'EEG')).labels};
Arg.normalEEGAmpLimits = [-75, 75];
Arg.tailPercentage = 0.001;
Arg.coOcurrencePrc = 0.25;
Arg.badSegmentIDStr = Cfg.event.badSegment; %string
Arg.plot = Cfg.grfx.on;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_segments')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_segments);
end

%% ASSIST

% Running more than once without rejection in between not (yet) supported
if isfield(EEG.CTAP, 'badsegev')
    if isfield(EEG.CTAP.badsegev, 'detect')
        warning('CTAP_detect_bad_channels:runMoreThanOnce',...
            'Running CTAP_detect_bad_segments() more than once without rejection in between is not supported. Overwriting existing detections...');
    end
end

% Don't pay attention to any bad channels
if isfield(EEG.CTAP, 'badchans')
    if isfield(EEG.CTAP.badchans, 'detect')
        Arg.channels = setdiff(Arg.channels, EEG.CTAP.badchans.detect.chans);
    end
end


%% CORE

%detect bad segments
switch Arg.method
    case 'quantileTh'
        
        % mappings (from CTAP_*() input to method input, avoid these)
        Arg.rejectionChannels = Arg.channels; %todo: Change CTAP_*() function interface regarding channels?
        Arg.eventIDStr = Arg.badSegmentIDStr;
        
        varg_in = struct2varargin(Arg);
        [EEG, Rej] = eeglab_detect_extreme_amplitudes(EEG, varg_in{:});

        %parse the detection output
        numbad = sum(Rej.allChannelsMatch);
        Rej = rmfield(Rej, {'match','allChannelsMatch'});
        EEG.CTAP.badsegev.quantileTh.method_data = Rej; %not used by CTAP
            %Note: contains data only for channels listed in Arg.channels i.e.
            %      typically e.g. EOG and REF channels are missing.
        rtb = table(Rej.qntTh(:,1), Rej.qntTh(:,2),...
                    'VariableNames', {'ampth_low','ampth_up'},...
                    'RowNames', Arg.channels);
        EEG.CTAP.badsegev.quantileTh.scores = rtb; 
        EEG.CTAP.badsegev.quantileTh.evidstr = Arg.badSegmentIDStr;
    otherwise
        error('CTAP_detect_bad_segments:badArgument', 'Unrecognized argument.')
end


%% Set .detect field
% save the index of the badness for the CTAP_reject_data() function
prcbad = 100 * numbad / EEG.pnts;
EEG.CTAP.badsegev.detect.prc = prcbad;
EEG.CTAP.badsegev.detect.src = {Arg.method, 1};
% TODO(feature-request)(jkor): add option to run this function many times prior
% to rejection. Need to figure out a union of all detected bad segments... 
% Store event id strings for later use in CTAP_reject_data()


%% ERROR/REPORT
reportStr = sprintf(...
    ['Bad segments by ''%s'' for ''%s'': '...
    '%d segments involving %d/%d = %3.1f prc of samples marked as bad.'],...
    Arg.method, EEG.setname, Rej.allChannelsCount, numbad, EEG.pnts, prcbad);
msg = myReport({reportStr}, Cfg.env.logFile);

Cfg.ctap.detect_bad_segments = Arg;
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


end %of CTAP_detect_bad_segments()
