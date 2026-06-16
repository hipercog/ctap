function Cfg = get_meas_cfg_MC(Cfg, srcfile, varargin)
%GET_MEAS_CFG_MC A wrapper to read measurement config data from a given source
% 
% Description:
%   Adds the MC struct to the Cfg struct, required by CTAP to know where the 
%   data is! Can read from multiple source types, including spreadsheet, SQLite file,
%   a directory (absolute or relative path), or a wildcard filename pattern
% 
% Syntax:
%   Cfg = get_meas_cfg_MC(Cfg, srcfile, varargin)
%
% Inputs:
%   Cfg         struct, CTAP configuration structure
%   srcfile     char, path to a spreadsheet, sqlite, or directory to read MC
% 
%   varargin:
%   sbj_filt    cell | vector | empty, some index of subjects to choose,
%               default = returns all available
%   meas_filt   char, string matching measurements to be selected
%               default = returns all available
%   eeg_ext     char, file-type of the EEG data if using directory as 'srcfile'
%               default = ''
%   fname_filt  char, string to require in the filenames to be selected
%               default = returns all available
%
% Outputs:
%   Cfg         struct, Cfg struct is updated by a valid Measurement Config
%
% Notes: 
%
% Copyright(c) 2018 :
% Benjamin Cowley (ben.cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FIXME - REVIEW THE USE CASES HERE, SEEMS TO BE SOME CONFUSION IN PURPOSE
% IN fname_filt

%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('Cfg', @isstruct)
p.addRequired('srcfile', @ischar)

p.addParameter('sbj_filt', 'all', @(x) iscell(x) || isvector(x) || isempty(x))
p.addParameter('meas_filt', '', @ischar)
p.addParameter('eeg_ext', '', @ischar)
p.addParameter('fname_filt', '', @ischar)

p.parse(Cfg, srcfile, varargin{:});
Arg = p.Results;

[pathstr, name, ext] = fileparts(srcfile);
ext = strrep(ext, '.', '');
if strcmpi(Arg.fname_filt, 'all')
    Arg.fname_filt = '';
end


%% FIND
% first create measurement structure from given dir and file extension
switch ext
    case 'sqlite'                                  %read from a database file
        MC = read_measinfo_sqlite(srcfile);

    case {'xls' 'xlsx'}                           %read from a spreadsheet file
        MC = read_measinfo_spreadsheet(srcfile);

    case ''                                        %read from a directory
        f_arr = path2filearr(srcfile, Arg.eeg_ext, Arg.fname_filt, p.Unmatched);
        if isempty(Arg.eeg_ext)%Get only EEG files of one type in file array
            [~, ~, es] = cellfun(@fileparts, f_arr, 'Un', 0);
            rejfs = ~ismember(strrep(es, '.', ''), ctapeeg_supported_types);
            if ~isscalar(unique(es(~rejfs)))
                error('get_meas_cfg_MC:fileTypeError',...
                    'Too many EEG input types discovered at ''%s''.', srcfile)
            else
                f_arr(rejfs) = [];
            end
        end
        MC = filearr2measconf(f_arr, p.Unmatched);
        
    otherwise                                      %read from a wildcard filename
% FIXME - SUPPORT USER TO ENTER WILDCARD SOURCE NAME WITH FIXED PART THAT
% MATCHES FILES...E.G. *conditionA*.bdf
        if contains(name, '*') && ismember(ext, ctapeeg_supported_types)
            MC = filearr2measconf(...
                path2filearr(pathstr, ext, Arg.fname_filt, p.Unmatched)...
                , p.Unmatched);
        else
            error('get_meas_cfg_MC:fileTypeError',...
               'The input file type ''%s'' is not supported.', ext)
        end
end


%% FILTER
if isempty(MC) || (isstruct(MC) && isempty(fieldnames(MC)))
    error('get_meas_cfg_MC:no_MC', 'No measurement configuration was found')
end
% Select measurements to process, matching to contents of Arg.sbj_filt
Filt.subject = {MC.subject.subject};
[~, fx] = name_filter(cell2struct({MC.subject.subject}, 'name'), Arg.sbj_filt);
Filt.subject = Filt.subject(fx);
% Select measurements to process, matching to contents of Arg.fname_filt
if ~isempty(Arg.meas_filt)
    Filt.measurement = {MC.measurement.measurement};
    [~, fx] = name_filter(cell2struct({MC.measurement.measurement}, 'name')...
        , Arg.meas_filt);
    Filt.measurement = Filt.measurement(fx);
end


%% RETURN
Cfg.MC = MC;
Cfg.pipe.runMeasurements = get_measurement_id(MC, Filt);

end
