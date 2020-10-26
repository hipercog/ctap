function [EEG, Cfg] = CTAP_reject_data(EEG, Cfg)
%CTAPEEG_reject_data - Rejects detected bad channels, epochs, components or segments
%
% Description:
%   After calling CTAP_detect_*() this function can be used to reject the
%   detected channels, IC components, epochs or segments.%
%
% Syntax:
%   [EEG, Cfg] = CTAP_reject_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%   Cfg.ctap.reject_data:
%   .method     string, Which rejection to make, allowed values {'badchans',
%               'badepochs','badsegev','badcomps','autoselect'},
%               default: 'autoselect' which automatically selects first
%               valid detection for removal.
%   .plot       boolean, Should quality control (QC) figures be plotted?,
%               default: Cfg.grfx.on
%
% Notes: 
%       If Cfg.ctap.reject_data.method='autoselect' (default), then by
%       the function looks in following order for detected badness:
%           'badchans' - clean channels marked in EEG.CTAP.badchans.detect
%           'badepochs' - clean epochs marked in EEG.CTAP.badepochs.detect
%           'badsegev' - remove bad segments from continuous data based
%                           on events (adds boundary events)
%           'badcomps' - clean ICA comps marked in EEG.CTAP.badcomps.detect
%
%           The 'detect' field is removed after cleaning, so that a
%           given set of badness will only be cleaned once. Thus, normal
%           usage is to call pairs of CTAP_detect_*, CTAP_reject_data
%
% See also: ctapeeg_reject_data()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are the available bad data rejection methods - order is important!
rejmethods = {'badchans', 'badepochs', 'badsegev', 'badcomps'};


%% Set optional arguments
Arg.method = 'autoselect';
Arg.plot = Cfg.grfx.on;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'reject_data')
    Arg = joinstruct(Arg, Cfg.ctap.reject_data);
end


%% ASSIST
% autodetect the currently valid methods...
detected = isfield(EEG.CTAP, rejmethods);
for idx = find(detected)
    detected(idx) = isfield(EEG.CTAP.(rejmethods{idx}), 'detect');
end
not_rejected = find(detected);
if isempty(not_rejected)
    error('CTAP_reject_data:noDetectField', 'Can''t find detected badness.')
end

% pick the user's request, or autoselect first valid method
if strcmp(Arg.method, 'autoselect')
    Arg.method = rejmethods{not_rejected(1)};
else
    if ismember(Arg.method, rejmethods) % user specified method is valid
        if ~ismember(Arg.method, rejmethods{not_rejected})
            error('CTAP_reject_data:noDetectionData',...
              'No detection data for method ''%s''. Cannot proceed.', Arg.method);
        end
    else % user specified method is invalid
        error('CTAP_reject_data:badMethod',...
              'Unknown method ''%s''. Cannot proceed.', Arg.method);
    end 
end


try
    detected = EEG.CTAP.(Arg.method).detect;
    [badness, scores] = ctap_read_detections(EEG, Arg.method);
catch ME
    error('CTAP_reject_data:noDetectField',...
        '%s : %s results not defined...', ME.message, Arg.method);
end

EEG0 = EEG; %make a copy to allow for comparison


%% CORE
params = struct;
if detected.prc > 0 && detected.prc < 100
    
    if ismember(Arg.method, rejmethods)
        [EEG, params, result] = ctapeeg_reject_data(EEG,...
            'method', Arg.method,...
            'badness', badness);
    else
        myReport(sprintf('FAIL Unrecognised method - ''%s''. Step %d-reject'...
            , Arg.method, numel(EEG.CTAP.history)), Cfg.env.logFile);
    end

    msg = myReport(sprintf('%s from ''%s''.\n', result, EEG.setname)...
        , Cfg.env.logFile);
else
    msg = myReport(sprintf('WARN %s are %dprc bad: no rejection.',...
        strrep(Arg.method, 'bad', ''), detected.prc));
end


%% Diagnostics: plots & logs
if Arg.plot && detected.prc > 0
    savepath = get_savepath(Cfg, mfilename, 'qc', 'suffix', Arg.method);                  
    savepath = fullfile(savepath, EEG.CTAP.measurement.casename);
    prepare_savepath(savepath)

    myReport(sprintf('Plotting diagnostics to ''%s''...\n', savepath)...
        , Cfg.env.logFile);
                        
    switch Arg.method
        case 'badchans'
            sbf_plot_channel_rejections(EEG0, savepath)
            
        case 'badepochs'
            plotNsave_epoch(EEG0, badness, savepath, EEG0.setname...
                        , 'ctapMethod', detected.src{1})
    
        case 'badcomps'
            sbf_plotNsave_bad_ICs(EEG0, savepath)
            
            if contains(strjoin(detected.src(:,1),'-'), 'blink') &&...
                                ismember('blink', unique({EEG0.event.type}))
                sbf_plotNsave_blinkERP(EEG0, EEG, savepath)
            end
            
        case 'badsegev'
            sbf_plot_bad_segments(EEG0, savepath)
            
    end
end

% Log tables of badness
sbf_report_bad_data


%% Remove field "detect" 
EEG.CTAP.(Arg.method) = rmfield(EEG.CTAP.(Arg.method), 'detect');


%% ERROR/REPORT
if detected.prc == 100
    % A totally bad file should no longer be preprocessed
    error('CTAP_reject_data:badData',...
        'All data is bad by ''%s'': preprocessing ends.', Arg.method);
end
    
Arg = joinstruct(Arg, params);
    
Cfg.ctap.reject_data = Arg;

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% Subfunctions

