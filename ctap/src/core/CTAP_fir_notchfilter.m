function [EEG, Cfg] = CTAP_fir_notchfilter(EEG, Cfg)
%CTAP_fir_notchfilter - FIR notch filter data using firfilt plugin (pop_eegfiltnew.m)
%
% Description:
%   A wrapper to use pop_eegfiltnew.m in CTAP.
%   Note at least one cut-off frequency needs to be set.
%   If only ''locutoff'' set -> high-pass filter
%   if only ''hicutoff'' set -> low-pass filter
%   If both set -> band pass filter
%
% Syntax:
%   [EEG, Cfg] = CTAP_fir_notchfilter(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
%   Cfg.ctap.fir_filter:
%   .lowcutoff  [1,1] numeric, Low end of the pass band in Hz, default: []
%   .highcutoff [1,1] numeric, High end of the pass band in Hz, default: []
%   .filtorder [1,1] integer, Filter order, default: [] i.e. order set by
%                             the filtering function
%   .revfilt [1,1] integer, Invert filter from bandpass to notch filter?,
%                           allowed values: {0,1}, default: 1 (notch)
%   .plotfreqz [1,1] integer, Plot filter's frequency and phase response?,
%                             allowed values: {0, 1},
%                             default: 0 (does not plot)
%   .minphase [1,1] numeric, Make the filter scalar boolean minimum-phase 
%                            converted causal filter,
%                            allowed values: {0,1}, default: 0
%
% Outputs:
%   EEG         EEGLAB struct, FIR filtered data 
%   Cfg         struct, Cfg struct is updated by parameters,
%               values actually used
%
% Notes: 
%
% See also: pop_eegfiltnew.m 
%
% Copyright(c) 2017 
% Jan Brogger jan@brogger.no 
% Based on CTAP_fir_filter
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
% Default values as in pop_eegfiltnew()
Arg.locutoff = [];
Arg.hicutoff = [];
Arg.filtorder = [];
Arg.revfilt = 1;
Arg.plotfreqz = 0;
Arg.minphase = 0;


% Override defaults with user parameters
if isfield(Cfg.ctap, 'fir_notchfilter')
    Arg = joinstruct(Arg, Cfg.ctap.fir_filter); %override w user params
end

% Check that the user has set some cutoff (i.e. not running on defaults)
if isempty(Arg.locutoff) && isempty(Arg.hicutoff)
   error('CTAP_fir_filter:inputError', ...
       'At least one of the notch filter cut off frequencies ''locutoff'' or ''hicutoff'' needs to be set. See pop_eegfiltnew.m for details.'); 
end


%% ASSIST
if Cfg.grfx.on
    EEG0 = EEG;
end


%% CORE
[EEG, ~, b] = pop_eegfiltnew(EEG, Arg.locutoff, Arg.hicutoff, Arg.filtorder,...
                               Arg.revfilt, 0, Arg.plotfreqz, Arg.minphase);



%% ERROR/REPORT
Arg.a = []; %these are empty for FIR
Arg.b = b;
Cfg.ctap.filter_data = Arg;

msg = sprintf('FIR notch filtered data using pop_eegfiltnew(): %s', EEG.setname); 
myReport(msg, Cfg.env.logFile);
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

if Cfg.grfx.on
    
    if isempty(Arg.hicutoff)
        xlim_arr = [0, 50];
    else
        xlim_arr = [0 Arg.hicutoff + 15];
    end
    
    % Make figure: PSD comparison plot and step response
    fg = plot_filter_response(EEG, EEG0, b, 'xlimits', xlim_arr);

    % Save
    qcfile = fullfile(get_savepath(Cfg, mfilename, 'qc'),...
          sprintf('filter_notch_effects_%s.png', EEG.CTAP.measurement.casename));
    saveas(fg, qcfile)
    close(fg);
    
    
    % firfilt plugin default plots
    fg = figure('Visible','off');
    plotfresp(b, [], [], EEG.srate);
    qcfile = fullfile(get_savepath(Cfg, mfilename, 'qc'),...
          sprintf('filter_notch_properties_%s.png', EEG.CTAP.measurement.casename));
    saveas(fg, qcfile)
    close(fg);
    
    
    
end