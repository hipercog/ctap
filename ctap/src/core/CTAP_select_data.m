function [EEG, Cfg] = CTAP_select_data(EEG, Cfg)
%CTAP_select_data - A wrapper to call pop_select() 
%
% Description:
%   Calls pop_select() by converting Cfg.ctap.select_data into a varargin
%   for the call.
%
% Syntax:
%   [EEG, Cfg] = CTAP_select_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.select_data:
%   .<method>   <method> is one of {'time','notime','point','nopoint',
%               'trial','notrial','channel','nochannel'}, see pop_select()
%               for details. Field contents specifies the things to
%               (un)select. I.e. the mapping is
%               pop_select(EEG, '<method>', <value>) <=> 
%               Cfg.ctap.select_data.<method>=value
%               default: there is no default
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: pop_select() 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods = { 'time', 'notime',...
            'point', 'nopoint',...
            'trial', 'notrial',...
            'channel', 'nochannel' };
        
Arg = Cfg.ctap.select_data;


%% ASSIST
methodsCalledMatch = ismember(methods, fieldnames(Arg));
methodsCalled = methods(methodsCalledMatch);


%% CORE
argsCellArray = struct2varargin(Arg);
EEG = pop_select(EEG, argsCellArray{:});


%% ERROR/REPORT
msg = myReport({'Selected data using pop_select with methods ',...
                catcellstr(methodsCalled), ': ', EEG.setname},...
                Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
