function [EEG, Cfg] = CTAP_extract_signal(EEG, Cfg)
%CTAP_extract_signal  - Exports some non-EEG signals into separate files
%
% Description:
%   Loops the channels of EEG and extracts the data to an edf file, or leda
%   file for EDA. By default it will extract all channels which are not EEG
%
% Syntax:
%   [EEG, Cfg] = CTAP_extract_signal(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.extract_signal:
%   .strip      boolean, Should the extracted signals be removed from EEG,
%               default: true
%   .types      cell string array, type names of channels to extract
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.strip = true;
Arg.types = {};
Arg.evflds = {};

% Override defaults with user parameters
if isfield(Cfg.ctap, 'extract_signal')
    Arg = joinstruct(Arg, Cfg.ctap.extract_signal); %override w user params
end


%% ASSIST
chanTypes = unique({EEG.chanlocs.type});
if ~isempty(Arg.types)
    chanTypes = chanTypes(ismember(chanTypes, Arg.types));
end


%% CORE
for i = 1:numel(chanTypes)
    switch chanTypes{i}
        case 'EEG'
            continue; %to next round in loop
        case 'EDA'
            savetype = 'leda';
        otherwise
            savetype = 'edf';
    end
    [DAT, params, EEG] = ctapeeg_extract_signal(...
        EEG, 'signal', chanTypes{i}, 'match', true, 'strip', Arg.strip);
    if ~isempty(DAT)
        savepath = fullfile(Cfg.env.paths.exportRoot, chanTypes{i});
    else
        continue; %to next round in loop
    end
    ctapeeg_export(DAT...
        , 'type', savetype...
        , 'name', [EEG.setname chanTypes{i}]...
        , 'outdir', savepath...
        , 'evflds', Arg.evflds);
    
    myReport(sprintf('Exported %s from %s to location %s.',...
        chanTypes{i}, EEG.CTAP.measurement.casename, Cfg.env.paths.exportRoot),...
        Cfg.env.logFile);
end


%% ERROR/REPORT
% Arg = joinstruct(Arg, params);
Arg = params;
Cfg.ctap.extract_signal = Arg;

msg = myReport({'Extracted DATA corresponding to channel types: ' chanTypes...
    newline}, Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
