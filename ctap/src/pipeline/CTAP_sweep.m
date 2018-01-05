function [EEG, Cfg] = CTAP_sweep(EEG, Cfg)
%CTAP_sweep - A CTAP wrapper function for HYDRA-parameter sweeping
%
% Description: sweeps the specified parameter range for the specified
%              function against the specified data.
%
% Syntax:
%   [EEG, Cfg] = CTAP_sweep(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct should be updated with parameter values
%                       actually used
%
% Notes: 
%
% See also: 
%
% Copyright(c) 2017 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
Arg.overwrite = true;
Arg.figVisible = 'off';
Arg.choose_result = 'inflection';
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'sweep')
    Arg = joinstruct(Arg, Cfg.ctap.sweep);%override with user params
end

if ~isfield(Cfg.env.paths, 'sweepRoot')
    Cfg.env.paths.sweepRoot = fullfile(Cfg.env.paths.analysisRoot, 'sweeps');
end


%% ASSIST
% Perform checks.
if ~isfield(Cfg.ctap.sweep, 'function')
    error('CTAP_sweep:bad_params', 'Must define target function to sweep!')
end
if ~isfield(Cfg.ctap.sweep, 'sweep_param')
    error('CTAP_sweep:bad_params', 'Must define target parameter to sweep!')
end
if ~isfield(Cfg.ctap.sweep, Cfg.ctap.sweep.sweep_param)
    error('CTAP_sweep:bad_params'...
        , 'Must define set or range of target parameter values to sweep over!')
end

% Make paths
svpath = fullfile(get_savepath(Cfg, '', 'sweep'), EEG.CTAP.measurement.casename);
prepare_savepath(svpath, 'deleteExisting', Arg.overwrite);

% If not given, Build the pseudo-pipe for sweeping config
if ~isfield(Arg, 'SWPipe')
    SWPipe.funH = {@Arg.function,...
                   @CTAP_reject_data };
    SWPipe.id = '1_swept';
else
    SWPipe = Arg.SWPipe;
end
param_field = strrep(Arg.function, 'CTAP_', '');
if ~isfield(Arg, 'SWPipeParams')
    SWPipeParams.(param_field).method = Cfg.ctap.(param_field).method;
else
    SWPipeParams.(param_field) = Arg.SWPipeParams;
end

SweepParams.funName = Arg.function;
SweepParams.paramName = Arg.sweep_param;
SweepParams.values = num2cell(Arg.(Arg.sweep_param));


%% CORE - SWEEP THE LEG!
[SWEEG, PARAMS] =...
CTAP_pipeline_sweeper(EEG, SWPipe, SWPipeParams, Cfg, SweepParams); %#ok<*ASGLU>


%% ANALYZE THE SWEEP OUTCOMES...
n_sweeps = numel(SWEEG);
dmat = NaN(n_sweeps, 2);
cost_arr = NaN(n_sweeps, 1);

% REPORT BADNESS
switch Arg.function
case 'CTAP_detect_bad_channels'
    for i = 1:n_sweeps
        dmat(i,:) = [SweepParams.values{i},...
                    numel(SWEEG{i}.CTAP.badchans.variance.chans) ];
        myReport(sprintf('mad: %1.2f, n_chans: %d\n', dmat(i,1), dmat(i,2))...
            , fullfile(svpath, 'sweeplog.txt'));

        % PLOT BADNESS
        if ~isempty(SWEEG{i}.CTAP.badchans.variance.chans)
            figh = ctap_plot_bad_chan_scalp(EEG...
                , get_eeg_inds(EEG, SWEEG{i}.CTAP.badchans.variance.chans)...
                , 'context', sprintf('sweep-%d', i)...
                , 'savepath', svpath); %#ok<*NASGU>
        end
    end
    
    % Plot sweep
    figH = figure('Position', get(0,'ScreenSize'), 'Visible', Arg.figVisible);
    plot(dmat(:,1), dmat(:,2), '-o');
    xlabel('MAD multiplication factor');
    ylabel('Number of artefactual channels');
    saveas(figH, fullfile(svpath, 'sweep_N-bad-chan.png'));
    close(figH);

%TODO: ADD OUTPUT FOR BAD COMPONENT AND BAD EPOCH SWEEPS
    
end

% FIND INFLECTION POINT.
% ALGORITHM:
if strcmp(Arg.choose_result, 'inflection')
    % SELECT FIRST POINT WHERE DIFF TO LAST POINT IS CLOSEST TO 1SD OF Y
    [~, i] = min(abs(abs(diff(dmat(:,2))) - std(dmat(:,2))));
    result = mean([dmat(i, 1) dmat(i + 1, 1)]);
else
    % TAKE VALUE FOR WHICH BADNESS IS CLOSEST TO 10%
    r = round((max(dmat(:,2)) - min(dmat(:,2))) / numel(dmat(:,2)));
    x = interp(dmat(:,1), r);
    y = interp(dmat(:,2), r);
    pc = EEG.nbchan / 10;
    [~, i] = min(abs(y - pc));
    result = x(i);
end


%%%% TODO: Test quality of identifications based on full HYDRA implementation - 
%%%% GENERATE GROUND TRUTH DATA AND ARTEFACTS FROM EEG, AND SEE WHAT IS CAUGHT



%% Finally, set the relevant parameter field of target function to be 'result'
Cfg.ctap.(param_field).(Arg.sweep_param) = result;


%% ERROR/REPORT
%... the complete parameter set from the function call ...
Cfg.ctap.sweep = Arg;
%log outcome to console and to log file
msg = myReport(sprintf('HYDRA swept function ''%s'', parameter ''%s'', to %d',...
    Arg.function, Arg.sweep_param, result), Cfg.env.logFile);
%create a history element
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