%% sbf_plotNsave_blinkERP
function sbf_plotNsave_blinkERP(EEG0, EEG, savepath)
    if ~isfield(Cfg.eeg, 'veogChannelNames')
        warning('CTAP_reject_data:cfgFieldMissing',...
        'Field Cfg.eeg.veogChannelNames is needed to plot blink ERPs.');
    else
        
        % EEG channels for the blink ERP QC plots:
        blinkERPEEGChannels = horzcat(...
            get_channel_name_by_description(EEG, 'frontal'),...
            get_channel_name_by_description(EEG, 'vertex'));
        chanArr = horzcat(Cfg.eeg.veogChannelNames, blinkERPEEGChannels);
        chanMatch = ismember({EEG.chanlocs.labels}, chanArr);

        if sum(chanMatch)>0
            figH = ctap_eeg_compare_ERP(EEG0, EEG, {'blink'},...
                'idArr', {'before rejection','after rejection'},...
                'channels', {EEG.chanlocs(chanMatch).labels},...
                'visible', 'off');

            savename = [EEG.CTAP.measurement.casename, '_',...
                        Arg.method, '_blinkERP.png'];
            savefile = fullfile(savepath, savename);
            print(figH, '-dpng', savefile);
            close(figH);  
        else
            warning('CTAP_reject_data:channelsNotFound',...
                'Channels {%s} not found in EEG. Cannot plot blink ERP.',...
                strjoin(chanArr,', '));

        end %of chanMatch
    end %of test Cfg.eeg.veogChannelNames
end %of sbf_plotNsave_blinkERP()


%% sbf_plotNsave_bad_ICs
%plot scalp maps, erpimages, spectra of ALL bad components
function sbf_plotNsave_bad_ICs(EEG0, savepath)
    %get bad IC indices
    comps = badness;
    chans = get_eeg_inds(EEG0, 'EEG');
    %make output dir path
    
    for i = 1:numel(comps)
        
        ICscore = scores(comps(i), :);
        figH = ctap_ic_plotprop(EEG0, comps(i)...
            , 'topoplot', {'plotchans', chans}...
            , 'spectopo', {'freqrange', [1 50]}...
            , 'visible', 'off');%...
%TODO(feature request)(BEN): UNCOMMENT WHEN THE METHOD DATA SUBPLOT LOOKS PRETTY
%             , 'stats', ICscore);

        %save the figure out
        saveas(figH, fullfile(savepath, sprintf('IC%d', comps(i)) ), 'png');
        close(figH);
        
    end %of comps
end %sbf_plotNsave_bad_ICs()


%% sbf_plot_channel_rejections
% Visualize channel rejections
function sbf_plot_channel_rejections(EEG0, savepath)
    chs = {EEG0.chanlocs(get_eeg_inds(EEG0, 'EEG')).labels};
    plotNsave_raw(EEG0, savepath, EEG0.setname,...
                  'channels', chs,...
                  'markChannels', badness)

    % PLOT SCALP OF BADNESS LOCATIONS
    ctap_plot_bad_chan_scalp(EEG0...
        , find(ismember({EEG0.chanlocs.labels}, badness))...
        , 'context', 'scalp'...
        , 'savepath', savepath)

end %sbf_plot_channel_rejections()


%% sbf_plot_bad_segments
% Visualize segment rejections
function sbf_plot_bad_segments(EEG0, savepath)
    
    evMatch = ismember({EEG0.event.type}, EEG0.CTAP.badsegev.quantileTh.evidstr);
    ev = EEG0.event(evMatch);
    inds = get_eeg_inds(EEG0, 'EEG');
    %save a bunch of pngs to a unique subdirectory.
    for i = 1:numel(ev)
        timeres = 'sec';
        if ev(i).duration < EEG0.srate
            timeres = 'ms';
        end
        extraWinSec = min(max(ev(i).duration / EEG0.srate, 1), 3);
        %use our excellent homemade raw data plotter
        figH = plot_raw(EEG0, ...
            'channels', {EEG0.chanlocs(inds).labels},...
            'startSample', max(1, ev(i).latency - extraWinSec * EEG0.srate),...
            'secs', ev(i).duration / EEG0.srate + 2 * extraWinSec,...
            'boxLimits', [ev(i).latency, ev(i).latency + ev(i).duration],...
            'timeResolution', timeres,...
            'paperwh', [-1 -1],...
            'figVisible', 'off');
        % Saves images as separate pngs to save time
        if ~isempty(figH)
            saveas(figH, fullfile(savepath, sprintf('Badseg_%d.png', i) ), 'png')
            close(figH);
        end
    end
    
end %sbf_plot_bad_segments()


%% sbf_report_bad_data
function sbf_report_bad_data

    badname = [Arg.method '_' EEG.CTAP.subject.subject];
    func = sprintf('s%df%d', Cfg.pipe.current.set, Cfg.pipe.current.funAtSet);
    if isempty(badness)
        bdstr = 'none'; %a placeholder to keep the variable type consistent
    elseif ~iscellstr(badness) %#ok<ISCLSTR>
            bdstr = num2str(badness, 3);
    else
            bdstr = strjoin(badness);
    end
    rejfile =...
        fullfile(Cfg.env.paths.qualityControlRoot, [badname '_rejections.mat']);

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
                                detected.prc);

    else
        %create table from scratch
        rejtab = table({bdstr}, {detected.prc},...
            'RowNames', {EEG.CTAP.measurement.casename},...
            'VariableNames', {[func '_' Arg.method], [func '_pc']}); %#ok<*NASGU>
    end

    save(rejfile, 'rejtab');
end %sbf_report_bad_data()

end %CTAP_reject_data()
