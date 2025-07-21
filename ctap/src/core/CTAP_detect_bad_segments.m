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
%   .exclude_channels   cellstring, Channels to exclude from the analysis, will 
%                       include channels marked bad in EEG.CTAP.badchans.detect
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
Arg.channelType = 'EEG';
Arg.exclude_channels = {};
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
if ~isfield(Arg, 'channels')
    chidx = get_eeg_inds(EEG, Arg.channelType);
    Arg.channels = {EEG.chanlocs(chidx).labels};
elseif isnumeric(Arg.channels)
    chidx = Arg.channels;
    Arg.channels = {EEG.chanlocs(chidx).labels};
else
    chidx = get_eeg_inds(EEG, Arg.channels);
end

% Check that given channels are EEG channels
if isempty(Arg.channels) || ~all(ismember({EEG.chanlocs(chidx).type}, 'EEG'))
    myReport(['WARN ' mfilename ':: '...
        'EEG channel type has not been well defined,'...
        ' or given channels are not all EEG!'], Cfg.env.logFile);
end

% Running more than once without rejection in between not (yet) supported
if isfield(EEG.CTAP, 'badsegev') && isfield(EEG.CTAP.badsegev, 'detect')
    warning('CTAP_detect_bad_channels:runMoreThanOnce',...
        ['Running CTAP_detect_bad_segments() more than once without rejection'...
        ' in between is not supported. Overwriting existing detections...']);
end

% Don't pay attention to any bad or deliberately-excluded channels
if isfield(EEG.CTAP, 'badchans') && isfield(EEG.CTAP.badchans, 'detect')
    Arg.exclude_channels =...
        union(Arg.exclude_channels, EEG.CTAP.badchans.detect.chans);
end
Arg.channels = setdiff(Arg.channels, Arg.exclude_channels);


%% CORE

%detect bad segments
switch Arg.method

    case 'given'
        if isfield(Arg, 'badSegsFile') && strcmpi(Arg.badSegsFile(end-2:end), 'csv')
            tbl = readtable(Arg.badSegsFile, "Delimiter", ' ');
        else
            error('CTAP_detect_bad_segments:insufficient_parameters'...
                , 'You must pass a file of bad segments to use this method');
        end
        gsg = table2array(tbl(ismember(tbl{:,1}, Cfg.measurement.casename), 2:end));
        if mod(numel(gsg), 2) ~= 0
            error('CTAP_detect_bad_segments:segments_misspecified'...
                , 'Bad segments file must have even number of start/stop times');
        end
        switch tbl.Properties.VariableNames{2}
            case 'sec'
                unit_mult = 1000;

            case {'ms' 'milli'}
                unit_mult = 1;

            case 'Var2'
                unit_mult = 1000 ^ single(any(mod(gsg, 1) ~= 0));%detects decimals
        end
        gsg = reshape(gsg, 2, numel(gsg) / 2)' .* unit_mult;
        gsg(all(isnan(gsg), 2), :) = [];
        rej_match = false(1, EEG.pnts);
        rej_inds = zeros(size(gsg, 1), 2);
        for i = 1:size(gsg, 1)
            if any(isnan(gsg(i, :)))
                continue
            end
            rej_inds(ceil(i / 2), 1) = find(EEG.times >= gsg(i, 1), 1);
            rej_inds(ceil(i / 2), 2) = find(EEG.times < gsg(i, 2), 1, 'last');
            rej_match(EEG.times >= gsg(i, 1) & EEG.times <= gsg(i, 2)) = true;

        end
        numbad = sum(rej_match);

        if numbad > 0
            rej_inds(all(rej_inds == 0, 2), :) = [];
            durat = rej_inds(:,2) - rej_inds(:,1) + 1;
            bs_count = numel(durat);
            bs_event = eeglab_create_event(rej_inds(:,1), Arg.badSegmentIDStr,...
                                            'duration', num2cell(durat));
            if ~isempty(EEG.event)
                EEG.event = eeglab_merge_event_tables(EEG.event, bs_event, 'ignore');
            else
                EEG.event = eeglab_merge_event_tables(bs_event, 'ignore');
            end
            rej_table = table(gsg(:, 1)', gsg(:, 2)', durat.*1000/EEG.srate...
                , rej_inds(:,1), rej_inds(:,2), durat...
                , 'RowNames', cellstr(num2str((1:numel(durat))'))...
                , 'VariableNames', {'ms_beg' 'ms_end' 'ms_dur' 'lat_beg' 'lat_end' 'lat_dur'});
        else
            bs_count = numbad;
            rej_table = table;
            fprintf('No artefactual segments given for %s.', Cfg.measurement.casename)
        end

    case 'quantileTh'
        
        % mappings (from CTAP_*() input to method input, avoid these)
        Arg.rejectionChannels = Arg.channels; 
        %todo FIXME: Change CTAP_*() function interface regarding channels?
        Arg.eventIDStr = Arg.badSegmentIDStr;
        
        varg_in = struct2varargin(Arg);
        [EEG, Rej] = eeglab_detect_extreme_amplitudes(EEG, varg_in{:});

        %parse the detection output
        numbad = sum(Rej.allChannelsMatch);
        Rej = rmfield(Rej, {'match','allChannelsMatch'});
        EEG.CTAP.badsegev.quantileTh.method_data = Rej; %not used by CTAP
            %Note: contains data only for channels listed in Arg.channels i.e.
            %      typically e.g. EOG and REF channels are missing.
        rej_table = table(Rej.qntTh(:,1), Rej.qntTh(:,2),...
                    'VariableNames', {'ampth_low','ampth_up'},...
                    'RowNames', Arg.channels);
        bs_count = Rej.allChannelsCount;
        
    otherwise
        error('CTAP_detect_bad_segments:badArgument', 'Unrecognized argument.')
end
% TODO FIXME : combine shared code from GIVEN method and QUANTILE method
% (inc. in eeglab_detect_extreme_amplitudes.m)


%% Set .detect field
% save the index of the badness for the CTAP_reject_data() function
EEG.CTAP.badsegev.(Arg.method).scores = rej_table;
EEG.CTAP.badsegev.(Arg.method).evidstr = Arg.badSegmentIDStr;
prcbad = 100 * numbad / EEG.pnts;
EEG.CTAP.badsegev.detect.prc = prcbad;
EEG.CTAP.badsegev.detect.src = {Arg.method, 1};
% TODO(feature-request)(jkor): add option to run this function many times prior
% to rejection. Need to figure out a union of all detected bad segments... 
% Store event id strings for later use in CTAP_reject_data()


%% ERROR/REPORT
reportStr = sprintf(['Bad segments by ''%s'' for ''%s'':'...
    ' %d segments involving %d/%d = %3.1f prc of samples marked as bad.']...
    , Arg.method, EEG.CTAP.measurement.casename, bs_count, numbad, EEG.pnts, prcbad);
msg = myReport({reportStr}, Cfg.env.logFile);

Cfg.ctap.detect_bad_segments = Arg;
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


end %of CTAP_detect_bad_segments()
