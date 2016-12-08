function entry = create_CTAP_history_entry(msg, varargin)
%CREATE_CTAP_HISTORY_ENTRY - adds an entry to the CTAP struct for each
%   operation performed
%
% Description:
%   Use this function to create history entries in the CTAP struct.
%
% Syntax:
%   entry = create_CTAP_history_entry(msg, varargin);
%
% Inputs:
%   msg         string, descriptive message about operation
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'fun'           string, name of function
%   'args'          struct, arguments actually used in function
%
% Outputs:
%   'entry'         struct, with fields 'msg', 'fun' and 'args'
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
% Created 2014- Jussi Korpela
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
p.addRequired('msg', @ischar);
p.addOptional('fun', '', @ischar);
p.addOptional('args', struct([]), @isstruct);

p.parse(msg, varargin{:});
Arg = p.Results;

entry.msg = msg;
entry.fun = Arg.fun;
entry.args = Arg.args;
