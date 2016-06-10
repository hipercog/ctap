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
%   .method         string, Method to use, available {'quantileTh'},
%                   default: 'quantileTh'
%   .channels       cellstring, Channels to include in the analysis, 
%                   default: {EEG.chanlocs(ismember({EEG.chanlocs.type},'EEG')).labels};
%   .amplitudeTh    [1,2] numeric, Amplitude threshold values in current 
%                   EEG data units, If data has been normalized the defaults
%                   will fail. default: [-75, 75]
%   .badSegmentIDStr    string, Event id string for labeling the bad segments 
%                       detected. default: Cfg.event.badSegment
%   .plot           boolean, Should quality control figures be plotted?
%                   default: Cfg.grfx.on
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
eegChanMatch = ismember({EEG.chanlocs.type},'EEG');
Arg.channels = {EEG.chanlocs(eegChanMatch).labels};
Arg.amplitudeTh = [-75, 75];
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
switch Arg.method
    case 'quantileTh'
        [EEG, Rej] = eeglab_detect_extreme_amplitudes(EEG,...
                    'rejectionChannels', Arg.channels,...
                    'defaultAmpLimits', Arg.amplitudeTh,....
                    'eventIDStr', Arg.badSegmentIDStr);
        numbad = sum(Rej.allChannelsMatch);
        Rej = rmfield(Rej, {'match','allChannelsMatch'});
        EEG.CTAP.badsegev.quantileTh.method_data = Rej; %not used by CTAP
        %Note: contains data only for channels listed in Arg.channels i.e.
        %typically e.g. EOG and REF channels are missing.
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

% 
% %% DIAGNOSTICS
% if Arg.plot && (prcbad > 0)
%     sbf_plot_bad_segments(EEG, Cfg, Arg)
% else
%     myReport(sprintf('\n'), Cfg.env.logFile);
% end
% 
% 
% %% Subfunctions
% 
% % Visualize segment rejections
% function sbf_plot_bad_segments(EEG, Cfg, Arg)
%     savedir = get_savepath(Cfg, mfilename);
%     evMatch = ismember({EEG.event.type}, Arg.badSegmentIDStr);
%     ev = EEG.event(evMatch);
%     extraWinSec = 2;
%     id = sprintf('%s_%s', EEG.CTAP.measurement.casename, Arg.method);
%     if numel(ev) > 1
%         savedir = fullfile(savedir, id);
%         if ~isdir(savedir), mkdir(savedir); end
%         id = '';
%     end
%     myReport(sprintf('Plotting diagnostics to ''%s''...\n', savedir)...
%         , Cfg.env.logFile);
%     %save a bunch of pngs to a unique subdirectory.
%     for i = 1:numel(ev)
%         figH = plot_raw(EEG, ...
%             'channels', {EEG.chanlocs(get_eeg_inds(EEG, {'EEG' 'EOG'})).labels},...
%             'startSample', max(1, ev(i).latency - extraWinSec * EEG.srate),...
%             'secs', ev(i).duration / EEG.srate + 2 * extraWinSec,...
%             'shadingLimits', [ev(i).latency, ev(i).latency + ev(i).duration],...
%             'figVisible', 'off');
%         set(figH, 'Position', [2000, 250, 600, 800])
%         % Saves images as separate pngs to save time
%         saveas(figH, fullfile(savedir, [id sprintf('Badseg_%d.png', i)]), 'png')
%         close(figH);
%     end
% end

end %of CTAP_detect_bad_segments()
