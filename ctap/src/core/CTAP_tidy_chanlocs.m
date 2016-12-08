function [EEG, Cfg] = CTAP_tidy_chanlocs(EEG, Cfg)
%CTAP_tidy_chanlocs - Edit EEG.chanlocs structure
%
% Description:
%   User must always specify Cfg.ctap.tidy_chanlocs.types!
%   Use given cell array of {'index' 'type'} str pairs
%   to edit a chanlocs structure type fields. Can optionally set some
%   channels to be deleted.
%
% Syntax:
%   [EEG, Cfg] = CTAP_template_function(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.tidy_chanlocs:
%   .types  cell array of {'index' 'type'} string pairs. Indices
%           should be within range of available EEG channels. Types
%           should be three letter codes, EEG, EOG, ECG, REF, etc
%           For example: {'1:128' 'EEG'},{'129:130' 'ECG'}
%   .tidy   logical, If true, channels with an empty type will be deleted,
%           default: true
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: pop_chanedit()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
% Arg.types: user must set this based on his own knowledge!
Arg.tidy = true;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'tidy_chanlocs')
    Arg = joinstruct(Arg, Cfg.ctap.tidy_chanlocs); %override with user params
end


%% CORE
% Set any chanlocs types according to convention
for i=1:numel(Arg.types)
    EEG = pop_chanedit(EEG, 'settype', Arg.types{i});
end
% tidy up - get rid of undefined, undesired channels
if isfield(Arg, 'tidy') && Arg.tidy
    EEG = pop_select(EEG, 'nochannel',...
        find(cellfun(@isempty,{EEG.chanlocs.type})));
end
% checkset
EEG = eeg_checkchanlocs(EEG);
% update urchanlocs, e.g. retain only the desired channels
EEG.urchanlocs = EEG.chanlocs;


%% Feedback about types
myReport({EEG.chanlocs.type; EEG.chanlocs.labels},...
    Cfg.env.logFile, sprintf('\t'));
disp('WARN ^ ^ ^ ^ CAUTION - CHECK YOUR TYPE ASSIGNMENT! ^ ^ ^ ^');


%% ERROR/REPORT
Cfg.ctap.tidy_chanlocs = Arg;

msg = myReport({'Made channel type assignment -' Arg.types}...
    , Cfg.env.logFile );

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

end % CTAP_tidy_chanlocs()
