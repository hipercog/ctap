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
%                   analyzed, overrides .channelType, default: inherits channelType
%   .channelType    string or cellstring, A list of channel type string that
%                   specify which channels are to be analyzed, default: 'EEG'
%   .orig_ref       cellstring, Original reference channels, needed by some
%                   methods that rereference the data, default: Cfg.eeg.reference
%   .refChannel     cellstring, reference channel name for FASTER
%                   default: get_refchan_inds(EEG, 'frontal')
%   .method         string, Detection method, either use 'given' for method and set 
%                   .source parameter (see below), or else read available methods in
%                       ctapeeg_detect_bad_channels.m
%   .source         string, either name of a csv file that lives at your dataRoot,
%                   or name of a field in your measurement config file
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
Arg.source = NaN;

Arg.plot_detections = Cfg.grfx.on;
if isfield(Cfg.eeg, 'reference')
    Arg.orig_ref = Cfg.eeg.reference;
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_channels')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_channels); %override w user params
end


%% ASSIST
rept = {''};
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
    rept{1} = myReport(['WARN ' mfilename ':: '...
        'EEG channel type has not been well defined,'...
        ' or given channels are not all EEG!']);
end

% Don't pay attention to any deliberately-excluded channels
if isfield(Arg, 'badchannels')
    Arg.channels = setdiff(Arg.channels, Arg.badchannels);
end

% re-reference if requested
% TODO: check if temp ref field is specified
if isfield(Arg, 'orig_ref') && ~isempty(Arg.orig_ref)
    EEG = pop_reref(EEG, [], 'refloc', EEG.chanlocs(ismember(...
        {EEG.chanlocs.labels}, Arg.orig_ref)));
end

% remove blink segments if requested and blink events exist
% TODO


%% CORE
if strcmpi(Arg.method, 'given')
    if exist(Arg.source, 'file')
        gch = readtable(Arg.source...
            , 'delimiter', ',', 'ReadRowNames', 1, 'ReadVariableNames', 0);
        idx = cellfun(@(x) contains(Cfg.measurement.subject, x), gch.Properties.RowNames);
        if sum(idx) > 1
            error('CTAP_detect_bad_channels:bad_channel_data_duplicate'...
                , 'Subj:%s matched %d rows in given data; ABORTING!'...
                , Cfg.measurement.subject, sum(idx))
        elseif sum(idx) == 1
            gch = strsplit(gch{idx, :}{:});
        else
            gch = '';
        end
    elseif isfield(Cfg.measurement, Arg.source)
        gch = strsplit(Cfg.measurement.(Arg.source));
    else
        error('CTAP_detect_bad_channels:insufficient_parameters'...
            , ['You must pass a valid source of bad channels to this method'...
              ': either CSV file or measurement config field'])
    end
    if isempty(gch)
        warning('CTAP_detect_bad_channels:no_bad_channel_data'...
            , 'No entry for subj:%s in given data', Cfg.measurement.subject)
    else
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
rept{end + 1} = sprintf('Bad channels by ''%s'' for ''%s'': ', Arg.method, EEG.setname);
rept{end + 1} = {'JUST FOUND : ' result.chans}; %just found bad chans
rept{end + 1} = {'TOTAL : ' EEG.CTAP.badchans.(Arg.method).chans}; %all by Arg.method
if numel(rept{end}) == numel(rept{end - 1})
    rept{end} = '';
end
prcbad = 100 * numbad / sum(ismember({EEG.chanlocs.type}, 'EEG'));
if prcbad > 10
    rept{end - 2} = ['WARN ' rept{end - 2}];
end
rept{end + 1} = sprintf('\nTOTAL %d/%d = %3.1f prc of channels marked to reject\n'...
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

msg = myReport(rept);
%myReport(msg, Cfg.env.logFile)

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, params);

if ~Cfg.parafor
    sbf_report_bad_data() % this will not work under parallel processing
end


%% sbf_report_bad_data - store detected channels for later review
function sbf_report_bad_data

    func = sprintf('s%df%d', Cfg.pipe.current.set, Cfg.pipe.current.funAtSet);
    bdstr = result.chans;
    if isempty(bdstr)
        bdstr = 'none'; %a placeholder to keep the variable type consistent
    else
        bdstr = strjoin(bdstr);
    end
    rejfile = fullfile(Cfg.env.paths.qualityControlRoot...
            , [Arg.method '_badchan_detections.mat']);

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