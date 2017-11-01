function EEG = add_CTAP(EEG, Cfg, varargin)
%ADD_CTAP - Adds CTAP struct to an EEG struct
%
% Description:
%   Use this function to create the CTAP struct when importing your data.
%   Also sets some metadata fields of the EEG struct.
%   Modify this function to add/remove/rename fields in EEG.CTAP.
%   Using one central place for creating the CTAP simplifies maintenance.
%
% Syntax:
%   EEG = add_CTAP(EEG, Cfg, reference, varargin);
%
% Inputs:
%   EEG         struct, EEGLAB EEG struct
%   Cfg         struct, CTAP configuration struct
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   'meta'      struct, data about the EEG recording, e.g. device, id
%   'time'      {1,3} cell, Three elements:
%               1. file start data string for CTAP.time.fileStartDS
%               2. data start data string for CTAP.time.dataStartDS,
%               3. data start offset in samples for CTAP.time.dataStartOffsetSamp
%               These are needed to add timestamps into results. Use Matlab 
%               format: 30 = ISO 8601: 'yyyymmddTHHMMSS' e.g. 20000301T154517
%               Default = now
%
% Outputs:
%   EEG         struct, EEGLAB EEG struct with field 'CTAP'
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also:  is_valid_CTAP
%
% Version History:
% 1.06.2014 Created (Jussi Korpela, FIOH)
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
p.addRequired('EEG', @isstruct);
p.addRequired('Cfg', @isstruct);

p.addParameter('time', {}, @iscell);
p.addParameter('meta', struct, @isstruct);

p.parse(EEG, Cfg, varargin{:});
Arg = p.Results;


%% Add EEG metadata
EEG.setname = Cfg.measurement.casename;
EEG.subject = Cfg.measurement.subject;
EEG.session = Cfg.measurement.session;
EEG.condition = Cfg.measurement.measurement;
EEG.group = '';


%% Add CTAP required fields
EEG.CTAP.subject = Cfg.subject;
EEG.CTAP.measurement = Cfg.measurement;

EEG.CTAP.files.eegFile = Cfg.measurement.physiodata;
EEG.CTAP.files.channelLocationsFile = Cfg.eeg.chanlocs;
EEG.CTAP.reference = Cfg.eeg.reference;

% .CTAP.time.fileStart and .CTAP.time.dataStart
if isempty(Arg.time)
    EEG.CTAP.time.fileStart = datestr(0,0);
	EEG.CTAP.time.dataStart = datestr(0,0);
    EEG.CTAP.time.dataStartOffsetSamp = NaN;
elseif numel(Arg.time)==1
    EEG.CTAP.time.fileStart = Arg.time{1};
	EEG.CTAP.time.dataStart = datestr(0,0);
    EEG.CTAP.time.dataStartOffsetSamp = NaN;
else
    EEG.CTAP.time.fileStart = Arg.time{1};
	EEG.CTAP.time.dataStart = Arg.time{2};
    EEG.CTAP.time.dataStartOffsetSamp = Arg.time{3};
end

EEG.CTAP.history = create_CTAP_history_entry(...
                ['CTAP struct created: ',datestr(now)],...
                'add_CTAP');
% This needs to be set up like this for the (end+1) appending to work
EEG.CTAP.err = struct;
EEG.CTAP.meta = Arg.meta;
