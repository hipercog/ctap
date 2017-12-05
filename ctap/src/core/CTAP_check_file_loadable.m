function [EEG, Cfg] = CTAP_check_file_loadable(~, Cfg)
%CTAP_check_file_loadable  - check if file is loadable
%
% Description:
%   Saves results into Cfg.env.paths.featuresRoot/loadable.
%
% Syntax:
%   [Cfg] = CTAP_check_file_loadable(~, Cfg);
%
% Description:
%   Saves results into Cfg.env.paths.featuresRoot/loadable.
%
% Syntax:
%   [Cfg] = CTAP_check_file_loadable(~, Cfg)
%
% Inputs:
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_data:
%   .type   string, Data type, default: '' which uses filename extension as
%           the data type. Use .type='neurone' if MC.physiodata contains
%           NeurOne data folders instead of traditional files. 
%
% Outputs:
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: CTAP_load_data() %
% Copyright(c) 2017 :
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Return a dummy EEG object
EEG = eeg_emptyset();

%% Set optional arguments
if isfield(Cfg, 'measurement')
    Arg = Cfg.measurement;
    Arg.type = ''; %by default guesses file type from MC.physiodata file extension
else
    error('CTAP_check_file_loadable:no_measurement', 'Cfg.measurement MUST exist!');
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_data')
    Arg = joinstruct(Arg, Cfg.ctap.load_data);
end

loadable = 0;
extns = {'.set', '.bdf', '.edf', '.gdf', '.vhdr', '.eeg', '.vpd', ...
         '.xml', '.e'};
file = file_loadable(Arg.physiodata, extns);

if ~file.load
    loadable = 0;
else    
    loadable = 1;
end

INFO = gather_measurement_metadata(Cfg.subject, Cfg.measurement);

savepath = fullfile(Cfg.env.paths.featuresRoot,'loadable');
if ~isdir(savepath)
    mkdir(savepath); 
end
savename = sprintf('%s_loadable.mat', Cfg.measurement.casename);
save(fullfile(savepath,savename), 'INFO', 'loadable');


%% ERROR/REPORT
res = struct;
res.file = Arg.physiodata;

Arg = joinstruct(Arg, res);
Cfg.ctap.load_data = Arg;

msg = myReport({'Checked file loadability' Arg.physiodata}, Cfg.env.logFile);

EEG = add_CTAP(EEG, Cfg);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);