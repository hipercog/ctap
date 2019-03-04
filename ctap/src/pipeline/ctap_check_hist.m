function [msg, fun, args] = ctap_check_hist(eeg, outdir)
%CTAP_CHECK_HIST displays the history struct from a CTAP-processed EEG file
%
% Description:
%   Function reads EEG.CTAP.history struct, which contains fields:
%   'msg' - a short message specified by a CTAP*() function
%   'fun' - function name at each pipeline step
%   'args' - complete set of arguments and values used in the function
%   For each struct array index, these three fields are displayed to command
%   line and optionally written to a log file. 
%
% Syntax:
%   check_ctap_hist(eeg, outdir)
%
% Inputs:
%   'eeg'       struct, EEG structure to check
%   'outdir'    string, output filename to write CTAP history entries,
%               default = does not write
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%
% Outputs:
%   'msg'       string, a short message specified by a CTAP*() function
%   'fun'       srting, function name at each pipeline step
%   'args'      struct, complete set of arguments and values used in function
% 
% 
% See also: myReport
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    outdir = '';
end
if ischar(eeg)
    [p, n, e] = fileparts(eeg);
    if isempty(e)
        eeg = fullfile(p, [n '.set']);
    end
    if exist(eeg, 'file')
        eeg = ctapeeg_load_data(eeg, 'type', 'set');
    else
        error('There is no EEG .set file at %s', eeg);
    end
elseif ~isstruct(eeg)
    warning('This is not an EEG struct'); return;
elseif ~is_valid_CTAPEEG(eeg)
    warning('EEG file was not processed by CTAP pipe'); return;
end

msg = {eeg.CTAP.history.msg};
fun = {eeg.CTAP.history.fun};
args = {eeg.CTAP.history.args};
for i=1:numel(msg)
    arg = evalc('disp(args{i})');
    tmp = myReport({fun{i} msg{i} arg}, outdir, newline); %#ok<NASGU>
end
