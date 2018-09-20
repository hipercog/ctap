function CTAP_pipeline_brancher(Cfg, pipeArr, varargin)
%CTAP_pipeline_brancher - Branches the pipes defined in pipeArr
%
% Description:
%   Input structs are documented in Google Docs:
%   https://docs.google.com/document/d/1nexEgDg0JzumWbl3-KJRUnq2_vf6Iiiei_wAd6zM9vo/
%
% Syntax:
%   CTAP_pipeline_brancher(Cfg, Filt, pipeArr, first, last, dbg, ovw);
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%   'pipeArr'   function handle array, specifies the pipe-config funtions
% 
% Varargin:
%   'runPipes'  [1 n] numeric, indices of pipes to process, default = 1:end
%   'dbg'       boolean, see CTAP_pipeline_looper, default = false
%   'ovw'       boolean, see CTAP_pipeline_looper, default = false
%
% Outputs:
%
% See also:
%
% Version History:
% 1.01.2017 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%global looplogFH


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;%unspecified varargin name-value pairs go in p.Unmatched

p.addRequired('Cfg', @isstruct)
p.addRequired('pipeArr', @iscell)

p.addParameter('runPipes', 1:numel(pipeArr), @isnumeric)
p.addParameter('dbg', false, @islogical)
p.addParameter('ovw', false, @islogical)

p.parse(Cfg, pipeArr, varargin{:});
Arg = p.Results;


%% Set up to run pipes
%Ensure runPipes makes sense
tmp = ~ismember(Arg.runPipes, 1:numel(pipeArr));
if any(tmp)
    error('CTAP_pipeline_brancher:bad_param',...
        '''runPipes'' value(s) %d NOT in ''pipeArr''!', Arg.runPipes(tmp))
end
Arg.runPipes = sort(Arg.runPipes);

% Get the number of sets called before the current first one
Cfg.pipe.totalSets = 0;
for i = 1:Arg.runPipes(1) - 1
    [i_Cfg, ~] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
end


%% Run the pipes
for i = Arg.runPipes
    % Set Cfg
    [i_Cfg, i_ctap_args] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
    myReport(sprintf('Begin analysis run at %s with pipe:%s ''%s'''...
        , datestr(now), newline, i_Cfg.id));

    for k = 1:length(i_Cfg.srcid)
        looplogfile = 'looplog.txt';
        looplogFH = fopen(looplogfile, 'a');
        fprintf(looplogFH, 'I: %d, K: %d\n', i, k);
        fclose(looplogFH);
        
        k_Cfg = i_Cfg;
        if isnan(k_Cfg.srcid{k}), continue, end %skip empty sources

        k_Cfg.env.paths = cfg_create_paths(Cfg.env.paths.ctapRoot, k_Cfg.id...
                                                            , k_Cfg.srcid, k);
        % Assign arguments to the selected functions, perform various checks
        k_Cfg = ctap_auto_config(k_Cfg, i_ctap_args);
        k_Cfg.MC = Cfg.MC;

        % Run the pipe
        CTAP_branchedpipe_looper(k_Cfg, 'debug', Arg.dbg, 'overwrite', Arg.ovw)

% TODO: CALL THIS USING CTAP_postproc_brancher() INSTEAD.
        if isfield(Cfg, 'export')
            export_features_CTAP([k_Cfg.id '_db']...
                , {'bandpowers', 'PSDindices'}, Cfg.MC, k_Cfg...
                , 'debug', Arg.dbg, 'overwrite', k_Cfg.export.ovw...
                , 'srcFilt', k_Cfg.export.featureSavePoints);
        end

        clear('k_*');
    end
    % Cleanup
    clear('i_*');
end

    function ts = sbf_get_total_sets(conf)
        if strcmp(conf.pipe.runSets{1}, 'all')
            conf.pipe.runSets = {conf.pipe.stepSets(:).id};
        end
        ts = conf.pipe.totalSets + sum(~cellfun(@isempty, conf.pipe.runSets));
    end

end %CTAP_pipeline_brancher()


