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
%   NOTE! FOR THESE 4 INPUTS ONE CAN ALSO READ FROM FILENAME USING REGEX.
%   INSTEAD OF PASSING ONE STRING/NUMBER PER SUBJECT, ENTER THE FOLLOWING:
%                   1x3 cell array, find subject name/number/etc, usage:
%                       cell 1 regex string to search for in the filename,
%                       cell 2 offset from regex index, typically set to 0
%                       cell 3 length of return value, counted from cell 1+2
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
%   file_arr = path2filearr('<some dir with *.set files>', '*.set');
%   MC = filearr2measconf(file_arr);
%
% Authors: Jussi Korpela (FIOH, 2015), Bnejamin Cowley (2019)
% -------------------------------------------------------------------------


%% Parse input arguments and set varargin defaults
p = inputParser;

p.addRequired('file_arr', @iscellstr)

p.addParameter('subject', {}, @iscell)
p.addParameter('subjectnr', NaN, @(x) isnumeric(x) || iscell(x))
p.addParameter('sex', repmat({'NULL'}, 1, length(file_arr)), @iscellstr)
p.addParameter('age', zeros(1, length(file_arr)), @isnumeric)
p.addParameter('session', {'session'}, @iscell)
p.addParameter('measurement', {'meas'}, @iscell)

p.parse(file_arr, varargin{:})
Arg = p.Results;

MC = struct();

%% Process defaults
if length(Arg.session) == 1
    Arg.session = repmat(Arg.session, length(file_arr), 1);
end

if length(Arg.measurement) == 1
    Arg.measurement = repmat(Arg.measurement, length(file_arr), 1);
end

% make these checks on regex-able parameters outside the loop, for less overhead
rgx = [0 1 1];


%% Assign fields of measurement config (MC) struct: MC.subject & MC.measurement
for i = 1:numel(file_arr)
    
    [fpath, fname, fext] = fileparts(file_arr{i});

    % Subject name
    testi = cellfun(@isnumeric, Arg.subject);
    if length(Arg.subject) == 3 && all(testi(:)' == rgx) %#ok<*BDSCI>
        MC.subject(i).subject = sbf_regex_namepart(fname, Arg.subject);
    elseif isempty(Arg.subject)
        MC.subject(i).subject = fname;
    else
        MC.subject(i).subject = Arg.subject{i};
    end
    % Subject number
    if iscell(Arg.subjectnr)
        testi = cellfun(@isnumeric, Arg.subjectnr);
        if length(Arg.subjectnr) == 3 && all(testi(:)' == rgx)
            MC.subject(i).subjectnr = ...
                        str2double(sbf_regex_namepart(fname, Arg.subjectnr));
        end
    elseif isnan(Arg.subjectnr)
        MC.subject(i).subjectnr = i;
    else
        MC.subject(i).subjectnr = Arg.subjectnr(i);
    end
    % Subject age and sex
    MC.subject(i).age = Arg.age(i);
    MC.subject(i).sex = Arg.sex{i};
    
    % Measurement version of subject name and number (same as MC.subject)
    MC.measurement(i).subject = MC.subject(i).subject;
    MC.measurement(i).subjectnr = MC.subject(i).subjectnr;
    % Measurement session
    testi = cellfun(@isnumeric, Arg.session);
    if length(Arg.session) == 3 && all(testi(:)' == rgx)
        MC.measurement(i).session = sbf_regex_namepart(fname, Arg.session);
    else
        MC.measurement(i).session = Arg.session{i};
    end
    % Measurement measurement
    testi = cellfun(@isnumeric, Arg.measurement);
    if length(Arg.measurement) == 3 && all(testi(:)' == rgx)
        MC.measurement(i).measurement = sbf_regex_namepart(fname, Arg.measurement);
    else
        MC.measurement(i).measurement = Arg.measurement{i};
    end
    % Measurement casename (important, used naming output files in CTAP)
    MC.measurement(i).casename =   [MC.measurement(i).subject '_'...
                                    MC.measurement(i).session '_'...
                                    MC.measurement(i).measurement];
    % Measurement data source
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

    %% Get 'subject/nr', 'session', or 'measurement' from filename with regex
    function out = sbf_regex_namepart(filename, rgx_cell)
        offset = rgx_cell{2};
        offlen = min(length(filename), ...
                regexp(filename, rgx_cell{1}) + offset + rgx_cell{3} - 1);
        out = filename(regexp(filename, rgx_cell{1}) + offset : offlen);
    end
end