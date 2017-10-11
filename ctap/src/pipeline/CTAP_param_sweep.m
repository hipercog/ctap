function CTAP_param_sweep(Cfg, varargin)
%CTAP_param_sweep - sweeps the specified parameter range for the specified
% function against the specified data.
%
% Description:
%
% Syntax:
%   CTAP_param_sweep(Cfg, varargin);
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   'debug'     boolean, runs parameter sweep without try-catch wrapper. Errors
%               from called functions will crash the batch.
%               default = false
%
% Outputs:
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also: 
%
% Version History:
% 26.01.2017 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Cfg', @isstruct);
p.addParameter('debug', false, @islogical);
p.parse(Cfg, varargin{:});
Arg = p.Results;

if ~Arg.debug
    warning('OFF', 'BACKTRACE')
end

%% FUNCTIONALITY

if ~Arg.debug
    warning('ON', 'BACKTRACE')
end


%% EMBEDDED FUNCTIONS


end% CTAP_param_sweep()
