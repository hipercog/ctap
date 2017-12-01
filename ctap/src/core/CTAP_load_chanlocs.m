function [EEG, Cfg] = CTAP_load_chanlocs(EEG, Cfg)
%CTAP_load_chanlocs - Load channel locations
%
% Description:
%   Load channel locations based on specification in Cfg.eeg.chanlocs.
%   Cfg.ctap.load_chanlocs specifies how to read custom Cfg.eeg.chanlocs
%   Can also define new chanlocs field values, and delete any channels
%   desired. NOTE: users should be very careful when defining indices for new 
%   fields, because eeg_checkchanlocs() is called after loading new chanlocs.
%   This function can delete channels which are, e.g. defined as not data.
%   TIP: try to load chanlocs once to check the outcome (e.g. by debugging after 
%   the call to ctapeeg_load_chanlocs) before defining fields to edit/tidy.
%
% Syntax:
%   [EEG, Cfg] = CTAP_load_chanlocs(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_chanlocs:
%   .filetype   string, type of chanlocs file; 
%               default = derived from 'locs' file extension 
%               If ext is not supported, input is set to custom, with given format
%   .format     cell string array, IF .filetype = custom THEN format required,
%               default = throws error
%   .skiplines  integer, number header lines for custom chanlocs
%               default = 1
%   .field      cell array of {'index' 'field' 'value'} string triples.
%               Indices should be within range of available channels.
%               Labels and other fields can be (carefully) defined by user.
%               Types should be three letter codes, EEG, EOG, ECG, REF, etc
%               For example: {'1:128' 'EEG'},{'129:130' 'ECG'}
%               default = {}, no field assignment action taken
%   .tidy       cell array of {'fieldname' 'value'} string pairs.
%               channels with 'fieldname' matching 'value' will be deleted.
%               For example: {'type' 'ECG'}, {'labels' ''} removes channels
%               of ECG data, and channels with empty label.
%               default = {}, no channel tidy action taken
%
%   Cfg.eeg.chanlocs
%       'file'  string, full filename pointing to a channel locations file,
%               default = get chanlocs matching EEG, from CTAP 'res' folder
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
%
% Notes: see '>>help readlocs' for: supported extensions and format strings
%
% See also: ctapeeg_load_chanlocs()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg.file = Cfg.eeg.chanlocs; %this is checked in ctap_auto_config()
Arg.field = {}; %user must set this based on his own knowledge!
Arg.tidy = {};

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_chanlocs')
    Arg = joinstruct(Arg, Cfg.ctap.load_chanlocs); %override w user params
end


%% ASSIST
exts = {'locs', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'elp', 'elp', 'ced'};
% Find chanlocs from directory with filename closest matching to EEG filename.
% NOTE: ONLY WORKS IF CHANLOCS ARE NAMED REGULARLY, WITH SUBJECT IDENTIFIER
% MATCHING EEG FILE, E.G. s01_eeg.bdf <--> s01_chanlocs.elp
if isdir(Arg.file)
    loc = match_file(Cfg.measurement.physiodata, Arg.file, exts);
    Arg.file = fullfile(Arg.file, loc);
end

if isfield(Cfg.ctap.load_chanlocs, 'assist') && Cfg.ctap.load_chanlocs.assist
    % find the chanlocs filetype from the file name
    if ~isfield( Arg, 'filetype' )
        types = {'loc', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'besa'...
              , 'polhemus', 'chanedit'};
        [~, ~, e] = fileparts(Arg.file);
        fext = strrep(e,'.','');
        e = ismember(exts, fext);
        if any(e)
            Arg.filetype = types{find(e, 1)};
        else
            error('Chanlocs extension ''%s'' not recognised', fext);
        end
    end
end


%% CORE
%load chanlocs
if isfield(Arg, 'filetype') && strcmp(Arg.filetype, 'custom') == 1
    try Arg.format;
    catch ME, 
        error('FAIL:: %s - no custom chanlocs format given', ME.message);
    end;
    try Arg.skiplines; 
    catch 
        Arg.skiplines = 1;   
    end;
end
    
argsCellArray = struct2varargin(Arg);
[EEG, params, ~] = ctapeeg_load_chanlocs(EEG, argsCellArray{:});


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set any chanlocs types according to user definition
if ~isempty(Arg.field)
    for fdx = 1:numel(Arg.field)
        for chidx = 1:numel(Arg.field{fdx}{1})
            EEG.chanlocs(Arg.field{fdx}{1}(chidx)).(Arg.field{fdx}{2}) =...
                Arg.field{fdx}{3};
%DONT USE pop_chanedit() BECAUSE IT CALLS eeg_checkchanlocs()
%             EEG = pop_chanedit(EEG, 'changefield'...
%                 , {Arg.field{fdx}{1}(chidx) Arg.field{fdx}{2:3}});
        end
    end
    % Feedback about types
    myReport({EEG.chanlocs.labels; EEG.chanlocs.type},...
        Cfg.env.logFile, sprintf('\t'));
    myReport('WARN^ ^ ^ ^ CAUTION - CHECK YOUR TYPE ASSIGNMENT! ^ ^ ^ ^');
end 

% tidy up - get rid of user-defined channels
if ~isempty(Arg.tidy)
    if ~iscell(Arg.tidy{1})
        Arg.tidy = {Arg.tidy};
    end
    for i = 1:numel(Arg.tidy)
        tidyidx = find(ismember({EEG.chanlocs.(Arg.tidy{i}{1})}, Arg.tidy{i}{2}));
        EEG = pop_select(EEG, 'nochannel', tidyidx);
    end
end

EEG = eeg_checkchanlocs(EEG); % checkset
% update urchanlocs, e.g. retain only the desired channels
EEG.urchanlocs = EEG.chanlocs;%make interpolation possible after channel removal


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.load_chanlocs = Arg;

msg = '';
if ~isempty(Arg.field)
    msg = myReport({'Made channel type assignment -' Arg.field});
end
msg = myReport(sprintf('Loaded chanlocs from %s.\n%s', Arg.file, msg)...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% MISC
% checkset
EEG = eeg_checkchanlocs(EEG);
