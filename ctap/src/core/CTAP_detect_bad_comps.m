function [EEG, Cfg] = CTAP_detect_bad_comps(EEG, Cfg)
%CTAP_detect_bad_comps - Autodetect bad quality components
%
% Description:
%
% Syntax:
%   [EEG, Cfg] = CTAP_detect_bad_comps(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.detect_bad_comps(i):
%   .plot   boolean, Should quality control figures be plotted?,
%           default: true
%   Other fields should match the varargins of ctapeeg_detect_bad_comps().
%   
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_detect_bad_comps()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.plot = Cfg.grfx.on; % plot settings follow the global flag, unless specified by user!

% Override defaults with user parameters
if isfield(Cfg.ctap, 'detect_bad_comps')
    Arg = joinstruct(Arg, Cfg.ctap.detect_bad_comps); %override with user params
end


%% ASSIST
% Check that there are EOG channels
if isfield(Arg, 'blinks') && sum(strcmp('EOG',{EEG.chanlocs.type})) < 2
    error('ctap:detectBadComps',...
    'EOG channel type not defined, or not all present; aborting!');
end

if isempty(EEG.icachansind)
   error('FAIL::This dataset has not been ICA''d! Aborting...');
else
    if ~isfield(EEG,'icaact') || isempty(EEG.icaact)
        EEG.icaact = eeg_getica(EEG);
    end
end


%% CORE
[EEG, params, result] = ctapeeg_detect_bad_comps(EEG, Arg);

Arg = joinstruct(Arg, params);


%% PARSE
% Checking and fixing
if ~isfield(EEG.CTAP, 'badcomps') 
    EEG.CTAP.badcomps = struct;
end
if ~isfield(EEG.CTAP.badcomps, Arg.method) 
    EEG.CTAP.badcomps.(Arg.method) = result;
else
    EEG.CTAP.badcomps.(Arg.method)(end+1) = result;
end

% save the index of the badness for the CTAP_reject_data() function
if isfield(EEG.CTAP.badcomps, 'detect')
    EEG.CTAP.badcomps.detect.src = [EEG.CTAP.badcomps.detect.src;...
        {Arg.method, length(EEG.CTAP.badcomps.(Arg.method))}];
    [numbad, ~] = ctap_read_detections(EEG, 'badcomps');
    numbad = numel(numbad);
else
    EEG.CTAP.badcomps.detect.src =...
        {Arg.method, length(EEG.CTAP.badcomps.(Arg.method))};
    numbad = numel(result.comps);
end

% parse and describe results
repstr1 = sprintf('''%s'' bad components for ''%s'': ', Arg.method, EEG.setname);
repstr2 = {result.comps};

prcbad = 100 * numbad / numel(EEG.icachansind);
if prcbad > 10
    repstr1 = ['WARN ' repstr1];
end
repstr3 = sprintf('\nTOTAL %d/%d = %3.1f prc of components marked to reject\n'...
    , numbad, numel(EEG.icachansind), prcbad);

EEG.CTAP.badcomps.detect.prc = prcbad;


%% ERROR/REPORT
Cfg.ctap.detect_bad_comps = Arg;

msg = myReport({repstr1 repstr2 repstr3}, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% DIAGNOSTICS
if Arg.plot && prcbad > 0
    sbf_plot_bad_comps
else
    myReport(sprintf('\n'), Cfg.env.logFile);
end


%% Subfunctions

% Visualize component rejections as contact sheet of scalp maps
function sbf_plot_bad_comps()
    savepath = get_savepath(Cfg, mfilename);
    myReport(sprintf('Plotting diagnostics to ''%s''...\n', savepath)...
        , Cfg.env.logFile);
    EEGname = strrep(EEG.CTAP.measurement.casename, '_', '-');

    %plot scalp maps of bad components
    comps = EEG.CTAP.badcomps.(Arg.method).comps;
    chans = get_eeg_inds(EEG, {'EEG'});
    saveid = sprintf('%s_Method-%s', EEG.CTAP.measurement.casename, Arg.method);

    figh = ctap_ic_topoplot(EEG, comps...
        , 'savepath', savepath...
        , 'savename', saveid...
        , 'topotitle', [EEGname ' BAD ICs']...
        , 'topoplot', {'plotchans', chans}...
        , 'visible', 'off'); %#ok<NASGU>
end

end
