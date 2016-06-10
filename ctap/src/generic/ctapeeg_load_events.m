function [EEG, varargout] = ctapeeg_load_events(EEG, varargin)
%CTAPEEG_LOAD_EVENTS add events to EEG struct
%
% Description:
%   * Convert events from raw EEG triggers to log strings. 
%
% SYNTAX
%   EEG = ctapeeg_load_events(EEG, varargin)
% 
% INPUT
%   'EEG'           EEG struct to process
% VARARGIN
%   'method'    :   name of event-loading method. Default='ascii'. Options are:
%                   'handle' - pass a function handle as another argument
%                   'ascii' - first column is event type, second is latency
%                   'Presentation' - Neurobs .log file loader
%                   'ctap' - BWRC way of adding new events
%   'directory' :   either one event file, or the location of all log files
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : struct, array of events loaded
%
% varargout
%
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sbf_check_input() % parse the varargin, set defaults


%% load some events
switch Arg.method
    case 'handle'
        EEG = Arg.handle(EEG, 'directory', Arg.directory);
    case 'Presentation'
        EEG = pop_importpres(EEG, Arg.directory);
    case 'ctap'
%         event = eeglab_create_event(Arg.evLatency, {'correctAnswerBlock'},...
%                         'duration', num2cell(Arg.evDuration'),...
%                         'ruleBlockID', num2cell(Arg.evBlockID'),...
%                         'rule', Arg.evRule,...
%                         'globalStim', Arg.evGlobalStim,...
%                         'localStim', Arg.evLocalStim);
%         [EEG.event, rejevent] = eeglab_merge_event_tables(event, EEG.event,...
%                                 'ignoreDiscontinuousTime');
    otherwise
        EEG.event = importevent(Arg.directory, EEG.event, EEG.srate );
end

varargout{1} = Arg;
varargout{2} = EEG.events;


%% Sub-functions
    function sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg.method = 'ascii';
        Arg.directory = '';
        Arg.handle = @pop_importpres;

        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end
