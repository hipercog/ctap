function [EEG, varargout] = ctapeeg_reref_data(EEG, varargin)
%CTAPEEG_REREF_DATA rereferencing the dataset
%
% SYNTAX        
%   EEG = ctapeeg_reref_data(EEG, varargin)
% 
% INPUT
%   'EEG'       : eeglab data struct
% VARARGIN
%   'ref'       : channels to reference to, either by type, e.g. REF, or by
%                 indices, e.g. 1:128
%                 (default) Whole Head average - good for local effects
%                           Mastoids - good for auditory & global effects
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : vector, reference channel indices
%
% NOTE
% See also CTAP_reref_data()
%
% CALLS    eeglab functions
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

sbf_check_input

varargout{1} = Arg;


%% ...reref
ref_inds = [];
if ischar(Arg.ref) || iscell(Arg.ref)
    ref_inds = get_refchan_inds(EEG, Arg.ref);
elseif isnumeric(Arg.ref)
    ref_inds = Arg.ref;
    Arg.ref = unique({EEG.chanlocs(ref_inds).labels});
end
if isempty(ref_inds)
    ref_inds = myReport({'SHSH' Arg.ref});
    error('ctapeeg_reref_data:no_ref',...
        '%s :: this reference not found - try rerefing to average!', ref_inds);
end

EEG = pop_reref(EEG, ref_inds, 'keepref','on');
EEG.ref = Arg.ref; %this fails for, e.g cellstr arrays

varargout{2} = ref_inds;


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
        
        try Arg.ref = vargs.ref;
        catch
            Arg.ref = 'EEG';
        end
    end

end % ctapeeg_reref_data()
