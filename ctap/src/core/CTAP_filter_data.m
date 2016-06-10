function [EEG, Cfg] = CTAP_filter_data(EEG, Cfg)
%CTAP_filter_data - Bandpass filter data
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_filter_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.filter_data:
%   .firtype    string, If empty uses IIR filtering via pop_iirfilt() 
%               otherwise FIR filtering using pop_eegfilt(), see
%               ctapeeg_filter_data() for options, default: 'fir1'
%   .lowCutOff  [1,1] numeric, Low end of the pass band in Hz, default: 1
%   .highCutOff [1,1] numeric, High end of the pass band in Hz, default: 45
%   Other arguments as in ctapeeg_filter_data().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
%
% Notes: 
%
% See also: ctapeeg_filter_data()  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.firtype = 'fir1';
Arg.lowCutOff = 1;
Arg.highCutOff = 45;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'filter_data')
    Arg = joinstruct(Arg, Cfg.ctap.filter_data); %override w user params
end


%% ASSIST

% Quality control 1/2: original PSD
if Cfg.grfx.on
    chind = 1; %channel index
    sr = [1, 2^12]; %sample range
    if EEG.pnts < sr(2)
       sr(2) = EEG.pnts; 
    end
    x0 = EEG.data(chind, sr(1):sr(2));
    nfft = 2^nextpow2(length(x0));
    [Pxx0,~] = periodogram(x0, hamming(length(x0)), nfft, EEG.srate); %V^2/Hz
end


%% CORE
Arg.filt = [Arg.lowCutOff, Arg.highCutOff];
[EEG, params] = ctapeeg_filter_data(EEG, Arg);


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.filter_data = Arg;

msg = myReport(['Filtered data at ' num2str(Arg.filt) ': ' EEG.setname]...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

% Quality control 2/2: filtered PSD
if Cfg.grfx.on
    x = EEG.data(chind, sr(1):sr(2));
    nfft = 2^nextpow2(length(x));
    [Pxx,f] = periodogram(x, hamming(length(x)), nfft, EEG.srate);

    PxxMat = [Pxx0, Pxx];
    fg = figure('Visible','off');
    % Plot and save
    plot(f, 10*log10(PxxMat));
    xlim([0, Arg.filt(2)+20]);
    xlabel('Frequency (Hz)');
    ylabel('Power (V^2/Hz in dB)');
    legend('original','filtered');
    title(sprintf('Power spectrum of channel %s, sample range %d:%d',...
                  EEG.chanlocs(chind).labels, sr));

    qcfile = fullfile(get_savepath(Cfg, mfilename),...
          sprintf('last_filtering_%s.png', EEG.CTAP.measurement.casename));
    saveas(fg, qcfile)
    close(fg);
end
