function Cfg = ctap_auto_config(Cfg, fun_args)
%CTAP_AUTO_CONFIG - Processes configuration file/struct with respect to the 
% desired analysis pipe.
%
% Does the following: 
%   * adds canonical locations to Cfg
%   * adds some CTAP conventions (default settings)
%   * assigns pipeline function parameters to Cfg.ctap
%   * checks if number of defined parameters is scalar or matches function calls
%   * checks that EEG reference, chanlocs have been given
%
% Details:
%   *   Finds indices of sets to run, then assigns function arg specifications
%       to Cfg.ctap, based on finding arg struct names inside function 
%       handle names
%
% Syntax:
%   Cfg = ctap_auto_config(Cfg, fun_args);
%
% Inputs:
%   'Cfg'       struct, defines paths, pipe, etc: see documentation
%   'fun_args'  struct, user-defined parameters for the function calls
%               specified in the pipebatch script. See above for
%               specifications
%
% Outputs:
%   'Cfg'       struct, updated configuration of paths, functions and parameters
%
%
% Version History:
% 08.12.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('OFF', 'BACKTRACE')


%% Add some CTAP-wide conventions
% Event type strings 
Cfg.event.badSegment = 'badSegment';
if ~isfield(Cfg.event, 'csegEvent')
    Cfg.event.csegEvent = 'cseg';
    % Set value to the one used by CTAP_generate_cseg_*.m
end

% Define graphics 'globals'
if ~isfield(Cfg, 'grfx')
    Cfg.grfx.on = true;
end


%% Add canonical locations to Cfg
if isfield(Cfg.env.paths, 'ctapRoot')
    
    % First step set input data is loaded from:
    if ~isfield(Cfg.env.paths, 'branchSource')
        warning('ctap_auto_config:no_basepath', ['Please use cfg_create_paths()',...
            ' to create canonical basepaths for your config.']);
        Cfg.env.paths.branchSource = ''; %the default
    end
    
    % All results are saved in:
    if ~isfield(Cfg.env.paths, 'analysisRoot')
        warning('ctap_auto_config:no_basepath', ['Please use cfg_create_paths()',...
            ' to create canonical basepaths for your config.']);
        Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.ctapRoot, Cfg.id);
    end
    [~,~,~] = mkdir(Cfg.env.paths.analysisRoot);
    
    if ~isfield(Cfg.env.paths, 'featuresRoot')
        Cfg.env.paths.featuresRoot = fullfile(...
            Cfg.env.paths.analysisRoot,'features');
    end

    if ~isfield(Cfg.env.paths, 'export')
        Cfg.env.paths.exportRoot = fullfile(...
            Cfg.env.paths.analysisRoot,'export');
    end

    if ~isfield(Cfg.env.paths, 'quality_control')
        Cfg.env.paths.qualityControlRoot = fullfile(...
            Cfg.env.paths.analysisRoot,'quality_control');
    end
    
    if ~isfield(Cfg.env.paths, 'logRoot')
        Cfg.env.paths.logRoot = fullfile(...
            Cfg.env.paths.analysisRoot,'logs');
    end        
    
    if ~isfield(Cfg.env.paths,'crashLogRoot')
        Cfg.env.paths.crashLogRoot = fullfile(...
            Cfg.env.paths.ctapRoot,'logs');
    end
    
    % Log Files
    if isfield(Cfg.env, 'logFile')
        Cfg.env.userLogFile = Cfg.env.logFile;
    end
    Cfg.env.logFile = fullfile(Cfg.env.paths.logRoot,...
                               sprintf('runlog_%s.txt',datestr(now, 30)) );

    % SQLite database file for storing function data
    %(such as numbers of trials etc.)
    Cfg.env.funDataDB = fullfile(Cfg.env.paths.qualityControlRoot,...
                        'ctap_function_data.sqlite');
                           
else
   error('ctap_auto_config:cfgFieldMissing', ['Cfg.env.paths.ctapRoot is ',...
       'required for CTAP to work. It specifies the location of CTAP output.']); 
