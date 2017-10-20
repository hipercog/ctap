function [EEG, varargout] = ctapeeg_template_function(EEG, varargin)
%CTAPEEG_TEMPLATE_FUNCTION template for a ctapeeg function. Short description
%       supports the usage of "lookfor";
%       write NAME right next to the % -character;
%       include search words within the FIRST comment line;
%
% Description:
%   ctapeeg core function philosophy is to provide all totally generic code
%   specific to a single function.
%
% Algorithm:
%   * How the function achieves its results?
%
% Syntax:
%   [EEG, varargout] = ctapeeg_template_function(EEG, varargin);
%
% Inputs:
%   'EEG'           struct, EEG structure to modify
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%
% Outputs:
%   'EEG'           struct, modified EEG structure
%
%   varargout
%   'params'        struct, names, values of all arguments to core function
%   'result'        struct, any results which are not direct modifications
%                   of the EEG struct. Caller decides how to handle. If
%                   function throws error, this becomes error report with
%                   severity flag and specific message
%
% Assumptions:
%
% References:
%
% Example: These lines will be shown as the example
%
% Notes: Include some good-to-know information
%
% See also: <function 1>, <function 2>
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sbf_check_input()


%% PREAMBLE
%

%% CORE
%   Do core functionality
varargout{1} = params;

try
    result = some_eeg_functionality(EEG, Arg);
catch ME,
    error('ctapeeg_template_function:FAIL',ME.message);
end
varargout{2} = result;

%% MISC


%% Sub-functions
    function sbf_check_input()
        %% Unpack and store varargin
        if numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end),varargin(1:2:end),2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg.param1 = '';
        Arg.param2 = [];

        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_template_function()
