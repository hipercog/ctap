function isValid = is_valid_CTAPEEG(EEG)
%IS_VALID_CTAP - Check that a given struct contains all required fields
%
% Description:
%   Test a EEG.CTAP struct for required fields. Simply calls is_valid_CTAP
%
% Syntax:
%   isValid = is_valid_CTAPEEG(EEG);
%
% Inputs:
%   'EEG'     struct, EEG struct to test
%
% Outputs:
%   'isValid' logical, Test pass/fail indicator
%
% See also:   is_valid_CTAP
%
% Copyright(c) 2014 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

isValid = true;

%% Validate CTAP struct
if isfield(EEG, 'CTAP')
    if ~is_valid_CTAP(EEG.CTAP)
        isValid = false;
        return;
    end
else
    isValid = false;
    return;
end
