function [EEG, Cfg] = CTAP_filter_design(EEG, Cfg)
%CTAP_filter_design - filter data with Matlab filter() according to your design
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_filter_design(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.filter_design:
%   'detrend'   : detrend EEG. Set as 'before' to detrend before filtering,
%                 or set as 'after' to detrend after filtering.
%                 Default=no detrending.
%   'design'    : pass a predesigned filter readable by Matlab's filter()
%                 function (use e.g. 'designfilt' or FDATool).
%                 OR build a filter with designfilt() from arguments
%                 Default=build from arguments
%   .locutoff  [1,1] numeric, Low end of the pass band in Hz, default: 1
%   .hicutoff  [1,1] numeric, High end of the pass band in Hz, default: 45
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
%
% Notes: 
%
% See also: CTAP_fir_filter()  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set default filter design arguments
Arg.detrend = '';
Arg.response = 'bandpassiir';
Arg.order = 16;
Arg.locutoff = 1;
Arg.hicutoff = 45;
Arg.design = [];

% Override defaults with user parameters
if isfield(Cfg.ctap, 'filter_data')
    Arg = joinstruct(Arg, Cfg.ctap.filter_data); %override w user params
end


%% ASSIST
if isempty(Arg.design)
    Arg.design = designfilt(Arg.response...
                 , 'FilterOrder', Arg.order...
                 , 'CutoffFrequency1', Arg.locutoff...
                 , 'CutoffFrequency2', Arg.hicutoff ...
                 , 'SampleRate', EEG.srate);
end

% Quality control 1/2: original PSD
if Cfg.grfx.on
    EEG0 = EEG;
end


%% CORE

%detrend if requested
if strcmpi(Arg.detrend, 'before')
    for i = 1:EEG.nbchan
        EEG.data(i, :) = detrend(EEG.data(i, :));
    end
end

% Apply one channel at a time
for i = 1:EEG.nbchan
    if EEG.trials>1
        EEG.data(i, :, :) = filter(Arg.design, squeeze(EEG.data(i, :, :))')';
    else
        EEG.data(i, :) = filter(Arg.design, EEG.data(i, :));
    end
end

%detrend if requested
if strcmpi(Arg.detrend, 'after')
    for i = 1:EEG.nbchan
        EEG.data(i, :) = detrend(EEG.data(i, :));
    end
end


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.filter_design = Arg;

msg = myReport(['Filtered data at ' num2str(Arg.filt) ': ' EEG.setname]...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

if Cfg.grfx.on
    % Make figure: PSD comparison plot and step response
    fg = plot_filter_response(EEG, EEG0, b, 'xlimits', [0 Arg.hicutoff + 15]);

    qcfile = fullfile(get_savepath(Cfg, mfilename, 'qc'),...
          sprintf('last_filtering_%s.png', EEG.CTAP.measurement.casename));
    saveas(fg, qcfile)
    close(fg);
end
