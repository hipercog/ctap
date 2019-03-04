function [EEG, varargout] = ctapeeg_reject_data(EEG, varargin)
%CTAPEEG_REJECT_DATA reject bad channels, epochs or components
%
% SYNTAX        
%   EEG = ctapeeg_reject_data(EEG, varargin)
%
% INPUT
%   'EEG'       eeglab data struct
% VARARGIN
%   'method'    choose method
%               'badchans'  clean channels
%               'badepochs' clean epochs
%               'badcomps'  clean ICA components
%               'badsegev'  remove segments from continuous data (adds
%                           boundary events)
%   'badness'   Definition of what to reject, data type depends on method
%               'badchans'  bad channel labels
%               'badepochs' bad epoch indices 
%               'badcomps'  bad independent component indices 
%               'badsegev'  [m,2] matrix of latency values 
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : string, message describes outcome
%
% NOTE
%           in this function no defaults can be guessed. Therefore the
%           varargins are required, although the interface structure remains
%           as varargin to match other ctapeeg functions
%
% CALLS     pop_select, pop_subcomp, eeg_eegrej
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Arg = struct;

sbf_check_input() % parse the varargin, set defaults

varargout{2} = '';

%% Apply methods
switch Arg.method
    case 'badchans'
        EEG = pop_select(EEG, 'nochannel', Arg.badness);
        
    case 'badepochs'
        tmp = find(~ismember(1:EEG.trials, Arg.badness));
        if numel(tmp)==1
            tmpep = EEG.epoch(tmp);
        end
        EEG = pop_select( EEG, 'notrial', Arg.badness, 'sorttrial', 'off' );
        if numel(tmp)==1
            EEG.epoch = tmpep;
        end
        
    case 'badcomps'
        %EEG0 = EEG;
        %icmat = icaact(EEG.data, EEG.icaweights*EEG.icasphere, mean(EEG.data,2));
        %compare_signals(icmat, [], EEG.srate)
        EEG = pop_subcomp( EEG, Arg.badness );
        EEG.setname = strrep(EEG.setname, ' pruned with ICA', '');
        
    case 'badsegev'
        evMatch = ismember({EEG.event.type}, Arg.badness);
        
        if 0 < sum(evMatch)
            evArr = NaN(sum(evMatch),2);
            evArr(:,1) = [EEG.event(evMatch).latency];
            evArr(:,2) = evArr(:,1) + [EEG.event(evMatch).duration]' - 1;
            
            if sum(isnan(evArr(:,2)))==0
                [EEG, ~] = eeg_eegrej(EEG, evArr);
                varargout{2} = sprintf('Removed %d events of types ''%s''.',...
                                        size(evArr,1),...
                                        Arg.badness);
            else
                varargout{2} = warning('ctapeeg_reject_data:missingData',...
                    'Some event durations missing. Nothing done.');
            end
        else
            error('ctapeeg_reject_data:no_events',...
            'No events of type ''%s''.', strjoin(Arg.badness));
        end
        
    otherwise
        error('ctapeeg_reject_data:badArgument',...
              'Unknow argument method = ''%s''.', Arg.method);
end

%% REPORT
if ~strcmp(Arg.method, 'badsegev')
    varargout{2} = myReport({'SHSH' sprintf(...
        'Removed %d %s : ', numel(Arg.badness), Arg.method) Arg.badness});        
end
varargout{1} = Arg;


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

        %SET AN ERROR BY DEFAULT
        Arg.method = 'no argument passed';
        Arg.badness = [];
        
        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_reject_data()
