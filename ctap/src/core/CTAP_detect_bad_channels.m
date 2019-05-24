function [EEG, Cfg] = CTAP_detect_bad_channels(EEG, Cfg)
%CTAP_detect_bad_channels  - Autodetect bad quality channels
%
% Description:
%   Requires channel locations and types. These can be added using
%   CTAP_load_chanlocs().
%
% Syntax:
%   [EEG, Cfg] = CTAP_detect_bad_channels(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_channels:
%   .channels       cellstring, A list of channels which should be
%                   analyzed, overrides .channelType, default: field does
%                   not exist
%   .channelType    string or cellstring, A list of channel type string that
%                   specify which channels are to be analyzed, default: 'EEG'
%   .orig_ref       cellstring, Original reference channels, needed by some
%                   methods that rereference the data, default: Cfg.eeg.reference
%   .refChannel     cellstring, reference channel name for FASTER
%                   default: get_refchan_inds(EEG, 'frontal')
%   .method         string, Detection method, see
%                   ctapeeg_detect_bad_channels.m for available methods.
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_detect_bad_channels()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.channelType = 'EEG';

Arg.plot_detections = Cfg.grfx.on;
if isfield(Cfg.eeg, 'reference')
    Arg.orig_ref = Cfg.eeg.reference;
end
%NOTE: removed the default refchan here since it is replicated (where
%      needed) in 'ctapeeg_detect_bad_channels'
% if isfield(Cfg.eeg, 'chanlocs')
%     Arg.refChannel = {EEG.chanlocs(get_refchan_inds(EEG, 'frontal')).labels};
% end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_channels')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_channels); %override w user params
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

% Don't pay attention to any deliberately-excluded channels
if isfield(Arg, 'badchannels')
    Arg.channels = setdiff(Arg.channels, Arg.badchannels);
end


%% CORE
if strcmpi(Arg.method, 'given')
    if isfield(Arg, 'badChanCsv')
        gch = readtable(Arg.badChanCsv, 'delimiter', ',', 'ReadRowNames', 1);
    else
        error('CTAP_detect_bad_channels:insufficient_parameters'...
            , 'You must pass a valid CSV file of bad channels to this method')
    end
    idx = cellfun(@(x) contains(Cfg.measurement.subject, x), gch.Properties.RowNames);
    if ~any(idx)
        warning('CTAP_detect_bad_channels:no_bad_channel_data'...
            , 'No entry for subj:%s in given data', Cfg.measurement.subject)
        gch = '';
    elseif sum(idx) > 1
        warning('CTAP_detect_bad_channels:bad_channel_data_duplicate'...
            , 'Subj:%s matched %d rows in given data; using first BUT CHECK!'...
            , Cfg.measurement.subject, sum(idx))
        gch = strsplit(gch{find(idx, 1), :}{:});
    else
        gch = strsplit(gch{idx, :}{:});
    end
    % First check if all exist as labels in EEG.chanlocs
    idx = ismember(gch, {EEG.chanlocs(chidx).labels});
    if any(idx)
        result.chans = gch(idx);
    elseif ~any(isnan(str2double(gch))) && any(ismember(str2double(gch), chidx))
        %all are numbers - treat as indices
        gch = str2double(gch);
        result.chans = {EEG.chanlocs(gch(ismember(gch, chidx))).labels};
    else
        result.chans = '';
        warning('CTAP_detect_bad_channels:check_bad_chan_file'...
            , 'Given bad channels do not index any existing channels!')
    end
    result.method_data = 'user_given_bad_channels';
    result.scores = table(ismember({EEG.chanlocs(chidx).labels}, gch)'...
        , 'RowNames', {EEG.chanlocs(chidx).labels}'...
        , 'VariableNames', {'given_bad_IC'});
    params = Arg;
else
    [EEG, params, result] = ctapeeg_detect_bad_channels(EEG, Arg);

    Arg = joinstruct(Arg, params);
end


%% PARSE RESULT
% Checking and fixing
if ~isfield(EEG.CTAP, 'badchans') 
    EEG.CTAP.badchans = struct;
end
if ~isfield(EEG.CTAP.badchans, Arg.method) 
    EEG.CTAP.badchans.(Arg.method) = result;
else
    EEG.CTAP.badchans.(Arg.method)(end+1) = result;
end

% save the index of the badness for the CTAP_reject_data() function
if isfield(EEG.CTAP.badchans, 'detect')
    EEG.CTAP.badchans.detect.src = [EEG.CTAP.badchans.detect.src;...
        {Arg.method, length(EEG.CTAP.badchans.(Arg.method))}];
    [numbad, ~] = ctap_read_detections(EEG, 'badchans');
    numbad = numel(numbad);
else
    EEG.CTAP.badchans.detect.src =...
        {Arg.method, length(EEG.CTAP.badchans.(Arg.method))};
    numbad = numel(result.chans);
end

% Describe results
rept1 = sprintf('Bad channels by ''%s'' for ''%s'': ', Arg.method, EEG.setname);
rept2 = {'JUST FOUND : ' result.chans}; %just found bad chans
rept3 = {'TOTAL : ' EEG.CTAP.badchans.(Arg.method).chans}; %all by Arg.method
if numel(rept3) == numel(rept2)
    rept3 = '';
end
prcbad = 100 * numbad / EEG.nbchan;
if prcbad > 10
    rept1 = ['WARN ' rept1];
end
rept4 = sprintf('\nTOTAL %d/%d = %3.1f prc of channels marked to reject\n'...
    , numbad, EEG.nbchan, prcbad);

EEG.CTAP.badchans.detect.prc = prcbad;


%% PLOT BADNESS
savepath = get_savepath(Cfg, mfilename, 'qc', 'suffix', Arg.method);  
% Plot threshold
if isfield(result.method_data, 'th')    
    if isfield(result.method_data.th, 'figtitle')
        titlestr = result.method_data.th.figtitle;
    else
        titlestr = sprintf('Bad channel detection, method: %s', Arg.method);
    end
    title(get(result.method_data.th.figh, 'CurrentAxes'), titlestr);
    
    print(result.method_data.th.figh, '-dpng', fullfile(savepath...
        , [EEG.CTAP.measurement.casename, '_', Arg.method, '_threshold.png']));
    close(result.method_data.th.figh);
end

% Plot scalpmap of bad channels just discovered
if Arg.plot_detections && ~isempty(result.chans)
    figh = ctap_plot_bad_chan_scalp(EEG...
        , get_eeg_inds(EEG, result.chans)...
        , 'context', Arg.method...
        , 'savepath', savepath); %#ok<*NASGU>
end


%% ERROR/REPORT
Cfg.ctap.detect_bad_channels = params;

msg = myReport({rept1 rept2 rept3 rept4}, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, params);

sbf_report_bad_data(); %store detected channels for later review


%% sbf_report_bad_data
function sbf_report_bad_data

    func = sprintf('s%df%d', Cfg.pipe.current.set, Cfg.pipe.current.funAtSet);
    bdstr = result.chans;
    if isempty(bdstr)
        bdstr = 'none'; %a placeholder to keep the variable type consistent
    else
        bdstr = strjoin(bdstr);
    end
    rejfile =...
        fullfile(Cfg.env.paths.qualityControlRoot, [Arg.method '_detections.mat']);

    if exist(rejfile, 'file')
        tmp = load(rejfile, 'rejtab');
        rejtab = tmp.rejtab;

        %assign into appropriate columns/rows
        rejtab = upsert2table(  rejtab,...
                                sprintf('%s_%s', func, Arg.method),...
                                EEG.CTAP.measurement.casename,...
                                bdstr);
        
        rejtab = upsert2table(  rejtab,...
                                sprintf('%s_pc', func),...
                                EEG.CTAP.measurement.casename,...
                                prcbad);

    else
        %create table from scratch
        rejtab = table({bdstr}, {prcbad},...
            'RowNames', {EEG.CTAP.measurement.casename},...
            'VariableNames', {[func '_' Arg.method], [func '_pc']}); %#ok<*NASGU>
    end

    save(rejfile, 'rejtab');
end %of sbf_report_bad_data()

end