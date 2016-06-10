function [EEG, varargout] = ctapeeg_epoch_data(EEG, varargin)
%CTAPEEG_EPOCH_DATA epoch the dataset or make it continuous 
%
% SYNTAX
%   EEG = ctapeeg_epoch_data(EEG, varargin)
%
% INPUT
%   'EEG'       :   eeglab data struct
% VARARGIN
%   'method'    : operation to take (Default=regep):
%                 'regep' - epoching to new periodic dummy events
%                 'epoch' - epoching to existing events
%                 'depoc' - make continuous; experimental method
%   REGEP optional param
%   'evname'    : type-name of event(s) to lock epochs, 
%                 Default='X'
%
%   EPOCH optional params are same as pop_epoch, including:
%   'evtype'    : type of event(s) to lock epochs
%   'indices'   : indices of events to lock epochs
%                 (for others do >> help pop_epoch)
%
%   'timelim'   : negative/positive milliseconds around epoch, 
%                 Default = [-500 500]
%   'valulim'   : negative/positive latency (points) around epoch,
%                 Default = []
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : struct, event which is returned by <help pop_epoch>
%
% NOTE
%
% See also: pop_epoch, eeg_regepochs, epoch2continuous
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

Arg = sbf_check_input(); % parse the varargin, set defaults

Arg.timelim = Arg.timelim./1000; %to seconds


%% Epoching...operation
switch Arg.method
    case 'epoch'
        % check if event type is defined
        if ~isempty(Arg.evtype)
            [EEG, event] = pop_epoch(EEG,Arg.evtype, Arg.timelim,...
                'valuelim', Arg.valulim,...
                'verbose', Arg.verbose,...
                'newname', Arg.name,...
                'epochinfo', Arg.epevents);
        else
            [EEG, event] = pop_epoch(EEG,Arg.evtype, Arg.timelim,...
                'eventindices', Arg.indices,...
                'valuelim', Arg.valulim,...
                'verbose', Arg.verbose,...
                'newname', Arg.name,...
                'epochinfo', Arg.epevents);
        end
        
    case 'regep'
        %{
        try Arg.evname;   catch ME, Arg.evname     = 'X';           end;
        %An alternative that avoids time consuming consistency edits in 
        eeg_checkset()

        tic;
        segLenSec = diff(Arg.timelim);
        [segArr] = generate_segments(EEG.pnts, segLenSec*EEG.srate, 0);
        event = eeglab_create_event(segArr(:,1), {Arg.evname},...
                'duration', num2cell(segArr(:,2)-segArr(:,1)) );
        [EEG.event, rejevent] = eeglab_merge_event_tables(event, EEG.event,...
                            'ignoreDiscontinuousTime');
        [EEG,event]=pop_epoch(EEG, {Arg.evname}, [0, segLenSec]);
        %Note: pop_epoch seems to double every newly created event of type
        %g.evname. Why? How to avoid this?
        toc;
        %27 sec

        %bypass this to avoid slow checking of event consistencies
        tic
        %{
        EEG=eeg_regepochs(EEG,'recurrence',g.period,'limits',g.timelim,...
        'rmbase',NaN,'eventtype',g.evname,'extractepochs',g.extract);
        %}        
        toc
        35 sec
        %}
        EEG = eeg_regepochs(EEG); % JARI FIX
        event = EEG.event;
        
    case 'depoc'
        %make dataset continuous again
        EEG = epoch2continuous(EEG);
        event = EEG.event;
        
end


%% wrap up
varargout{1} = Arg;
varargout{2} = event;


%% Sub-functions
    function Arg = sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        try Arg.method = vargs.method;
        catch
            Arg.method = 'regep';
        end
        
        Arg.name = [EEG.setname '_epochs'];
        Arg.valulim = [];
        Arg.timelim = [-500 500];

        switch Arg.method
            case 'epoch'
                Arg.evtype = {};
                Arg.indices = [];
                Arg.verbose = 'no';
                Arg.epevents = 'yes';

            case 'regep'

            case 'depoc'
                
        end
        
        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
        
        if strcmp(Arg.method, 'epoch') &&...
                isempty(Arg.evtype) && isempty(Arg.indices)
            error('ctapeeg_epoch_data:no_events_or_indices',...
                'NO Epoching Events/Indices are specified: Epoching fails.');
        end
    end

end % ctapeeg_epoch_data()
