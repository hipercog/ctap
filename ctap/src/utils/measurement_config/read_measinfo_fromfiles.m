function MC = read_measinfo_fromfiles(...
    filepath, type, subject, subj_nr, varargin)
%READ_MEASINFO_FROMFILES - Read the MC from a directory which contains EEG files
%
% Description:
%
% Syntax:
%   MC = read_measinfo_fromfiles(filepath, type)
%
% Inputs:
%   'filepath'      The path to the set of files.
%   'type'          The type of file to import
%   'subject'       1x3 cell array, find subject name, usage:
%                       cell 1 regex string to search for in the filename,
%                       cell 2 offset from regex index, fix start of return val
%                               can be omitted, Default = 0
%                       cell 3 length of return value, counted from cell 1+2
%                               can be omitted, Default = length of filename
%   'subj_nr'       1x3 cell array, find subject number, usage as for 'subject'
%                       ALL CELLS MUST BE SPECIFIED
% 
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'session'       1x3 cell array, find session name, usage as for 'subject'
%                               can omit cells 2,3, and enter a singleton cell
%                               with string S, to fix 'session' = S.
%   'measurement'	1x3 cell array, find measurement name, usage as 'subject'
%                               can omit cells 2,3, and enter a singleton cell
%                               with string M, to fix 'measurement' = M.
%   'logfile'       char, path to a log file, Default = ''
%
%
% Outputs:
%   MC          A struct containing the information needed to describe the MC
%               The following fields are read from the files
%                  - subject
%                       .subject
%                  - measurement
%                       .subjectnr
%                       .session
%                       .measurement
%                       .date
%                       .physiodata
%                       .measurementlog
%                       .casename
%                       .subject
%
%
% Authors: Benjamin Cowley (FIOH, 2015)
% -------------------------------------------------------------------------


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('filepath', @ischar);
p.addRequired('type', @ischar);
p.addRequired('subject', @iscell);
p.addRequired('subj_nr', @iscell);

p.addParameter('session', {''}, @iscell);
p.addParameter('measurement', {''}, @iscell);
p.addParameter('logfile', '', @ischar);

p.parse(filepath, type, subject, subj_nr, varargin{:});
Arg = p.Results;

if isempty(Arg.type)
    error('read_measinfo_fromfiles:no_type', 'File type needed - we can''t guess')
end

%% Get files
files = dir(fullfile(Arg.filepath, Arg.type));

if numel(files)==0, error('No files found!'); end

% Assign fields of the Measurement struCt
for i = 1:numel(files)
    
    %% Get the info for the 'subject' field
    if numel(Arg.subject) < 2
        offset = 0;
    else
        offset = Arg.subject{2};
    end
    [~, tmp, ~] = fileparts(files(i).name);
    if numel(Arg.subject) < 3
        offlen = length(tmp);
    else
        offlen = min(length(tmp), ...
            regexp(files(i).name, Arg.subject{1}) + offset + Arg.subject{3} - 1);
    end
    MC.subject(i).subject = files(i).name(...
        regexp(files(i).name, Arg.subject{1}) + offset : offlen);
%     MC.subject.sex
%     MC.subject.age

    %% Get the info for the 'measurement' field
    MC.measurement(i).subject = MC.subject(i).subject;
    
    offlen = min(length(tmp), regexp(files(i).name, Arg.subj_nr{1}) +...
        Arg.subj_nr{2} + Arg.subj_nr{3} - 1);
    MC.measurement(i).subjectnr = str2double(files(i).name(...
        regexp(files(i).name, Arg.subj_nr{1}) + Arg.subj_nr{2} : offlen));

    if numel(Arg.session) > 1
        offlen = min(length(tmp), regexp(files(i).name, Arg.session{1}) +...
            Arg.session{2} + Arg.session{3} - 1);
        MC.measurement(i).session = files(i).name(...
            regexp(files(i).name, Arg.session{1}) + Arg.session{2} : offlen);
    else
        MC.measurement(i).session = Arg.session{1};
    end

    if numel(Arg.measurement)>1
        offlen = min(length(tmp), regexp(files(i).name, Arg.measurement{1}) +...
            Arg.measurement{2} + Arg.measurement{3} - 1);
        MC.measurement(i).measurement = files(i).name(...
            regexp(files(i).name, Arg.measurement{1}) + Arg.measurement{2} : offlen);
    else
        MC.measurement(i).measurement = Arg.measurement{1};
    end
    MC.measurement(i).date = files(i).date;
    MC.measurement(i).physiodata = fullfile(Arg.filepath, files(i).name);
    MC.measurement(i).measurementlog = Arg.logfile;
    MC.measurement(i).casename = [MC.subject(i).subject '_'...
                               MC.measurement(i).session '_'...
                               MC.measurement(i).measurement];
%     MC.measurement.physiodevice
%     MC.measurement.notes
%     MC.measurement.datanotes
%     MC.measurement.channelrejection

%     %% Get the info for the 'blocks' field
%     MC.blocks.casename = MC.measurement.casename;
%     MC.blocks.blockid = 1;
%     MC.blocks.starttype = 'time';
%     MC.blocks.starttime = 1;
%     MC.blocks.stoptype = 'time';
%     MC.blocks.stoptime = 60;
%     MC.blocks.tasktype
%     MC.blocks.notes
% 
%     %% Get the info for the 'events' field
%     MC.events.casename = MC.measurement.casename;
%     MC.events.eventtype
%     MC.events.timestamp
%     MC.events.eventname
end
