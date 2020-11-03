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
%   .filetype   string, file extension denoting type of chanlocs; If ext is 
%               not supported, input is set to custom, with given format
%               default: derived from 'locs' file extension 
%   .format     cell string array, IF .filetype = custom THEN format required,
%               default: throws error
%   .skiplines  integer, number header lines for custom chanlocs
%               default: 1
%   .field      cell array of {'index' 'field' 'value'} string triples.
%               Indices should be within range of available channels.
%               Labels and other fields can be (carefully) defined by user.
%               Types should be three letter codes, EEG, EOG, ECG, REF, etc
%               For example: {'1:128' 'type' 'EEG'}, {'129' 'labels' 'HEOG1'}
%               If empty, no field assignment action is taken
%               default: {}
%   .tidy       cell array of {'fieldname' 'value'} string pairs.
%               channels with 'fieldname' matching 'value' will be deleted.
%               For example: {'type' 'ECG'}, {'labels' ''} removes channels
%               of ECG data, and channels with empty label.
%               If empty, no channel tidy action is taken
%               default: {}
%   .opt_centre logical, call EEGLAB's 'chancenter' to auto-optimise centre
%               default: true
%   .cnv_coords logical, call EEGLAB's 'convertlocs' to convert coordinates
%               default: true
%   .topoplot   logical, call EEGLAB's 'topoplot' to save a 2D fig of chanlocs
%               default: true
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
Arg.opt_centre = true;
Arg.cnv_coords = true;
Arg.topoplot = true;

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
% Set any chanlocs types/labels/other fields according to user definition
if ~isempty(Arg.field)
    for fdx = 1:numel(Arg.field)
        if strcmpi(Arg.field{fdx}{1}, 'all')
            Arg.field{fdx}{1} = {EEG.chanlocs.labels};
        end
        if ischar(Arg.field{fdx}{1})
            Arg.field{fdx}{1} = Arg.field{fdx}(1);
        end
        for chidx = 1:numel(Arg.field{fdx}{1})
            idx = 0;
            % Test numeric index
            if isnumeric(Arg.field{fdx}{1}(chidx))
                idx = 1:numel(EEG.chanlocs) == Arg.field{fdx}{1}(chidx);
            else
                strdx = str2double(Arg.field{fdx}{1}(chidx));
                if ~isnan(strdx)
                    idx = 1:numel(EEG.chanlocs) == Arg.field{fdx}{1}(chidx);
                end
            end
            if ~any(idx)
                idx = ismember({EEG.chanlocs.labels}, Arg.field{fdx}{1}(chidx));
                if ~any(idx)
                    idx = ismember({EEG.chanlocs.type}, Arg.field{fdx}{1}(chidx));
                end
            end
            if any(idx)
                [EEG.chanlocs(idx).(Arg.field{fdx}{2})] = deal(Arg.field{fdx}{3});
            else
                warning('CTAP_load_chanlocs:field_fail'...
                    , 'no channel found to match %s', Arg.field{fdx}{1}{chidx})
            end
        end
    end
    % Feedback about types
    myReport({EEG.chanlocs.labels; EEG.chanlocs.type},...
        Cfg.env.logFile, sprintf('\t'));
    myReport('WARN^ ^ ^ ^ CAUTION - CHECK YOUR CHANLOCS ASSIGNMENT! ^ ^ ^ ^');
end


% tidy up - get rid of user-defined channels
if ~isempty(Arg.tidy)
    if ~iscell(Arg.tidy{1})
        Arg.tidy = {Arg.tidy};
    end
    for i = 1:numel(Arg.tidy)
        tidx = find(ismember({EEG.chanlocs.(Arg.tidy{i}{1})}, Arg.tidy{i}{2}));
        if ~isempty(tidx), EEG = pop_select(EEG, 'nochannel', tidx); end
    end
end

% Auto-optimise the head centre and convert to spherical and polar coords
if Arg.opt_centre
    xidx = ~cellfun(@isempty, {EEG.chanlocs.X});
    yidx = ~cellfun(@isempty, {EEG.chanlocs.Y});
    zidx = ~cellfun(@isempty, {EEG.chanlocs.Z});
    [X, Y, Z] =...
        chancenter([EEG.chanlocs.X]', [EEG.chanlocs.Y]', [EEG.chanlocs.Z]', []);
    X = num2cell(X);    Y = num2cell(Y);    Z = num2cell(Z);
    [EEG.chanlocs(xidx).X, EEG.chanlocs(yidx).Y, EEG.chanlocs(zidx).Z] =...
                                                    deal(X{:}, Y{:}, Z{:});
end
if Arg.cnv_coords
    myReport('Note: auto-converted XYZ coordinates to spherical & polar'...
        , Cfg.env.logFile);
    EEG.chanlocs = convertlocs(EEG.chanlocs, 'cart2all');
end

% checkset
EEG = eeg_checkchanlocs(EEG);
% update urchanlocs, e.g. retain only the desired channels
EEG.urchanlocs = EEG.chanlocs;%make interpolation possible after channel removal

% PLOT SCALPMAP OF CHANLOCS FOR QA
if Arg.topoplot
    fh = figure('Visible', 'off');
    topoplot([], EEG.chanlocs...
        , 'style', 'blank'...
        , 'electrodes', 'labels'...
        , 'whitebk', 'on');
    print(fh, '-dpng', fullfile(get_savepath(Cfg, mfilename, 'qc')...
        , [EEG.CTAP.measurement.casename 'chanlocs.png']))
    close(fh)
end


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
