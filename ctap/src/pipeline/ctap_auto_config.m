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

warned = false;


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
        warning('You should use cfg_create_paths() to create canonical basepaths for your config.');
        Cfg.env.paths.branchSource = ''; %the default
    end
    
    % All results are saved in:
    if ~isfield(Cfg.env.paths, 'analysisRoot')
        warning('You should use cfg_create_paths() to create canonical basepaths for your config.');
        Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.ctapRoot, Cfg.id);
    end
    [~,~,~] = mkdir(Cfg.env.paths.analysisRoot);
    
    
    Cfg.env.paths.featuresRoot = fullfile(...
        Cfg.env.paths.analysisRoot,'features');

    Cfg.env.paths.exportRoot = fullfile(...
        Cfg.env.paths.analysisRoot,'export');

    Cfg.env.paths.qualityControlRoot = fullfile(...
        Cfg.env.paths.analysisRoot,'quality_control');
    
    Cfg.env.paths.logRoot = fullfile(...
        Cfg.env.paths.analysisRoot,'logs');
    
    Cfg.env.paths.crashLogRoot = fullfile(...
        Cfg.env.paths.ctapRoot,'logs');
    
    % Log Files
    Cfg.env.logFile = fullfile(Cfg.env.paths.logRoot,...
                               sprintf('runlog_%s.txt',datestr(now, 30)) );

else
   error('ctap_auto_config:cfgFieldMissing',...
         'Cfg.env.paths.ctapRoot is required for CTAP to work. It specifies the location of CTAP output.'); 
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
    warned = true;
end

if ~isfield(Cfg.eeg, 'veogChannelNames')
    warning('ctap_auto_config:cfgFieldMissing',...
         ['Field Cfg.eeg.veogChannelNames is recommended for blink'... 
         'artefact detection and rejection.']);
    warned = true;
end

if ~isfield(Cfg.eeg, 'heogChannelNames')
    warning('ctap_auto_config:cfgFieldMissing',...
         ['Field Cfg.eeg.heogChannelNames is recommended for blink'...
         'artefact detection and rejection.']);
    warned = true;
end


%% Run checks on the pipe
%Discard the 'test' step set if present and not requested
if ~any(ismember(Cfg.pipe.runSets, 'test'))
    testtest = ismember({Cfg.pipe.stepSets.id}, 'test');
    if any(testtest), Cfg.pipe.stepSets(testtest) = []; end
end

%Check needed pipe fields that the user can leave unspecified 
if ~isfield(Cfg.pipe.stepSets, 'srcID') %check srcID
    [Cfg.pipe.stepSets.srcID] = deal([]);
end
if ~isfield(Cfg.pipe.stepSets, 'save') %check save instruction
    [Cfg.pipe.stepSets.save] = deal(true);
else
    [Cfg.pipe.stepSets(cellfun(@isempty, {Cfg.pipe.stepSets.save})).save] =...
        deal(true);
    if numel(Cfg.pipe.stepSets) > 1 && ~Cfg.pipe.stepSets(1).save
        warning('ctap_auto_config:badSaveSpec',...
            ['NO SAVE ON STEP 1: the pipe must save intermediary data to have'...
                ' multiple steps - check your save specification']);
        warned = true;
    end
end


%% ADD ANALYSIS STEP PARAMETERS TO Cfg
%get original and requested pipe stepSet indices
allSets = 1:numel(Cfg.pipe.stepSets);
fixcfg = false;
if strcmp(Cfg.pipe.runSets{1}, 'all')
    runSets = allSets;
else
    runSets = find(ismember({Cfg.pipe.stepSets.id}, Cfg.pipe.runSets));
    if numel(runSets) ~= numel(allSets)
        fixcfg = true;
    end
end

%get the contents of the requested pipe, check srcID
pipesz = numel([Cfg.pipe.stepSets(runSets).funH]); % get size of requested pipe
pipeFuns = cell(pipesz, 1);
stepMap = zeros(pipesz, 1);

p = 1; % get the function names of the requested pipe
for i = runSets %over stepSets
    for k = 1:numel(Cfg.pipe.stepSets(i).funH) %over analysis steps
        pipeFuns{p} = func2str(Cfg.pipe.stepSets(i).funH{k});
        stepMap(p) = i;
        p = p + 1;
    end
end
uniqFuns = unique(pipeFuns);
leftout = ones(numel(uniqFuns),1);

defParams = fieldnames(fun_args); % get the configuration parameter names
numdfpm = numel(defParams);
%find where exist multiple entries per function in parameters
manyArg = zeros(numdfpm,1);
for i = 1:numdfpm
    tmp = size(fun_args.(defParams{i}));
    if sum(tmp > 1), manyArg(i) = tmp(tmp > 1); end
