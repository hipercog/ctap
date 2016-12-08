function [EEG, Cfg] = CTAP_load_chanlocs(EEG, Cfg)
%CTAP_load_chanlocs - Load channel locations
%
% Description:
%   Load channel locations based on specification in Cfg.eeg.chanlocs.
%   Cfg.ctap.load_chanlocs specifies how to read custom Cfg.eeg.chanlocs
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
%   .types      cell array of {'index' 'type'} string pairs.
%               Indices should be within range of available EEG channels.
%               Types should be three letter codes, EEG, EOG, ECG, REF, etc
%               For example: {'1:128' 'EEG'},{'129:130' 'ECG'}
%               default = {}, no type assignment action taken
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
Arg.types = {}; %user must set this based on his own knowledge!
Arg.tidy = {};

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_chanlocs')
    Arg = joinstruct(Arg, Cfg.ctap.load_chanlocs); %override w user params
end


%% ASSIST
if isfield(Cfg.ctap.load_chanlocs, 'assist') && Cfg.ctap.load_chanlocs.assist
    % find the chanlocs filetype from the file name
    if ~isfield( Arg, 'filetype' )
        types = {'loc', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'besa'...
              , 'polhemus', 'chanedit'};
        exts = {'locs', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'elp'...
              , 'elp', 'ced'};
        [~, ~, e] = fileparts(Cfg.eeg.chanlocs);
        fext = strrep(e,'.','');
        e = find(~cellfun(@isempty, strfind(exts, fext)), 1, 'first');
        if ~isempty(e)
            Arg.filetype = types{e};
        else
            error('Chanlocs extension ''%s'' not recognised', fext);
        end
    end
end


%% CORE
%load chanlocs
if isfield(Arg, 'filetype')
    if strcmp(Arg.filetype, 'custom') == 1
        try Arg.format;
        catch ME, 
            error('FAIL:: %s - no custom chanlocs format given', ME.message);
        end;
        try Arg.skiplines; 
        catch 
            Arg.skiplines = 1;   
        end;
        [EEG, params, ~] = ctapeeg_load_chanlocs(EEG,...
            'locs', Arg.file,...
            'filetype', Arg.filetype,...
            'format', Arg.format,...
            'skiplines', Arg.skiplines);
    else
        [EEG, params, ~] = ctapeeg_load_chanlocs(EEG,...
            'locs', Arg.file,...
            'filetype', Arg.filetype);
    end
else
    [EEG, params, ~] = ctapeeg_load_chanlocs(EEG,...
        'locs', Arg.file);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set any chanlocs types according to user definition
if ~isempty(Arg.types)
    for i = 1:numel(Arg.types)
        EEG = pop_chanedit(EEG, 'settype', Arg.types{i});
    end
    % Feedback about types
    myReport({EEG.chanlocs.type; EEG.chanlocs.labels},...
        Cfg.env.logFile, sprintf('\t'));
    warning off backtrace
    warning('^ ^ ^ ^ CAUTION - CHECK YOUR TYPE ASSIGNMENT! ^ ^ ^ ^')
    warning on backtrace
end 

% tidy up - get rid of user-defined channels
if ~isempty(Arg.tidy)
    for i = 1:numel(Arg.tidy)
        tidyidx = find(ismember({EEG.chanlocs.(Arg.tidy{i}{1})}, Arg.tidy{i}{2}));
        EEG = pop_select(EEG, 'nochannel', tidyidx);
    end
end

% checkset
EEG = eeg_checkchanlocs(EEG);
% update urchanlocs, e.g. retain only the desired channels
EEG.urchanlocs = EEG.chanlocs;%make interpolation possible after channel removal


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.load_chanlocs = Arg;

msg = '';
if ~isempty(Arg.types)
    msg = myReport({'Made channel type assignment -' Arg.types});
end
msg = myReport(sprintf('Loaded chanlocs from %s.\n%s', Arg.file, msg)...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% MISC
% checkset
EEG = eeg_checkchanlocs(EEG);
