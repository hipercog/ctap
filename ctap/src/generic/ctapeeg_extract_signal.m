function [DAT, varargout] = ctapeeg_extract_signal(EEG, varargin)
%CTAPEEG_EXTRACT_SIGNAL split off e.g. peripheral-psychophysiology data
% 
% Description:
%   * The function simply splits off some data channels as an EEGLAB struct
%
% SYNTAX
%   [EEG, varargout] = ctapeeg_extract_signal(EEG, ...)
%
% INPUT
%   'EEG'     : EEG file to process
%
% VARARGIN
%   'signal'  : extract some data with a specific chanlocs type, defined by 
%               string signal, e.g. "EDA", "GSR" or "ECG"
%               Default = "EEG"
%   'match'   : if true, select the channels matching the given signal type.
%               Otherwise, select all channels NOT matching.
%               Default = false
%
% OUTPUT
%   'DAT'     : This is the EEG struct containing only the requested signal
%
% VARARGOUT
%   {1}       : The parameter list used in the function
%   {2}       : The EEG struct corresponding to the remainder after the
%               requested signal is removed.
%
%
% NOTE 1      First do ctapeeg_load_events if you want to output 
%             log file/Presentation code strings with your psychophys data!
% NOTE 2      It is usually best practice to simply import data directly
%             from raw data-files to the target application. 
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


%% Extract the requested data
DAT = [];

if ~isempty(strfind({EEG.chanlocs.type}, Arg.signal))
    idx = ~strcmp(Arg.signal, {EEG.chanlocs.type});
    if Arg.match
        idx = ~idx;
    end
    DAT = pop_select(EEG, 'channel', find(idx));
    DAT.setname = [DAT.setname '_' Arg.signal];
    if Arg.strip
        EEG = pop_select(EEG, 'nochannel', find(idx));
    end
end

varargout{1} = Arg;
varargout{2} = EEG;


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
        Arg.signal = 'EEG';
        Arg.match = false;
        Arg.strip = false;

        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_extract_peripherals()
