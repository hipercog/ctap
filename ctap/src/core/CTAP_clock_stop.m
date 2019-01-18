function [EEG, Cfg] = CTAP_clock_stop(EEG, Cfg)
%CTAP_clock_stop  - stops clock and outputs elapsed time as feature
%
%
% Syntax:
%   [Cfg] = CTAP_clock_stop(~, Cfg);
%
% Description:
%   Saves elapsed time since last call of CTAP_clock_start
%   into Cfg.env.paths.featuresRoot/elapsed.
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
% See also: CTAP_clock_stop() %
% Copyright(c) 2017 :
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
elapsed = seconds(time(between(Cfg.elapsed.clockstart, datetime('now'))));
Arg.elapsed = elapsed;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'clock_stop')
    Arg = joinstruct(Arg, Cfg.ctap.clock_stop);
end

[INFO, SEGMENT] = gather_measurement_metadata(Cfg.subject, Cfg.measurement); %#ok<*ASGLU>

savepath = fullfile(Cfg.env.paths.featuresRoot, 'elapsed');
if ~isfolder(savepath), mkdir(savepath); end
savename = sprintf('%s_elapsed.mat', Cfg.measurement.casename);
save(fullfile(savepath, savename), 'INFO', 'SEGMENT', 'elapsed');


%% CORE
Cfg.elapsed.elapsed = elapsed;


%% ERROR/REPORT
msg = myReport({'Elapsed ' Arg.elapsed}, Cfg.env.logFile);

EEG = add_CTAP(EEG, Cfg);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);