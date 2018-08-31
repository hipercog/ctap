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
%   .refChannel     cellstring, {'Fz'}
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
if isfield(Cfg.eeg, 'chanlocs')
    Arg.refChannel = {EEG.chanlocs(get_refchan_inds(EEG, 'frontal')).labels};
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_channels')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_channels); %override w user params
end

%% ASSIST
if ~isfield(Arg, 'channels')
    Arg.channels = find(ismember({EEG.chanlocs.type}, Arg.channelType));
end

% Check that given channels are EEG channels
if isempty(Arg.channels) ||...
        sum(strcmp('EEG', {EEG.chanlocs.type})) < length(Arg.channels)
    myReport(['WARN CTAP_detect_bad_channels:: '...
        'EEG channel type has not been well defined,'...
        ' or given channels are not all EEG!'], Cfg.env.logFile);
end


%% CORE
[EEG, params, result] = ctapeeg_detect_bad_channels(EEG, Arg);

Arg = joinstruct(Arg, params);


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
if Arg.plot_detections
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