end
% copy parameters to the Cfg struct for the pipeline_looper
% if there are multiple calls to function i and only one instance of the
% parameters, turn parameters into a struct array of dimension [1,n] 
% where n = number of calls to function i
for i = 1:numdfpm
    tmp = cellfun(@isempty, strfind(uniqFuns, defParams{i}));
    if sum(~tmp) > 1
        tmpstr = sprintf('''%s''\t', uniqFuns{~tmp});
        error('write_cfg_ctap:param_funcname_mismatch',...
            'parameter ''%s'' matches to %d function names: %s',...
            defParams{i}, sum(~tmp), tmpstr);
    elseif sum(~tmp)
        num_pipe_calls = sum(ismember(pipeFuns, uniqFuns{~tmp}));
        if num_pipe_calls > 1
            Cfg.ctap.(defParams{i})(1:num_pipe_calls) = fun_args.(defParams{i});
        else
            Cfg.ctap.(defParams{i}) = fun_args.(defParams{i});
        end
    end
    leftout = leftout & tmp;
end
% make parameter fields as empty structs where none were specified
uniqFuns = uniqFuns(leftout);
fu_names = strrep(uniqFuns, 'CTAP_', '');
fu_names = strrep(fu_names, 'ctapeeg_', '');
for i = 1:numel(uniqFuns)
    num_fun_occ = sum(ismember(pipeFuns, uniqFuns{i}));
    nopars = struct([fu_names{i} '_params'], 0);
    Cfg.ctap.(fu_names{i}) = repmat(nopars, 1, num_fun_occ);
end


%% Get the complete pipe description

if fixcfg
    % get the size of the whole pipe
    pipesz = numel([Cfg.pipe.stepSets.funH]);
    allPipeFuns = cell(pipesz,1);
    allStepMap = zeros(pipesz,1);

    p = 1; % get the function names of the whole pipe
    for i = allSets %over ALL stepSets
        for k = 1:numel(Cfg.pipe.stepSets(i).funH) %over analysis steps
            allPipeFuns{p} = func2str(Cfg.pipe.stepSets(i).funH{k});
            allStepMap(p) = i;
            p = p + 1;
        end
    end
    exclStp = find(~ismember(allSets, runSets));
    exclIdx = find(ismember(allStepMap, exclStp));
end


%% RUN CHECKS
%for parameters defined with many rows, check assignments will work - i.e.
%the user-defined parameter configuration struct is well-formed
if sum(manyArg)
    % check that the number of parameters equals number of function calls
    for i = find(manyArg)'
        tmp = ~cellfun(@isempty, strfind(pipeFuns, defParams{i}));
        if sum(tmp) && sum(tmp) ~= manyArg(i)
            funStr = pipeFuns{tmp};
            if fixcfg
                % compare the reduced and complete pipes, find where the
                % excluded stepSet lies and remove associated parameter rows
                funcIdx = find(strcmp(allPipeFuns, funStr));
                goneIdx = ismember(funcIdx, exclIdx);
                if numel(Cfg.ctap.(defParams{i})) == numel(goneIdx)
                    Cfg.ctap.(defParams{i})(goneIdx) = [];
                else
                    error('write_cfg_ctap:multi_param_mismatch',...
                        ['''Cfg.ctap.%s'' has %d parameter sets; BUT ''%s'' is'...
                        ' called in complete pipe %d time, in current pipe %d '...
                        'time :: can''t infer parameter assignment! Aborting'],...
                    defParams{i}, manyArg(i), funStr, numel(funcIdx), sum(tmp));
                end
            else
                error('write_cfg_ctap:multi_param_mismatch',...
                '''%s'' has %d parameter rows; BUT pipe calls ''%s'' %d times.'...
                    , defParams{i}, manyArg(i), funStr, sum(tmp));
            end
        end
    end
end

% Check pipe has minimum requirements and suggest mandatory reref.
%   Only if current stepSets is not a subset excluding step 1
%todo: This logic is not clear. Latter boolean was previously longer than
%one. Does not always ask for reref.
if ~fixcfg && ~ismember({Cfg.pipe.stepSets(1).id}, Cfg.pipe.runSets)
    %check for chanlocs
    tmp = cellfun(@isempty, strfind(pipeFuns, 'load_chanlocs'));
    if all(tmp)
        warning('check_cfg_ctap:no_load_chanlocs',...
            '**** MAKE SURE you have chanlocs or pipe may FAIL ****');
        warned = true;
    end
    %check for reref
    tmp = cellfun(@isempty, strfind(pipeFuns, 'reref_data'));
    if all(tmp)
        warning('check_cfg_ctap:no_reref_data',...
         'NO reref! Consider ADDING data re-reference (once chanlocs exist)??');
        warned = true;
    end
end


%% REVIEW WARNINGS
if warned
    testi = dbstack;
    if isempty(strfind([testi.file], 'HYDRAKING.m'))
        %Give a chance to halt pipe
        reply = input(['CTAP is configured with warnings.'...
            'To launch, press Enter. To abort, press any key + Enter'], 's');
        if ~isempty(reply)
            error; %#ok<LTARG>
        end
    end
end

end %ctap_auto_config()
