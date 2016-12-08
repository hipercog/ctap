function [EEG, Cfg] = CTAP_filter_blink_ica(EEG, Cfg)
%CTAP_filter_blink_ica - FIR filter blink related ICA components using firfilt plugin
%
% Description:
%   Can be used to filter ICA components to remove blink related activity.
%   Reconstructs EEG.data using the filtered ICA components.
%
% Syntax:
%   [EEG, Cfg] = CTAP_filter_blink_ica(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.filter_blink_ica:
%   .cutoff     numeric, high pass filter cutoff frequency in Hz, default: 10
%   .transBandWidth     numeric, transition band width in Hz, default: 1
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2016 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.cutoff = 10; % high pass filter cutoff frequency in Hz
Arg.transBandWidth = 1; % transition band width in Hz

% Override defaults with user parameters
if isfield(Cfg.ctap, 'filter_blink_ICA')
    Arg = joinstruct(Arg, Cfg.ctap.filter_blink_ICA); %override with user params
end


%% CORE
EEG0 = EEG; 
cmpidx = EEG.CTAP.badcomps.blink_template.comps;


% Plot blink related ICs
chans = get_eeg_inds(EEG0, {'EEG'});

for i = 1:numel(cmpidx)

    figH = ctap_ic_plotprop(EEG0, cmpidx(i)...
        , 'topoplot', {'plotchans', chans}...
        , 'spectopo', {'freqrange', [1 50]}...
        , 'visible', 'off');%...

    %save the figure out
    savepath = get_savepath(Cfg, mfilename, 'qc', ...
                            'suffix', 'blinkICs');
    savepath = fullfile(savepath, EEG.CTAP.measurement.casename);
    prepare_savepath(savepath);
    saveas(figH, fullfile(savepath, sprintf('IC%d', cmpidx(i)) ), 'png');
    close(figH);

end %of comps


% Make dummy dataset to be able to use firfilt plugin directly
icaact = eeg_getica(EEG);
TMP = create_eeg(icaact(cmpidx,:),...
                'fs', EEG.srate);
            
% Filter
m  = pop_firwsord('hamming', TMP.srate, Arg.transBandWidth);
b  = firws(m, Arg.cutoff / (TMP.srate / 2), 'high', windows('hamming', m + 1));
TMPf = firfilt(TMP, b);

% Substitute filtered verions for blink related IC's 
icaact(cmpidx,:) = TMPf.data;

% Reconstruct data
EEG.data(EEG.icachansind, :) = EEG.icawinv * icaact; %ICA computed for some channels only
%todo: what is the canonical EEGLAB way of doing this?

% Debug:
%Arg.cutoff = 10;
%Arg.transBandWidth = 1;

%ctap_eegplot(ICA);

%ctap_eegplot(TMP);
%ICA = create_eeg(icaact,...
%                'fs', EEG.srate);

%ctap_eegplot(TMPf);

%ctap_eegplot(EEG0);
%ctap_eegplot(EEG);

%{
si = fix(TMP.srate * 651);
ei = fix(TMP.srate * 653);
plot(TMP.times(si:ei), TMP.data(1, si:ei))
hold on;
plot(TMPf.times(si:ei), TMPf.data(1, si:ei), 'color', 'red');
hold off;
%}

%% Plot blink ERP
if ~isfield(Cfg.eeg, 'veogChannelNames')
    
    warning('CTAP_filter_blink_ICA:cfgFieldMissing',...
    'Field Cfg.eeg.veogChannelNames is needed to plot blink ERPs.');

else

    figh = ctap_eeg_blink_ERP(EEG0, EEG, Cfg.eeg.veogChannelNames,...
                        'dataSetLabels', {'Before correction','After correction'});

    savepath = get_savepath(Cfg, mfilename, 'qc', ...
                            'suffix', 'blinkERP');
    savename = [EEG.CTAP.measurement.casename, '_blinkERP.png'];
    savefile = fullfile(savepath, savename);
    print(figh, '-dpng', savefile);
    close(figh);
  
end   


 
%% ERROR/REPORT
Cfg.ctap.filter_blink_ica = Arg;

msg = sprintf('FIR filtered blin ICs data: %s', EEG.setname); 
myReport(msg, Cfg.env.logFile);
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