end


%% Check that required fields exist and have proper values
if ~isfield(Cfg, 'eeg')
   error('ctap_auto_config:cfgFieldMissing',...
     ['EEG specifications not given. Please add field ''Cfg.eeg'', along'...
     'with values for ''Cfg.eeg.reference'' and ''Cfg.eeg.chanlocs''.']); 
end

%Cfg.eeg.reference: required to make sure user understands importance of choice
%NB! - Cannot check Cfg.eeg.reference here: channel names not available
if isfield(Cfg.eeg, 'reference')
    if ischar(Cfg.eeg.reference)
       Cfg.eeg.reference = cellstr(Cfg.eeg.reference);%shud be cell string array
    end
else
   error('ctap_auto_config:cfgFieldMissing',...
     ['EEG reference channel not specified. Please add field Cfg.eeg.'...
     'reference with a value of: some channel name, ''average'' or ''asis''.']); 
end

if ~isfield(Cfg.eeg, 'chanlocs')
    warning('ctap_auto_config:cfgFieldMissing',...
         'Field Cfg.eeg.chanlocs is required for CTAP to work.');
end

if ~isfield(Cfg.eeg, 'veogChannelNames')
    warning('ctap_auto_config:cfgFieldMissing',...
         ['Field Cfg.eeg.veogChannelNames is recommended for blink'... 
         'artefact detection and rejection.']);
end

if ~isfield(Cfg.eeg, 'heogChannelNames')
    warning('ctap_auto_config:cfgFieldMissing',...
         ['Field Cfg.eeg.heogChannelNames is recommended for ocular'...
         'artefact detection and rejection.']);
end

if isfield(Cfg, 'export')
    if ~isfield(Cfg.export, 'featureSavePoints')
        Cfg.export.featureSavePoints = {};
    end
    if ~isfield(Cfg.export, 'ovw')
        Cfg.export.ovw = false;
    end
end


%% Measure pipe - parse given stepSets and runSets

% 1st, if runSets is numeric, convert to stepSet.id cell string array
if isnumeric(Cfg.pipe.runSets) 
    if all(ismember(Cfg.pipe.runSets, 1:numel(Cfg.pipe.stepSets)))
        Cfg.pipe.runSets = {Cfg.pipe.stepSets(Cfg.pipe.runSets).id};
    else
        error('ctap_auto_config:bad_runSets', 'runSets (%s) is not valid'...
            , myReport({'SHSH' Cfg.pipe.runSets}))
    end
elseif ischar(Cfg.pipe.runSets)
    Cfg.pipe.runSets = {Cfg.pipe.runSets};
end

% 2nd, Discard the 'test' step set if present and not requested
if ~any(ismember(Cfg.pipe.runSets, 'test'))
    Cfg.pipe.stepSets(ismember({Cfg.pipe.stepSets.id}, 'test')) = [];
end

% 3rd, get original (allSets) stepSet indices
allSets = 1:numel(Cfg.pipe.stepSets);

% 4th, get requested (runSets) stepSet indices
if strcmpi(Cfg.pipe.runSets{1}, 'all')
    runSets = allSets;
    Cfg.pipe.runSets = {Cfg.pipe.stepSets(allSets).id};
    %'all' replaced to simplify usage of this field -- 'all' not allowed
    % in general, just a convenience feature
else
    runSets = find(ismember({Cfg.pipe.stepSets.id}, Cfg.pipe.runSets));
    if isempty(runSets)
        error('ctap_auto_config:bad_runSets', '%s was badly specified'...
            , myReport({'SHSH' Cfg.pipe.runSets}))
    end
end

% Add field Cfg.pipe.totalSets if missing
if ~isfield(Cfg.pipe, 'totalSets')
    Cfg.pipe.totalSets = numel(runSets);
else
    Cfg.pipe.totalSets = Cfg.pipe.totalSets + numel(runSets);
end


%% Run checks on the pipe

%Check needed pipe fields that the user can leave unspecified 
if ~isfield(Cfg.pipe.stepSets, 'srcID') %check srcID
    [Cfg.pipe.stepSets.srcID] = deal([]);
