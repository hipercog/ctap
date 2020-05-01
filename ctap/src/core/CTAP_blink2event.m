function [EEG, Cfg] = CTAP_blink2event(EEG, Cfg)
%CTAP_blink2event  - Detect blinks and add them as events
%
% Description:
%   Adds blinks as events in EEG.event. Gets VEOG and HEOG channel names
%   from Cfg.eeg.veog/heogChannelNames.
%   Assumes blink signal to have a positive notch at blink positions i.e.
%   either Cfg.eeg.veogChannelNames contains a channel name that conforms
%   to this specification or
%   Cfg.eeg.veogChannelNames(1) - Cfg.eeg.veogChannelNames(2) is such a
%   signal. If this is not the case use the varargin "invert".
%
% Syntax:
%   [EEG, Cfg] = CTAP_blink2event(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.blink2event:
%   invert      boolean, If true, inverts the EOG signal polarity,
%               default = false
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: eeglab_extract_eog()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.invert_polarity = false;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'blink2event')
    Arg = joinstruct(Arg, Cfg.ctap.blink2event); %override with user params
end


%% ASSIST
if ~isfield(Cfg.eeg, 'veogChannelNames')
   warning('CTAP_blink2event:cfgFieldMissing',...
     'Field Cfg.eeg.veogChannelNames needed for EOG extraction. Cannot proceed.');
end

if ~isfield(Cfg.eeg, 'heogChannelNames')
   error('CTAP_blink2event:cfgFieldMissing',...
     'Field Cfg.eeg.heogChannelNames needed for EOG extraction. Cannot proceed.');
end


%% CORE
Eog = eeglab_extract_eog(EEG,...
                        Cfg.eeg.veogChannelNames,...
                        Cfg.eeg.heogChannelNames);
                    
if Arg.invert_polarity
    EEG = eeglab_blink2event(EEG, -Eog.veog, rmfield(Arg, 'invert_polarity'));
else 
    EEG = eeglab_blink2event(EEG, Eog.veog, rmfield(Arg, 'invert_polarity'));
end

%% ERROR/REPORT
Cfg.ctap.blink2event = Arg;

msg = myReport(['Added blinks as events for ' EEG.subject ' - ' EEG.setname]...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

% PLOTS
if isfield(EEG.CTAP, 'detected')
    if isfield(EEG.CTAP.detected, 'blink')
        
        % Plot blink detection criterion values and grouping
        figH = figure(  'Visible', 'off',...
                        'PaperUnits', 'normalized',...
                        'PaperType', 'a4',...
                        'PaperPosition', [0 0 0.8 0.3] );
        y = randn(1, length(EEG.CTAP.detected.blink.QCData.criterionValue));
        x = EEG.CTAP.detected.blink.QCData.criterionValue;
        plot(x(EEG.CTAP.detected.blink.QCData.isBlink)...
           , y(EEG.CTAP.detected.blink.QCData.isBlink)...
           , 'ro'...
           , x(~EEG.CTAP.detected.blink.QCData.isBlink)...
           , y(~EEG.CTAP.detected.blink.QCData.isBlink)...
           , 'ko');
        legend('blink','non-blink')
        ylabel('Arbitrary units');
        xlabel(sprintf('Value of %s',...
            EEG.CTAP.detected.blink.QCData.criterionName));
        title('Blink detection criterion values (y-jittered)')
        set(gca, 'YTickLabel', '');
        
        savename = [EEG.CTAP.measurement.casename, '_blink_criterion.png'];
        savefile = fullfile(get_savepath(Cfg, mfilename, 'qc'), savename);
        print(figH, '-dpng', savefile);
        close(figH);
        
        % Plot ERP of detected blinks
        eegep = pop_epoch(EEG, {'blink'}, [-0.3 0.3]);
        
        chixv = get_eeg_inds(EEG, Cfg.eeg.veogChannelNames);
        chixh = get_eeg_inds(EEG, Cfg.eeg.heogChannelNames);
        chinds = union(chixv, chixh);
        figH = plot_epoched_EEG({eegep},...
                        'channels', {EEG.chanlocs(chinds).labels},...
                        'idArr', {'detected blinks'},...
                        'visible', 'off');
        
        savename = [EEG.CTAP.measurement.casename, '_blink_ERP.png'];
        savefile = fullfile(get_savepath(Cfg, mfilename, 'qc'), savename);
        print(figH, '-dpng', savefile);
        close(figH);
    end
end