function CTAP_branchedpipe_looper(Cfg, varargin)
%CTAP_branchedpipe_looper - Loops over the functions defined in Cfg.pipe.stepSets
%
% Description:
%   Input structs are documented in Google Docs:
%   https://docs.google.com/document/d/1nexEgDg0JzumWbl3-KJRUnq2_vf6Iiiei_wAd6zM9vo/
%
% Syntax:
%   CTAP_pipeline_looper(Cfg, varargin);
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   'debug'     boolean, runs pipe without try-catch wrapper. Errors from
%               core functions will crash the batch.
%               default = false
%   'overwrite' boolean, if false, checks each stepSet for existing .set file -
%               will skip a stepSet instead of overwriting older file.
%               default = false
%   'trackfail' boolean, if true, will save data from a failed stepSet, with
%               file-suffix '_BAD_FILE', for later examination. Such files are
%               deleted on subsequent *successful* passes of this stepSet
%               default = false
%
% Outputs:
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also:
%
% Version History:
% 10.02.2017 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%global looplogFH
looplogfile = 'looplog.txt';
looplogFH = fopen(looplogfile, 'a'); %#ok<NASGU>

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Cfg', @isstruct);
p.addParameter('debug', false, @islogical);
p.addParameter('overwrite', false, @islogical);
p.addParameter('trackfail', false, @islogical);
p.parse(Cfg, varargin{:});
Arg = p.Results;

if ~Arg.debug
    warning('OFF', 'BACKTRACE')
end


%% Create the directories needed
fnames = fieldnames(Cfg.env.paths);
fnames(~cellfun(@ischar, struct2cell(Cfg.env.paths))) = [];
for fn = 1:numel(fnames)
    if ~isdir(Cfg.env.paths.(fnames{fn})) && ...
       ~isempty(Cfg.env.paths.(fnames{fn}))
        mkdir(Cfg.env.paths.(fnames{fn}));
    end
end

