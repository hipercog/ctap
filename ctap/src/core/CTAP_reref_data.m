function [EEG, Cfg] = CTAP_reref_data(EEG, Cfg)
%CTAP_reref_data - Rereference data
%
% Description:
%   Note: CTAP_load_chanlocs() or similar should have been run before 
%   this step to get names for the channels.
%
%   Important for BioSemi data, see:
%   http://www.biosemi.com/faq/cms&drl.htm
%
% Syntax:
%   [EEG, Cfg] = CTAP_reref_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.reref_data:
%   .reference  cell of strings, List of reference channel names,
%               default: Cfg.eeg.reference
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: get_refchan_inds(), pop_reref()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.reference = Cfg.eeg.reference;
Arg.keepref = 'on';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'reref_data')
    Arg = joinstruct(Arg, Cfg.ctap.reref_data); %override with user params
end


%% ASSIST
chaninds = get_refchan_inds(EEG, Arg.reference);
% if the requested reference is from the EEG.chanlocs.type field...
if isempty(chaninds)
    if sum(ismember(Arg.reference, {'EEG', 'REF'})) > 0
        chaninds = find(ismember({EEG.chanlocs.type}, Arg.reference));
    end
end
% proceed if some reference was found
if isempty(chaninds)
    error('CTAP_reref_data:channelsNotFound',...
       'Reference channels ''%s'' not found.', strjoin(Arg.reference,', '));
end


%% CORE
% Set any old reference channels back to type='EEG'
% EEG = pop_chanedit(EEG, 'changefield', {get_eeg_inds(EEG, 'REF') 'type' 'EEG'});

% Re-reference
EEG = pop_reref(EEG, chaninds, 'keepref', Arg.keepref);

% Set kept reference channels to correct type
% EEG = pop_chanedit(EEG, 'changefield', {chaninds 'type' 'REF'});

if strcmp(Arg.reference, 'average')
    EEG.CTAP.reference = 'average';
else
    EEG.CTAP.reference = {EEG.chanlocs(chaninds).labels};
end


%% ERROR/REPORT
Cfg.ctap.reref_data = Arg;

msg = myReport(sprintf('Rereferenced data to: ''%s'' for %s.',...
            strjoin({EEG.chanlocs(chaninds).labels},', '),...
            EEG.setname), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
