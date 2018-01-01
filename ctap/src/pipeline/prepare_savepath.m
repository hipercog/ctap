function prepare_savepath(savepath, varargin)
% prepare_savepath - Make savepath ready to receive new files

%% Parse inputs
p = inputParser;
p.addRequired('savepath', @ischar)

p.addParameter('create', true, @islogical)%create the path?
p.addParameter('deleteExisting', true, @islogical)%delete existing path contents?
p.addParameter('filenames', '*.*', @ischar)%matching filename string

p.parse(savepath, varargin{:})
Arg = p.Results;


%% Make directory if it does not exist
if ~isdir(savepath) && Arg.create
    mkdir(savepath)
end 

%% Remove existing result files
if (length(dir(savepath)) > 2) && Arg.deleteExisting
   delete(fullfile(savepath, Arg.filenames))
end