myReport(sprintf('Pipe analysis has stepSets:%s %s %s',...
    newline, char(Cfg.pipe.runSets)', newline), Cfg.env.logFile);
EEG = struct;


%% Run step sets
% Find indices of sets to run
if strcmp(Cfg.pipe.runSets{1},'all')
    runSets = 1:numel(Cfg.pipe.stepSets);
else
    runSets = find(ismember({Cfg.pipe.stepSets.id}, Cfg.pipe.runSets));
end


%% Load and subset measurement config data
%Establish where we get our first measurement files
% if ~isempty(Cfg.env.paths.branchSource)
%     pipeSrcDir = Cfg.env.paths.branchSource;
% elseif runSets(1) == 1
%     pipeSrcDir = NaN;
% else
%     pipeSrcDir = sbf_get_src_subdir(Cfg, runSets(1));
% end

badFlag = {'_BAD_FILE'};
% TODO: badFlag approach is not always working. For example
% CTAP_load_data_seamless does not create a file at all if it fails...
if runSets(1) == 1 && isempty(Cfg.env.paths.branchSource)
    %At the start of the pipe, user-defined measurements are all processed
    strucFilt.casename = Cfg.pipe.runMeasurements;
else
    %After 1+ steps, some measurements may have failed.
    %Use source directory to find loadable files
    pipeSrcDir = sbf_get_src_subdir(Cfg, runSets(1));
    Filt = dir(fullfile(pipeSrcDir, '*.set'));
    if numel(Filt) == 0
        error('CTAP_pipeline_looper:inputError',...
        'Source directory ''%s'' is either empty or doesnt exist. Please check.',...
        pipeSrcDir);
    end
    Filt = {Filt(cellfun(@isempty, strfind({Filt.name}, badFlag{1}))).name};
    [~, Filt, ~] = cellfun(@fileparts, Filt, 'UniformOutput', false);
    strucFilt.casename = intersect(Cfg.pipe.runMeasurements, Filt);
    
    % check that a dataset was found
    if numel(strucFilt.casename) == 0
       warning('CTAP_pipeline_looper:inputError',...
        'Source directory ''%s'' does not contain data for casename ''%s''. Please check.',...
        pipeSrcDir, Cfg.pipe.runMeasurements{1});
    end
    
end
%Now initialise stuff for managing measurement indexing
MCSub = Cfg.MC;
MCSub.measurement = struct_filter(Cfg.MC.measurement, strucFilt);
numMC = numel(MCSub.measurement);
MCbad = false(numMC, 1);
if numMC == 0 && ~isempty(strucFilt)
    msg = sprintf('\nNo measurements matching the filter: %s. %s',...
                catcellstr({strucFilt.casename}, 'sep',', '),...
                'WHY DON''T YOU TRY: specifying a different set of measurements.');
    myReport(msg, Cfg.env.logFile);
end


%% Run sets
for n = 1:numMC %over measurements
    myReport(sprintf('\n\n\n================\nProcessing %s ...',...
        MCSub.measurement(n).casename), Cfg.env.logFile);
    Cfg.measurement = MCSub.measurement(n);
    SbjFilt.subject = Cfg.measurement.subject;
    Cfg.subject = struct_filter(Cfg.MC.subject, SbjFilt);
    tmp_Cfg = Cfg; %hold a copy of Cfg as it may be edited during Sets
    clear('SbjFilt');

    for i = runSets %over stepSets
        myReport(sprintf('\n\nSTEP SET %s', Cfg.pipe.stepSets(i).id),...
            Cfg.env.logFile);

        %respect prior run of this stepSet - don't overwrite...
        if ~Arg.overwrite
            %...if save is true...
            if Cfg.pipe.stepSets(i).save
                thisfile = fullfile(Cfg.env.paths.analysisRoot...
                 , Cfg.pipe.stepSets(i).id, [Cfg.measurement.casename, '.set']);
                if exist(thisfile, 'file')
                    myReport(sprintf('Overwrite is OFF and %s exists already.%s',...
                        thisfile, ' Skipping this STEP SET'), Cfg.env.logFile);
                    continue
                end
            %...OR, if stepSet calls peek_data ONLY, and it has been done before
            elseif ismember(cellfun(@func2str...
                   , Cfg.pipe.stepSets(i).funH, 'Un', 0), 'CTAP_peek_data')
               testi = fullfile(Cfg.env.paths.qualityControlRoot...
                   , 'CTAP_peek_data', sprintf('set%d_fun1'...
                   , i + Cfg.pipe.totalSets - numel(runSets))...
                   , Cfg.measurement.casename);
               if isdir(testi) && ~isempty(dirflt(testi))
                   continue
               end
            end
        end
        i_ctap_hist_sz = 0;


        %% Load source data for current step set
        try
            % Load source dataset
            if (i == 1) && isempty(Cfg.env.paths.branchSource)
                % assuming step1,func1 is CTAP_load_data() and
                % loading based on MC.measurement.physiodata
                i_EEG = struct();
            else
                % middle of pipe, load from some previous step set or branch
                i_EEG = pop_loadset(...
                    'filepath', sbf_get_src_subdir(Cfg, i),...
                    'filename', [Cfg.measurement.casename, '.set']);
            end
        catch ME,
            funStr = 'intermediate_data_load';
            sbf_report_error(ME);
            break;
        end

        %% Perform analysis steps in current step set
        for k = 1:numel(Cfg.pipe.stepSets(i).funH) %over analysis steps
            looplogfile = 'looplog.txt';
            looplogFH = fopen(looplogfile, 'a');
            fprintf(looplogFH, '\tn: %d, i2: %d, k2: %d\n', n, i, k);
            fclose(looplogFH);
            
            if (i + k > 2)
                if ~is_valid_CTAPEEG(i_EEG)
                    warning('EEG file was not processed by CTAP pipe');
                    break;
                else
                    i_ctap_hist_sz = numel(i_EEG.CTAP.history);
                end
            end
            % Find the function in the Cfg.ctap struct
            funStr = func2str(Cfg.pipe.stepSets(i).funH{k});
            ctap = fieldnames(Cfg.ctap);
            ctapFun = get_similar_str(ctap, funStr);
            fun_args = Cfg.ctap.(ctapFun);
            % Check the cardinality of the discovered function arg struct
            num_ctapFun = numel(Cfg.ctap.(ctapFun));
            if num_ctapFun > 1
                i_tmp_ctap = Cfg.ctap.(ctapFun)(2:end);
                Cfg.ctap.(ctapFun) = Cfg.ctap.(ctapFun)(1);
            end
            % Call function via handle
            if Arg.debug
                i_Cfg_tmp = sbf_execute_pipefun;
            else
                try
                    i_Cfg_tmp = sbf_execute_pipefun;
                catch ME,
                    sbf_report_error(ME);
                    if isfield(i_EEG, 'CTAP')
                        i_EEG.CTAP.history(end+1) = create_CTAP_history_entry(...
                            ['FAIL_' Cfg.pipe.stepSets(i).id], funStr, fun_args);
                    end
                    MCbad(n) = true;
                    break;
                end
            end
            % Diff the Cfg and i_Cfg_tmp structs to find changes
            %{
            [i_diff, diff_sz] = struct_field_diff(Cfg, i_Cfg_tmp);
            if ~isempty(fieldnames(i_diff)) && diff_sz > 0
                fun_args = i_diff;
            end
            %}
            % Overwrite Cfg with any changes to i_Cfg_tmp
            Cfg = joinstruct(Cfg, i_Cfg_tmp);
            % Create CTAP history entry, if wrapper hasn't already done it
            if numel(i_EEG.CTAP.history) <= i_ctap_hist_sz
                i_EEG.CTAP.history(end+1) = create_CTAP_history_entry(...
                    ['Success--' Cfg.pipe.stepSets(i).id], funStr, fun_args);
            end
            % recover args for later use
            if num_ctapFun > 1
                Cfg.ctap.(ctapFun) = i_tmp_ctap;
            end
        end
        %actions to take whatever happened during ananlysis steps
        i_sv = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.stepSets(i).id);
        if ~isdir(i_sv), mkdir(i_sv); end %make stepSet directory
        EEG = i_EEG; %store EEG state to write out history after loops

        % if stepSet loop didn't complete, measurement is no longer processed.
        if MCbad(n)
            if Arg.trackfail%if requested then save the unfinished EEG file
                pop_saveset(i_EEG, 'filepath', i_sv, 'filename'...
                    , [Cfg.measurement.casename, badFlag{1}, '.set']);
            end
            clear('i_*')%remove temp vars
            break;

        elseif Cfg.pipe.stepSets(i).save%save stepSet result
            i_savefile = fullfile(i_sv, [Cfg.measurement.casename, '.set']);
            i_EEG.CTAP = add_pipe_dataloc(i_EEG.CTAP,...
                                        Cfg.pipe.stepSets(i).id,...
                                        i_savefile);
            i_savefile = [Cfg.measurement.casename...
                , badFlag{MCbad(n) & Arg.trackfail}, '.set'];
            pop_saveset(i_EEG, 'filepath', i_sv, 'filename', i_savefile);

        else
            myReport(sprintf('\nSTEP SET %s SAID: "DON''T SAVE ME!!"\n'...
                , Cfg.pipe.stepSets(i).id), Cfg.env.logFile);

        end
        %cleanup: delete existing _BAD_FILEs, remove temp vars
        warning('OFF', 'MATLAB:DELETE:FileNotFound')
        delete(fullfile(i_sv, [Cfg.measurement.casename, badFlag{1}, '.*']));
        warning('ON', 'MATLAB:DELETE:FileNotFound')
        clear('i_*')

    end %over stepSets
    Cfg = tmp_Cfg; %reassign original ctap

    suxes = {'successfully! :)' 'unsuccessfully :''('};
    suxes = sprintf('\n================\nMeasurement ''%s'' analyzed %s\n',...
        Cfg.measurement.casename, suxes{MCbad(n) + 1});
    histfile = sprintf('%s_history.txt', Cfg.measurement.casename);
    myReport(suxes, Cfg.env.logFile);
    myReport(suxes, fullfile(Cfg.env.paths.logRoot, histfile));
    ctap_check_hist(EEG, fullfile(Cfg.env.paths.logRoot, histfile));

end %over measurements


%% END/REPORT
myReport(sprintf('\nAnalysis run ended at %s.\n', datestr(now, 30)),...
    Cfg.env.logFile);
if any(MCbad)
    myReport({'Analysis failed for: ' MCSub.measurement(MCbad).casename},...
        Cfg.env.logFile, sprintf('\n'));
else
    myReport('All Analysis Successful!', Cfg.env.logFile);
end

% Report the detected badness per file
myReport(sprintf('\n================\nBADNESS SUMMARY:\n'), Cfg.env.logFile);
myReport(scrape_file_for_str(Cfg.env.logFile, 'Bad '), Cfg.env.logFile);
if isfield(Cfg.env, 'userLogFile')
    fid = fopen(Cfg.env.logFile);
    myReport(textscan(fid, '%s'), Cfg.env.userLogFile);
end

% Concatenate all the bad data tables and write as a single text file
if ismember('CTAP_reject_data', cellfun(@func2str...
        , [Cfg.pipe.stepSets(runSets).funH], 'UniformOutput', false))
    rejfiles = dir(fullfile(Cfg.env.paths.qualityControlRoot, '*rejections.mat'));
    if ~isempty(rejfiles)
        tmp = load(fullfile(Cfg.env.paths.qualityControlRoot, rejfiles(1).name));
        rejtab = tmp.rejtab;
        for rt = 2:numel(rejfiles)
            nxt = fullfile(Cfg.env.paths.qualityControlRoot, rejfiles(rt).name);
            tmp = load(nxt);
%TODO(feature-request)(BEN) join tables with non-matching rownames, use missing values
            try
                rejtab = join(rejtab, tmp.rejtab, 'Keys', 'RowNames');
            catch ME,
                fprintf('%s::%s misses rows, can''t join\n', ME.message, nxt)
            end
        end
        writetable(rejtab, fullfile(Cfg.env.paths.logRoot, 'all_rejections.txt')...
            ,  'WriteRowNames', true);
    end
end

fclose('all');
if ~Arg.debug
    warning('ON', 'BACKTRACE')
end


%% EMBEDDED FUNCTIONS

% A function to report errors
% todo: make this function shared between all loopers and save the errors
% also into a table which can be easily analyzed. The current version
% produces a very large number of small text files which is impractical.
function sbf_report_error(ME)
    % Error handling
    logfile = fullfile(Cfg.env.paths.crashLogRoot,...
                sprintf('crashlog_%s.txt', datestr(now(),30)) );

    myReport(sprintf([...
        'WARN\n~~~~/#~~~~/#~~~~/#~~~~/#~~~~/#~~~~'...
        '\nProcessing failed on %s \nbecause: %s \n@ %s : %s'...
        '\n~~~~/#~~~~/#~~~~/#~~~~/#~~~~/#~~~~']...
        , MCSub.measurement(n).casename...
        , ME.message...
        , Cfg.pipe.stepSets(i).id...
        , funStr)...
        , logfile);
end


% embedded function calls the next pipe function
function i_Cfg_tmp = sbf_execute_pipefun
    switch funStr(1:5)
        case 'CTAP_'
            Cfg.pipe.current.set = i + Cfg.pipe.totalSets - numel(runSets);
            Cfg.pipe.current.funAtSet = k;
            [i_EEG, i_Cfg_tmp] = Cfg.pipe.stepSets(i).funH{k}(i_EEG, Cfg);
        otherwise
            % Unpack Cfg to pass parameters to function via
            % varargin, as name, value pairs in cell array
            fun_varargs = [fieldnames(Cfg.ctap.(ctapFun))...
                struct2cell(Cfg.ctap.(ctapFun))]';
            [i_EEG, i_Cfg_tmp] = Cfg.pipe.stepSets(i).funH{k}(i_EEG...
                                                          , fun_varargs{:});
    end
end

% Add a new stepset data location to EEG.CTAP
function CTAP = add_pipe_dataloc(CTAP, stepSetID, file)
    entry = struct('id', stepSetID,...
                   'file', file);
    if ~isfield(CTAP.files, 'stepset')
        CTAP.files.stepset(1) = entry;
    else
        if ~ismember(stepSetID, {CTAP.files.stepset.id})
            CTAP.files.stepset(end+1) = entry;
        end
    end
end

% Get source directory of loadable files
function src_subdir = sbf_get_src_subdir(Cfg, idx)

    if ~isempty(Cfg.pipe.stepSets(idx).srcID)
        parts = strsplit(Cfg.pipe.stepSets(idx).srcID, '#');
        if numel(parts) == 2
            src_subdir = fullfile(Cfg.env.paths.ctapRoot, parts{1}, parts{2});
        else
            src_subdir = fullfile(Cfg.env.paths.analysisRoot, parts{1});
        end
    else
        %get first stepSet index with saved data
        idx = find([Cfg.pipe.stepSets(1:idx - 1).save], 1, 'last' );
        if isempty(idx)
            if ~isempty(Cfg.env.paths.branchSource)
                src_subdir = Cfg.env.paths.branchSource;
            else
                error('CTAP_pipeline_looper:badSaveSpec',...
                'NO SAVE POINT FOUND TO LOAD DATA - check your save specification');
            end
        else
            src_subdir = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.stepSets(idx).id);
        end
    end
end

end% CTAP_pipeline_looper()
