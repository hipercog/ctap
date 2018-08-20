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
if ~Cfg.eeg.chanlocs
    return
end
Arg.file = ctap_eeg_find_chlocs(Cfg);
Arg.field = {}; %user must set this based on his own knowledge!
Arg.tidy = {};
Arg.optimise_centre = true;
Arg.convert_coords = true;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_chanlocs')
    Arg = joinstruct(Arg, Cfg.ctap.load_chanlocs); %override w user params
end


%% ASSIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(Cfg.ctap.load_chanlocs, 'assist') && Cfg.ctap.load_chanlocs.assist
    % find the chanlocs filetype from the file name
    if ~isfield(Arg, 'filetype')
        types = {'loc', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'besa'...
              , 'polhemus', 'chanedit'};
        exts = {'locs', 'loc', 'sph', 'sfp', 'xyz', 'asc', 'elc', 'elp'...
            , 'elp', 'ced'};
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


%% CORE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load chanlocs
if isfield(Arg, 'filetype') && strcmp(Arg.filetype, 'custom') == 1
    try Arg.format;
    catch ME
        error('FAIL:: %s - no custom chanlocs format given', ME.message);
    end
    try Arg.skiplines; 
    catch 
        Arg.skiplines = 1;   
    end
end
    
[EEG, params, ~] = ctapeeg_load_chanlocs(EEG, struct2varargin(Arg));


%% MISCELLANEOUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set any chanlocs types according to user definition
if ~isempty(Arg.field)
    for fdx = 1:numel(Arg.field)
        if strcmpi(Arg.field{fdx}{1}, 'all')
            Arg.field{fdx}{1} = {EEG.chanlocs.labels};
        end
        for chidx = 1:numel(Arg.field{fdx}{1})
            if isnumeric(Arg.field{fdx}{1}(chidx))
                idx = 1:numel(EEG.chanlocs) == Arg.field{fdx}{1}(chidx);
            else
                idx = ismember({EEG.chanlocs.labels}, Arg.field{fdx}{1}(chidx));
            end
            if any(idx)
                [EEG.chanlocs(idx).(Arg.field{fdx}{2})] = deal(Arg.field{fdx}{3});
            end
        end
        if fdx > 1
            ovw = ismember(Arg.field{fdx - 1}{1}, Arg.field{fdx}{1});
            Arg.field{fdx - 1}{1}(ovw) = [];
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
        if ~isempty(tidyidx), EEG = pop_select(EEG, 'nochannel', tidyidx); end
    end
end

% Auto-optimise the head centre and convert to spherical and polar coords
if Arg.optimise_centre
    [X, Y, Z] =...
        chancenter([EEG.chanlocs.X]', [EEG.chanlocs.Y]', [EEG.chanlocs.Z]', []);
    X = num2cell(X);    Y = num2cell(Y);    Z = num2cell(Z);
    [EEG.chanlocs.X, EEG.chanlocs.Y, EEG.chanlocs.Z] = deal(X{:}, Y{:}, Z{:});
end
if Arg.convert_coords
    myReport('Note: auto-converted XYZ coordinates to spherical & polar'...
        , Cfg.env.logFile);
    EEG.chanlocs = convertlocs(EEG.chanlocs, 'cart2all');
end

% checkset
EEG = eeg_checkchanlocs(EEG);
% update urchanlocs, e.g. retain only the desired channels
EEG.urchanlocs = EEG.chanlocs;%make interpolation possible after channel removal


%% ERROR/REPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Arg = joinstruct(Arg, params);
Cfg.ctap.load_chanlocs = Arg;

msg = '';
if ~isempty(Arg.field)
    msg = myReport({'SHSHMade channel type assignment -'...
        cellfun(@myReport, Arg.field, 'Un', 0)}, [], newline);
end
msg = myReport(sprintf('Loaded chanlocs from %s%s%s', Arg.file, newline, msg)...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