end
if ~isfield(Cfg.pipe.stepSets, 'save') %check save instruction
    [Cfg.pipe.stepSets.save] = deal(true);
else
    [Cfg.pipe.stepSets(cellfun(@isempty, {Cfg.pipe.stepSets.save})).save] =...
        deal(true);
    if Cfg.pipe.totalSets == numel(runSets) &&...%=> we're in first pipe
       numel(allSets) > 1 &&...%=> pipe has multiple steps
       ~Cfg.pipe.stepSets(1).save %=> save for step 1 is turned off
        warning('ctap_auto_config:badSaveSpec',...
            ['NO SAVE ON STEP 1: the pipe must save intermediary data to have'...
                ' multiple steps - check your save specification']);
    end
end


%% GET INDICES OF PIPE

% Get the complete pipe description
[allPipeFuns, allStepMap] = sbf_get_pipe_desc(Cfg, allSets);
% exclStp = find(~ismember(allSets, runSets));
% exclIdx = find(ismember(allStepMap, exclStp));

% Get the contents of the requested pipe description
[runPipeFuns, runStepMap] = sbf_get_pipe_desc(Cfg, runSets); %#ok<ASGLU>
uniqFuns = unique(runPipeFuns);
leftout = ones(numel(uniqFuns),1);

% Get whole-pipe indices of called functions
runFunIdx = find(ismember(allStepMap, runSets));

% Get the configuration parameter names
defPars = fieldnames(fun_args);
numdfpm = numel(defPars);

% Find where exist multiple entries per function in parameters
manyArg = zeros(numdfpm,1);
for i = 1:numdfpm
    tmp = size(fun_args.(defPars{i}));
    if sum(tmp > 1), manyArg(i) = tmp(tmp > 1); end
end


%% ADD ANALYSIS STEP PARAMETERS TO Cfg
% copy parameters to the Cfg struct for the pipeline_looper
% if there are multiple calls to function i and only one instance of the
% parameters, turn parameters into a struct array of dimension [1,n] 
% where n = number of calls to function i
for i = 1:numdfpm
    uniqPars = ~cellfun(@isempty, strfind(uniqFuns, defPars{i}));
    
    if sum(uniqPars) > 1
        tmpstr = sprintf('''%s''\t', uniqFuns{uniqPars});
        error('ctap_auto_config:param_funcname_mismatch',...
            'parameter ''%s'' matches to %d function names: %s',...
            defPars{i}, sum(uniqPars), tmpstr);
        
    elseif sum(uniqPars)
        %get indexing info for the function: order and number of calls
        fOrd = sbf_get_fun_order(defPars{i}, allPipeFuns, runFunIdx, runPipeFuns);
        fNumCalls = sum(ismember(runPipeFuns, uniqFuns{uniqPars}));
        
        %remove any prior initialisation for this function
        if isfield(Cfg, 'ctap') && isfield(Cfg.ctap, defPars{i})
            Cfg.ctap = rmfield(Cfg.ctap, defPars{i});
        end
        
        if isscalar(fun_args.(defPars{i}))
            %scalar argument structs get dealt to each function call
            Cfg.ctap.(defPars{i})(1:fNumCalls) = deal(fun_args.(defPars{i}));
            
        elseif numel(fOrd) == fNumCalls &&...
                all(ismember(fOrd, 1:numel(fun_args.(defPars{i}))))
            %struct array arguments get assigned by order of function calls
            Cfg.ctap.(defPars{i})(1:fNumCalls) = fun_args.(defPars{i})(fOrd);
            
        else
            %sthg is terribly wrong!
            error('ctap_auto_config:multi_param_mismatch'...
                , ['Parameter struct ''fun_args.%s'' has %d rows; BUT ''%s'''...
                ' is called in complete pipe %d time, & in run pipe %d '...
                'time :: can''t infer parameter assignment! Aborting']...
                , defPars{i}...
                , numel(fun_args.(defPars{i}))...
                , uniqFuns{uniqPars}...
                , sum(ismember(allPipeFuns, uniqFuns{uniqPars}))...
                , fNumCalls);
        end
    end
    leftout = leftout & ~uniqPars;
