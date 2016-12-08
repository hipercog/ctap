function [EEG, Cfg] = CTAP_generate_cseg(EEG, Cfg)
%CTAP_generate_cseg - Generate calculation segments
%
% Description:
%   Creates events of type Cfg.event.csegEvent into EEG.event to guide PSD
%   estimation.
%
% Syntax:
%   [EEG, Cfg] = CTAP_generate_cseg(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.generate_cseg:
%   .segmentLength  [1,1] numeric, cseg length in sec, default: 5
%   .segmentOverlap [1,1] numeric, cseg overlap in precentage, value range
%                   [0...1], default: 0
%   .csegEvent      string, Event type string for the events, 
%                   default: 'cseg'
%   Other arguments should match the varargin of
%   ctapeeg_add_regular_events().
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_add_regular_events()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.segmentLength = 5;%in sec
Arg.segmentOverlap = 0; %in percentage [0,1]
Arg.csegEvent = 'cseg'; %event type string

% Override defaults with user parameters
if isfield(Cfg.ctap, 'generate_cseg')
    Arg = joinstruct(Arg, Cfg.ctap.generate_cseg);
end


%% Add events
vargs = rmfield(Arg, {'segmentLength','segmentOverlap','csegEvent','generate_cseg_params'});
vargs = struct2varargin(vargs);
EEG = ctapeeg_add_regular_events(EEG,...
                                Arg.segmentLength,...
                                Arg.segmentOverlap,...
                                Arg.csegEvent,...
                                vargs{:});
                      
% MAYBEDO: Create a visualization of how the events are located with
% respect to e.g. boundary events and the dataset duration
%{
evmatch = ismember({EEG.event.type}, Arg.csegEvent);
[evc, labs] = struct_to_cell(EEG.event(evmatch));

replabs = {'latency','duration'};
replabsInds = ismember(labs, replabs);
%}


%% ERROR/REPORT
Cfg.ctap.generate_cseg = Arg;
nEvents = sum(ismember({EEG.event.type}, Arg.csegEvent));
msg = myReport(sprintf('%d ''%s'' events addded to EEG.event.',...
               nEvents,Arg.csegEvent), Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
