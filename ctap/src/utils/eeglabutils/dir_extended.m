function files = dir_extended( directory, varargin )
%DIR_EXTENDED carefully controlled selection of files from a directory - should
%be generic but now still focused on EEG files: work in progress.
%
% SYNTAX
%	files = dir_extended( directory, varargin )
%
% Inputs:
%   'directory'	name of file or directory of files, default=pwd
%
% varargin:
%   'outdir'    : name of output folder
%   'conv'      : call with supported naming convention, to read experiment
%                   info from filename, e.g.:
%               'CENT'=[date[0-9]{6,8}]?_[subject]_[protocol]
%               'TTL'=[project/experiment][subject[0-9]{3}]_[measurement]
%               WIP - turn this into a config file entry, remove hardcoding
%   'inft'      : bdf or set file format
%   'name'      : name of specific subject(s) to preproc
%   'prot'      : name of specific protocol(s) to preproc
%   'notin'     : name of filetype or protocol to exclude
%   'save'      : 0 false; 1 true, save the EEG files to output directory
%
%   OUTPUT
%   'ALLEEG'    : structure of EEG structs, if processing a directory
%   'EEG'       : EEG struct, if saving a file, saves a '.set'
%
% USAGE:    Call with 'directory' to get ALLEEG struct
%           Call with 'inft' as '.bdf': load biosemi 128 files; or 
%               '.set': load existing studies to further preprocess.
%
% NOTE:     to create a log.txt without saving the EEG as output files,
%           pass an output directory without passing ('save', 'true').
% CALLS:    ctapeeg_load_data, eeglab functions
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright 2014- Benjamin Cowley, benjamin.cowley@ttl.fi
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

%% Get the paramters sorted out, intialisation & varargin calls
if nargin < 1,  directory = pwd; end;


% Unpack and store varargin (assume parameter/name pairs)
if(length(varargin) > 1)
    Arg = cell2struct(varargin(2:2:end),varargin(1:2:end),2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If desired, the default values can be changed here:
Arg.func='ctapeeg_load_dir';
Arg.time = datestr(now, 'yymmddHHMM');
try Arg.conv;     catch ME, Arg.conv       = 'anon'; end;
try Arg.inft;     catch ME, Arg.inft       = 'bdf';  end;
if strcmp(Arg.inft(1), '.') ~= 1,	Arg.inft = ['.' Arg.inft];  end;
try Arg.name;     catch ME, Arg.name       = {};     end;
try Arg.prot;     catch ME, Arg.prot       = {};     end;
try Arg.notin;    catch ME, Arg.notin      = {};     end;
try Arg.save;     catch ME, Arg.save       = false;  end;

varargout{1} = Arg;

s = filesep;
looper = 1;

%% Find the files requested, parse the input params
% If no params, do the entire current folder - no sub-selections specified.
if nargin < 1
    direc = strcat(pwd, s);
    files = dir(strcat(direc, '*', Arg.inft));
    if isempty( files ),	badparam( direc, 2 );   return; end
    looper = numel(files);
else % Parse the given filename, do either a file or a folder.
    [direc, save_name, ext] = fileparts(directory);
    % If filename is a directory, not a file
    if isdir(directory)
        % if extension is not empty when filename is a directory, 
        % path contained a period
        if ~isempty(ext)
            save_name = strcat( save_name, ext );
        end
        % Obtain all files
        files = dir(fullfile(direc, save_name, ['*', Arg.inft]));
        % Act on params to remove non-conforming files
        if ~iscell(Arg.name), Arg.name = {Arg.name};  end;
        nmnm = numel(Arg.name);
        if ~iscell(Arg.prot), Arg.prot = {Arg.prot};  end;
        nmpr = numel(Arg.prot);
        if ~iscell(Arg.notin),    Arg.notin = {Arg.notin};  end;
        nmnt = numel(Arg.notin);
        if nmnm+nmpr > 0
            for i=1:numel(files)
                [~, ~, files(i).subj, files(i).prot,...
                    files(i).ext]=parseCENTfname(files(i).name);
            end
        end
        if nmnm > 0
            marker = false(1,numel(files));
            for nm = 1:nmnm,    
                marker = marker|~cellfun( @isempty,...
                    strfind({files.subj}, Arg.name{nm}) );	
            end;
            files = files(marker);
        end
        if nmpr > 0
            marker = false(1,numel(files));
            for pr = 1:nmpr
                marker = marker|~cellfun( @isempty,...
                    strfind({files.prot}, Arg.prot{pr}) );	
            end
            files = files(marker);
        end
        if nmnt > 0
            marker = false(1,numel(files));
            for nt = 1:nmnt
                marker = marker|cellfun( @isempty, strfind(...
                    [{files.subj} {files.prot} {files.ext}], Arg.notin{nt}));
            end
            files = files(marker);
        end
         
        clear marker;
        if isempty( files ),	badparam( directory, 3 );   return; end
        looper = numel(files);
    else
        % Single file case - check file exists, and check file format
        if strcmpi( ext, '.bdf' ) == 0 && strcmpi( ext, '.set' ) == 0
            badparam( directory, 1 );   return;
        end
        files=dir(directory);
        Arg.inft = ext;
    end
    [direc,~,~]=fileparts(which(files(1).name));
end
% Output directory goes into input directory by default
try Arg.outdir;   catch ME, %#ok<*NASGU>
    if Arg.save
        Arg.outdir = fullfile( direc, [Arg.conv '_' Arg.func '_' Arg.time] );
    else
        Arg.outdir = '';
    end
end;
if Arg.save && ~isdir(Arg.outdir)
    s = mkdir(Arg.outdir);
    if s == 0,	badparam(Arg.outdir, 4);  return;	end;
end

%% Cycle through files requested (either named, or in this directory)
myReport('Loading files...', Arg.outdir);
[ALLEEG, ~, ~] = pop_newset([], [], 1, 'gui', 'off');
% [ALLEEG, EEG, ~] = pop_newset(ALLEEG, EEG, 1, 'gui', 'off');
h=NaN;
if looper>1 && usejava('jvm') && ~feature('ShowFigureWindows')
    h=waitbar(0);
end
failset=cell(looper,1);
for i = 1:looper
    if ~isnan(h),	waitbar(i/looper);  end
    
    filename = files(i).name;
    try
        EEG = ctapeeg_load_data(filename, 'inft', Arg.inft, 'conv', Arg.conv);
    catch ME,
        myReport(ME.message, Arg.outdir);
        failset{i} = filename;
        continue;
    end
    if isempty(EEG)
        failset{i} = filename;
        continue;
    end
    % Add to ALLEEG data set
    [ALLEEG, ~, ~] =...
        pop_newset(ALLEEG, EEG, i, 'gui', 'off', 'setname', save_name);
    if Arg.save
        pop_saveset(ALLEEG(i), 'filename', [save_name '.set'],...
            'filepath', Arg.outdir);
        myReport(...
        ['Saved file: ' ALLEEG(i).setname ' to path: ' Arg.outdir],Arg.outdir);
    else
        ALLEEG(i).filename = [save_name '.set'];
        ALLEEG(i).filepath = Arg.outdir;
    end
    EEG = ALLEEG(i);
    myReport(['Loaded file: ' EEG.setname], Arg.outdir);
end
failset(cellfun(@isempty,failset))=[];
if ~isempty(failset)
    myReport({'Not processed: ' failset}, Arg.outdir);
end
if ~isnan(h),   delete(h);  end
toc;
end % load_dir()