end

% Make parameter fields as empty structs where none were specified
uniqFuns = uniqFuns(leftout);
fu_names = strrep(uniqFuns, 'CTAP_', '');
fu_names = strrep(fu_names, 'ctapeeg_', '');
for i = 1:numel(uniqFuns)
    num_fun_occ = sum(ismember(runPipeFuns, uniqFuns{i}));
    nopars = struct([fu_names{i} '_user_params'], 0);
    Cfg.ctap.(fu_names{i}) = repmat(nopars, 1, num_fun_occ);
end


%% RUN CHECKS
% Check if there are multiple calls to extract features and add extra level 
% to save path for export functions called more than once per pipe. 
% Prepend .extra_path with index of function occurence in complete pipe to
% help keep paths stable when pipes are called with subset of stepSets.
xfn = {'extract_bandpowers', 'extract_PSDindices', 'export_psd'};
for ftx = 1:numel(xfn)
    idx_xtr = sbf_get_fun_order(xfn{ftx}, allPipeFuns, runFunIdx, runPipeFuns);
    if isempty(idx_xtr)
        return
    end
    if isscalar(Cfg.ctap.(xfn{ftx}))
        Cfg.ctap.(xfn{ftx})(2:numel(idx_xtr)) = Cfg.ctap.(xfn{ftx})(1);
    end
    for ix = 1:numel(idx_xtr)
        Cfg.ctap.(xfn{ftx})(ix).extra_path = sprintf('%d%s', idx_xtr(ix),...
            Cfg.pipe.stepSets(idx_xtr(ix)).id(2:end));
    end
end

% Check pipe has minimum requirements and suggest mandatory reref.
%   Only if current stepSets is not a subset excluding step 1
if numel(runSets) == numel(allSets) && numel(runSets) == Cfg.pipe.totalSets
    %check for chanlocs
    tmp = cellfun(@isempty, strfind(runPipeFuns, 'load_chanlocs'));
    if all(tmp)
        warning('ctap_auto_config:no_load_chanlocs',...
            '**** MAKE SURE you have chanlocs or pipe may FAIL ****');
    end
    %check for reref
    tmp = cellfun(@isempty, strfind(runPipeFuns, 'reref_data'));
    if all(tmp)
        warning('ctap_auto_config:no_reref_data',...
         'NO reref! Consider ADDING data re-reference (once chanlocs exist)??');
    end
end

warning('ON', 'BACKTRACE')


end %ctap_auto_config()


function idxFun = sbf_get_fun_order(fn, apf, rfi, rpf)
% fn - function name, with or without 'CTAP_' or 'ctapeeg_' prefix
% apf - all pipe function names
% rfi - run pipe function indices
% rpf - run pipe function names

    fn = strrep(fn, 'CTAP_', '');
    fn = strrep(fn, 'ctapeeg_', '');
    all_idx = find(ismember(apf, ['CTAP_' fn]) | ismember(apf, ['ctapeeg_' fn]));
    if isempty(all_idx)
        idxFun = [];
    else
        idxFun = find(ismember(all_idx, rfi(ismember(rpf, ['CTAP_' fn]))));
    end
end


function [pipe_fun_names, step_map] = sbf_get_pipe_desc(Cfg, idx)
    pipe_size = numel([Cfg.pipe.stepSets(idx).funH]);%get size of requested pipe
    pipe_fun_names = cell(pipe_size, 1);
    step_map = zeros(pipe_size, 1);

    p = 1; % get the function names of the requested pipe
    for i = idx %over stepSets
        for k = 1:numel(Cfg.pipe.stepSets(i).funH) %over analysis steps
            pipe_fun_names{p} = func2str(Cfg.pipe.stepSets(i).funH{k});
            step_map(p) = i;
            p = p + 1;
        end
    end
end
