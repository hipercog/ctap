function Cfg = get_meas_cfg_MC(Cfg, srcfile, varargin)
%GET_MEAS_CFG_MC A wrapper to read measurement config data from a given source
% 
% Description:
%   Adds the MC struct to the Cfg struct, required by CTAP to know where the 
%   data is! Can read from multiple source types, including a directory
%   (absolute or relative path), a spreadsheet, or an SQLite file
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
%               default = 'all' (a keyword to return all available)
%   eeg_ext     char, file-type of the EEG data if using directory as 'srcfile'
%   fname_filt  char, string to require in the filenames to be selected
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


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('Cfg', @isstruct)
p.addRequired('srcfile', @ischar)

p.addParameter('sbj_filt', 'all', @(x) iscell(x) || isvector(x) || isempty(x))
p.addParameter('eeg_ext', '', @ischar)
p.addParameter('fname_filt', '', @ischar)

p.parse(Cfg, srcfile, varargin{:});
Arg = p.Results;

[pathstr, name, ext] = fileparts(srcfile); 


%% FIND
% first create measurement structure from given dir and file extension
switch ext
    case ''
        f_arr = path2filearr(srcfile, Arg.eeg_ext, Arg.fname_filt, p.Unmatched);
        if isempty(Arg.eeg_ext)%Get only EEG files of one type in file array
            [~, ~, es] = cellfun(@fileparts, f_arr, 'Un', 0);
            rejfs = ~ismember(strrep(es, '.', ''), ctap_supported_eeg_types);
            if ~isscalar(unique(es(~rejfs)))
                error('get_meas_cfg_MC:fileTypeError',...
                    'Too many EEG input types discovered at ''%s''.', srcfile)
            else
                f_arr(rejfs) = [];
            end
        end
        MC = filearr2measconf(f_arr, p.Unmatched);
        
    case '.sqlite'
        MC = read_measinfo_sqlite(srcfile);
    case '.xls' | '.xlsx'
        MC = read_measinfo_spreadsheet(srcfile);
    otherwise
        if strcmp(name, '*') && ismember(ext, ctap_supported_eeg_types)
            MC = filearr2measconf(...
                path2filearr(pathstr, ext, fname_filt, p.Unmatched)...
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
[~, fltidx] = name_filter(cell2struct({MC.subject.subject}, 'name'), Arg.sbj_filt);
Filt.subject = Filt.subject(fltidx);
% OLD WAY:
% if ~isempty(Arg.sbj_filt)
%     if iscell(Arg.sbj_filt)
%         comparand = {MC.subject.subject};
%     else
%         comparand = [MC.subject.subjectnr];
%     end
%     Filt.subject = Filt.subject(ismember(comparand, Arg.sbj_filt));
% end
runMC = get_measurement_id(MC, Filt);


%% RETURN
% TODO?? UPDATE cfg_validate_paths WITH RATIONAL PATH CHECKING - IT'S A
% GOOD IDEA TO VALIDATE HARDCODED PATHS, BUT HOW TO PROVIDE GROUND TRUTH?
% Fix spreadsheet-hardcoded paths to match locale
% if any(strcmpi(ext, {'.sqlite' '.xls' '.xlsx'}))
%     Cfg = cfg_validate_paths(Cfg);
% end

Cfg.MC = MC;
Cfg.pipe.runMeasurements = runMC;

end
