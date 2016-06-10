function MC = filearr2measconf(file_arr, varargin)
%FILEARR2MEASCONF - Create measurement config based on a list of files
%
% Description:
%
% Syntax:
%   MC = filearr2measconf(file_arr, varargin)
%
% Inputs (required):
%   'file_arr'      [1,m] cell of strings, Full paths to some files    
%
% Inputs (optional):
%   'subject'       [1,m] cell of strings, Subject id strings for 'file_arr'
%   'subjectnr'     [1,m] integer, Numeric ids for subjects
%   'session'       [1,m] cell of strings, Session id strings
%   'measurement'   [1,m] cell of strings, Measurement id strings
%
% Outputs:
%   MC          A struct containing the information needed to describe the MC
%               The following fields are read from the files
%                  - subject
%                       .subject
%                       .subjectnr
%                  - measurement
%                       .subject
%                       .subjectnr
%                       .session
%                       .measurement
%                       .casename
%                       .physiodata
%                       .date
%
% Example:
%   dstdir = '<some dir with *.set files>';
%   files = dir(fullfile(dstdir, '*.set'));
%   file_arr = {files.name};
%   file_arr = cellfun(@(x) fullfile(dstdir,x), file_arr, 'UniformOutput', false);
%   MC = filearr2measconf(file_arr);
%
% Authors: Jussi Korpela (FIOH, 2015)
% -------------------------------------------------------------------------


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('file_arr', @iscellstr);
p.addParameter('subject', {}, @iscellstr);
p.addParameter('subjectnr', NaN, @isnumeric);
p.addParameter('sex', repmat({'NULL'},1,length(file_arr)), @iscellstr);
p.addParameter('age', repmat(0,1,length(file_arr)), @isnumeric);
p.addParameter('session', {'session'}, @iscellstr);
p.addParameter('measurement', {'meas'}, @iscellstr);
p.parse(file_arr, varargin{:});
Arg = p.Results;

MC = struct();

%% Process defaults
if length(Arg.session)==1
    Arg.session = repmat(Arg.session, length(file_arr), 1);
end
if length(Arg.measurement)==1
    Arg.measurement = repmat(Arg.measurement, length(file_arr), 1);
end

%% Assign fields of the measurement config (MC) struct
for i = 1:numel(file_arr)
    
    [fpath, fnamebody, fext] = fileparts(file_arr{i});

    %% MC.subject & MC.measurement
    if isempty(Arg.subject)
        MC.subject(i).subject = fnamebody;
        MC.measurement(i).subject = fnamebody;
    else
        MC.subject(i).subject = Arg.subject{i};
        MC.measurement(i).subject = Arg.subject{i};
    end
    
    if isnan(Arg.subjectnr(1))
        MC.subject(i).subjectnr = i;
        MC.measurement(i).subjectnr = i;
    else
        MC.subject(i).subjectnr = Arg.subjectnr(i);
        MC.measurement(i).subjectnr = Arg.subjectnr(i);
    end
    
    MC.subject(i).age = Arg.age(i);
    MC.subject(i).sex = Arg.sex{i};
    
    MC.measurement(i).subjectnr = i;
    MC.measurement(i).session = Arg.session{i};
    MC.measurement(i).measurement = Arg.measurement{i};
    MC.measurement(i).casename =   [MC.measurement(i).subject '_'...
                                    MC.measurement(i).session '_'...
                                    MC.measurement(i).measurement];
 
    MC.measurement(i).physiodata = file_arr{i};
    
    tmp = dir(file_arr{i});
    if length(tmp) == 1
        % is a file
        ind = 1;
    else
        % is a directory (e.g. for NeurOne)
        ind = find(ismember({tmp.name},'.'));
    end
    MC.measurement(i).date = datestr(tmp(ind).datenum,30);
end
