function isValid = is_valid_CTAP(S)
%IS_VALID_CTAP - Check that a given struct contains all required fields
%
% Description:
%   Test a EEG.CTAP struct for required fields.
%   Documents the intended structure of the EEG.CTAP struct.
%   Should respond to the stage in the pipeline that it's called from, e.g.
%   if called within any detect_bad_X function, chanlocs should have type
%   and label fields.
%
% Syntax:
%   isValid = is_valid_CTAP(S);
%
% Inputs:
%   'S'       struct, CTAP struct to test
%
% Outputs:
%   'isValid' logical, Test pass/fail indicator
%
% Assumptions:
% A valid EEG.CTAP struct should contain:
%   EEG.CTAP.subject
%   EEG.CTAP.measurement
%   EEG.CTAP.files.eegFile
%   EEG.CTAP.files.channelLocationsFile
%
%   EEG.CTAP.time.fileStart
%   EEG.CTAP.time.dataStart
%   EEG.CTAP.reference
%   EEG.CTAP.history
% 
% Recommended but optional fields include:
%   EEG.CTAP.MC.measurement
%
% References:
%
% Example:
%
% Notes:
%
% See also:
%
% Copyright(c) 2014 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

baseFieldNames = {'subject','measurement','files','time',...
                  'meta','reference','history'};
filesFieldNames = {'eegFile','channelLocationsFile'};


%% Test root level fields
isValid = true;
test = ismember(baseFieldNames,fieldnames(S));
    
if length(find(~test)) > 0 %#ok<ISMT>
   isValid = false; 
   myReport({'Fields missing from CTAP struct: ' baseFieldNames(~test)});
end

%% Test CTAP.files
if isfield(S,'files')
    test2 = ismember(filesFieldNames, fieldnames(S.files));
    if length(find(~test2)) > 0 %#ok<ISMT>
        isValid = false;
        myReport({'Fields missing from CTAP.files:' filesFieldNames(~test2)});
    end
end

